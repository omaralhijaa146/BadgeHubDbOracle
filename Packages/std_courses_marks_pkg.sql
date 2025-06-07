create or replace package stds_marks_pkg
    as
    procedure calc_stds_gpa_by_batch(p_batch_id in number);
    procedure calc_stds_course_marks_by_batch(p_batch_id in number);
    function get_stds_course_marks_by_batch(p_batch_id in number) return t_stds_course_marks pipelined;
    end stds_marks_pkg;

create or replace package body stds_marks_pkg
as
     procedure lock_rows(p_batch_id number);


     function batch_finished_exams(p_batch_id batches.id%type) return boolean
     as
         v_completed_exams_count number;
         v_total_exams_count number;
     begin
         select count(ex_t_ass.exam_type_id) as exam_types_course, count(ex.id) as exam_completed into v_total_exams_count,v_completed_exams_count from
             batches b inner join plans p on b.plan_id = p.id and (b.active=1 and p.active=1)
                       inner join learning_periods lp on b.period_id=lp.id
                       inner join course_plan cp on cp.plan_id =p.id
                       inner join courses c on c.id=cp.course_id
                       inner join exam_type_assignments ex_t_ass on ex_t_ass.course_id=c.id
                       left join exams ex on ex.course_id = ex_t_ass.course_id
                 and ex_t_ass.EXAM_TYPE_ID=ex.exam_type_id
                 and ex.expired=1 and lp.id= ex.learning_period_id where b.id=p_batch_id;
         return v_completed_exams_count=v_total_exams_count;
     end batch_finished_exams;

    function check_calc_marks_requirements(p_batch_id number) return boolean
         as
        v_batch_exists number;
        v_batch_has_stds number;
        v_batch_has_current_period number;
        e_invalid_batch_id exception;
        e_batch_has_no_stds exception;
        e_batch_has_no_current_period exception;
        e_batch_has_remaining_exams exception;
        e_locked_rows exception;
        pragma exception_init(e_locked_rows,-54);
        begin
            if p_batch_id is null then
                raise e_invalid_batch_id;
            end if;

            select count(*) into v_batch_exists from BATCHES where id = p_batch_id and ACTIVE=1;

            if v_batch_exists=0 then
                raise e_invalid_batch_id;
            end if;

            select count(*) into v_batch_has_stds from STUDENTS where BATCH_ID=p_batch_id and ACTIVE=1;
            if v_batch_has_stds=0 then
                raise e_batch_has_no_stds;
            end if;

            select nvl(lp.CURRENT_PERIOD,0) into v_batch_has_current_period from batches b inner join learning_periods lp on b.period_id= lp.id where b.id=p_batch_id and lp.current_period=1;

            if v_batch_has_current_period=0 then
                raise e_batch_has_no_current_period;
            end if;

            if not batch_finished_exams(p_batch_id) then
                raise e_batch_has_remaining_exams;
            end if;

            return true;

        exception
            when e_invalid_batch_id then
                raise_application_error(error_codes_pkg.gc_invalid_batch_id,error_codes_pkg.gc_msg_invalid_batch_id);
            when too_many_rows then
                raise_application_error(error_codes_pkg.gc_too_many_rows, error_codes_pkg.gc_msg_too_many_rows);
            when e_batch_has_no_stds then
                raise_application_error(error_codes_pkg.gc_batch_has_no_stds,error_codes_pkg.gc_msg_batch_has_no_stds);
            when e_locked_rows then
                rollback;
                raise_application_error(error_codes_pkg.gc_locked_rows,error_codes_pkg.gc_msg_locked_rows);
            when e_batch_has_no_current_period then
                raise_application_error(error_codes_pkg.gc_batch_has_no_current_period,error_codes_pkg.gc_msg_batch_has_no_current_period);

            when e_batch_has_remaining_exams then
                raise_application_error(error_codes_pkg.gc_batch_has_remaining_exams,error_codes_pkg.gc_msg_batch_has_remaining_exams);
            when others then
                if sqlcode between -1000 and -1 then
                    -- Known Oracle error, map it
                    raise_application_error(error_codes_pkg.gc_ora_to_app_base + abs(sqlcode),
                                            'Oracle error ' || sqlcode || ': ' || sqlerrm);
                else
                    -- Truly unknown error
                    raise_application_error(error_codes_pkg.gc_unknown_error,
                                            'Unknown error ' || sqlcode || ': ' || sqlerrm);
                end if;

        end;

     function get_stds_course_marks_by_batch(p_batch_id in number) return t_stds_course_marks pipelined
    as
        begin
            -- noinspection SqlResolve
            for rec in STDS_COURSE_MARKS_UTL_PKG.CUR_STDS_MARKS(p_batch_id) loop
                pipe row ( OBJ_STDS_COURSE_MARKS(STUDENT_ID => rec.Student_Id, COURSE_ID => rec.Course_Id, CREDIT_HOURS => rec.Credit_Hours, FINAL_MARK => rec.Final_Mark, GRADESCALEID => rec.GradeScaleId, LETTER_GRADE => rec.Letter_Grade, GPA_POINTS => rec.Gpa_points) );
            end loop;
            return ;
        end get_stds_course_marks_by_batch;

     procedure calc_stds_gpa_by_batch(p_batch_id in number)
     as

         cursor cur_stds_gpas is select student_id,final_mark, gradeScaleId,(sum(GPA_Points*Credit_Hours)/sum(Credit_Hours)) as gpa from table(stds_marks_pkg.get_stds_course_marks_by_batch(p_batch_id)) group by student_id,final_mark,gradeScaleId;
        type t_stds_gpas is table of cur_stds_gpas%rowtype;
        v_stds_gpas t_stds_gpas;
         v_rows_limit number:=100;
         v_min_grad_gpa number;
        e_invalid_batch_requirements exception;
     begin

         if check_calc_marks_requirements(p_batch_id) then
            lock_rows(p_batch_id);
        else
            raise e_invalid_batch_requirements;
        end if;

        select GPA_POINTS into v_min_grad_gpa from grade_scale where LETTER_GRADE='F';


         open cur_stds_gpas;

         loop
             fetch cur_stds_gpas bulk collect into v_stds_gpas limit v_rows_limit;

             exit when v_stds_gpas.count=0;

             forall i in 1..v_stds_gpas.count
                update students set gpa = v_stds_gpas(i).GradeScaleId, GRADUATED= (
                    case
                        when v_stds_gpas(i).gpa>v_min_grad_gpa then 1
                        when v_stds_gpas(i).gpa=v_min_grad_gpa then 0
                        end) where id = v_stds_gpas(i).student_id ;
             commit;
         end loop;

         close cur_stds_gpas;

         exception
                when e_invalid_batch_requirements then
                        raise_application_error(error_codes_pkg.gc_invalid_batch_requirements,error_codes_pkg.gc_msg_invalid_batch_requirements);
                        close cur_stds_gpas;
                when others then
                    if sqlcode between -1000 and -1 then

                        raise_application_error(error_codes_pkg.gc_ora_to_app_base + abs(sqlcode),
                                                'Oracle error ' || sqlcode || ': ' || sqlerrm);
                    else

                        raise_application_error(error_codes_pkg.gc_unknown_error,
                                                'Unknown error ' || sqlcode || ': ' || sqlerrm);
                    end if;

     end calc_stds_gpa_by_batch;

    procedure calc_stds_course_marks_by_batch(p_batch_id in number)
    as
        cursor cur_stds_course_marks is select * from table(get_stds_course_marks_by_batch(p_batch_id));
        type t_stds_marks is table of cur_stds_course_marks%rowtype;
        v_stds_marks t_stds_marks;
        v_rows_limit number:=100;
        e_invalid_batch_requirements exception;
        begin

            if check_calc_marks_requirements(p_batch_id) then
                lock_rows(p_batch_id);
            else
                raise e_invalid_batch_requirements;
            end if;

            open cur_stds_course_marks;
            loop

                fetch  cur_stds_course_marks bulk collect into v_stds_marks limit v_rows_limit;

                exit when v_stds_marks.count = 0;

                forall i in 1.. v_stds_marks.count
                    update courses_enrollments set student_mark=v_stds_marks(i).FINAL_MARK, LETTER_GRADE = v_stds_marks(i).GradeScaleId where Student_Id= v_stds_marks(i).STUDENT_ID and Course_Id=v_stds_marks(i).Course_Id ;

                commit;
            end loop;
            close cur_stds_course_marks;

        exception
            when e_invalid_batch_requirements then
                raise_application_error(error_codes_pkg.gc_invalid_batch_requirements,error_codes_pkg.gc_msg_invalid_batch_requirements);
                close cur_stds_course_marks;

            when others then
                if sqlcode between -1000 and -1 then

                    raise_application_error(error_codes_pkg.gc_ora_to_app_base + abs(sqlcode),
                                            'Oracle error ' || sqlcode || ': ' || sqlerrm);
                else

                    raise_application_error(error_codes_pkg.gc_unknown_error,
                                            'Unknown error ' || sqlcode || ': ' || sqlerrm);
                end if;

        end calc_stds_course_marks_by_batch;

        procedure lock_rows(p_batch_id number)
            as
            begin

            --students-batches
            execute immediate 'select s.Id as Student_Id, b.Id as Batch_Id from (select Id,Batch_Id,Graduated,Active from Students where Batch_Id=:batchId) s
        INNER JOIN (select Id,Active from Batches where Id=:batchId) b ON b.Id = s.Batch_Id where  s.Graduated=0 and s.ACTIVE=1 and b.ACTIVE=1 for update nowait' using p_batch_id,p_batch_id;

            -- course-enrollments
            execute immediate 'select c.Id as Course_Id,c.Credit_Hours,ce.Student_Id,c.Assignment_Weight,c.Attendance_Weight,c.Allowed_Absence_Days,ce.ABSENCE_DAYS from Courses c
        INNER JOIN Courses_Enrollments ce ON c.Id = ce.Course_Id
                inner join (select s.Id as Student_Id, b.Id as Batch_Id from (select Id,Batch_Id,Graduated,Active from Students where Batch_Id=:batchId) s
        INNER JOIN (select Id,Active from Batches where Id=:batchId) b ON b.Id = s.Batch_Id where  s.Graduated=0 and s.ACTIVE=1 and b.ACTIVE=1) sb on sb.Student_Id = ce.Student_Id for update nowait' using p_batch_id,p_batch_id;

            --courses_sections
            execute immediate 'select s.Id as Section_Id, sb.Course_Id,sb.Student_Id,sb.Assignment_Weight,sb.Attendance_Weight,sb.Absence_Days,sb.Allowed_Absence_Days from (
select c.Id as Course_Id,c.Credit_Hours,ce.Student_Id,c.Assignment_Weight,c.Attendance_Weight,c.Allowed_Absence_Days,ce.ABSENCE_DAYS from Courses c
        INNER JOIN Courses_Enrollments ce ON c.Id = ce.Course_Id
                inner join (select s.Id as Student_Id, b.Id as Batch_Id from (select Id,Batch_Id,Graduated,Active from Students where Batch_Id=:batchId) s
        INNER JOIN (select Id,Active from Batches where Id=:batchId) b ON b.Id = s.Batch_Id where  s.Graduated=0 and s.ACTIVE=1 and b.ACTIVE=1) sb on sb.Student_Id = ce.Student_Id
                                                                                                                                                                            ) sb inner join SECTION_ENROLLMENTS se on se.Student_Id=sb.Student_Id inner join Sections s on s.Id=se.Section_Id and sb.Course_Id=s.Course_Id for update nowait' using p_batch_id,p_batch_id;


        --exams_mark
           execute immediate 'select 1 FROM
       Courses c
        inner join Exams ex on ex.Course_Id=c.Id
        inner join Exam_Type_Assignments ex_t_ass on c.Id=ex_t_ass.Course_Id and ex.Exam_Type_Id=ex_t_ass.Exam_Type_Id
        inner join Students_Exams se on se.Exam_Id=ex.Id
        inner join (
select s.Id as Section_Id, sb.Course_Id,sb.Student_Id,sb.Assignment_Weight,sb.Attendance_Weight,sb.Absence_Days,sb.Allowed_Absence_Days from (
select c.Id as Course_Id,c.Credit_Hours,ce.Student_Id,c.Assignment_Weight,c.Attendance_Weight,c.Allowed_Absence_Days,ce.ABSENCE_DAYS from Courses c
        INNER JOIN Courses_Enrollments ce ON c.Id = ce.Course_Id
                inner join (select s.Id as Student_Id, b.Id as Batch_Id from (select Id,Batch_Id,Graduated,Active from Students where Batch_Id=:batchId) s
        INNER JOIN (select Id,Active from Batches where Id=:batchId) b ON b.Id = s.Batch_Id where  s.Graduated=0 and s.ACTIVE=1 and b.ACTIVE=1) sb on sb.Student_Id = ce.Student_Id
                                                                                                                                                                            ) sb inner join SECTION_ENROLLMENTS se on se.Student_Id=sb.Student_Id inner join Sections s on s.Id=se.Section_Id and sb.Course_Id=s.Course_Id
       ) ce on ce.Student_Id=se.Student_Id for update nowait' using p_batch_id,p_batch_id;

            --assignments_mark
                execute immediate '                select 1
                FROM
                ASSIGNMENTS ass
                INNER JOIN  ASSIGNMENTS_SUBMISSIONS ass_sub_sub ON ass.Id = ass_sub_sub.Assignment_Id
                INNER JOIN (select s.Id as Section_Id, sb.Course_Id,sb.Student_Id,sb.Assignment_Weight,sb.Attendance_Weight,sb.Absence_Days,sb.Allowed_Absence_Days from (
select c.Id as Course_Id,c.Credit_Hours,ce.Student_Id,c.Assignment_Weight,c.Attendance_Weight,c.Allowed_Absence_Days,ce.ABSENCE_DAYS from Courses c
        INNER JOIN Courses_Enrollments ce ON c.Id = ce.Course_Id
                inner join (select s.Id as Student_Id, b.Id as Batch_Id from (select Id,Batch_Id,Graduated,Active from Students where Batch_Id=:batchId) s
        INNER JOIN (select Id,Active from Batches where Id=:batchId) b ON b.Id = s.Batch_Id where  s.Graduated=0 and s.ACTIVE=1 and b.ACTIVE=1) sb on sb.Student_Id = ce.Student_Id
                                                                                                                                                                            ) sb inner join SECTION_ENROLLMENTS se on se.Student_Id=sb.Student_Id inner join Sections s on s.Id=se.Section_Id and sb.Course_Id=s.Course_Id) cs on ass.Section_Id=cs.Section_Id and ass_sub_sub.Student_Id=cs.Student_Id for update nowait
' using p_batch_id,p_batch_id;
        --attendance_mark
                execute immediate 'select 1 FROM Attendance_Records att_rec
                INNER JOIN Attendance_Lists Att_L ON att_rec.Attendance_List_Id = Att_L.Id
                inner join (select s.Id as Section_Id, sb.Course_Id,sb.Student_Id,sb.Assignment_Weight,sb.Attendance_Weight,sb.Absence_Days,sb.Allowed_Absence_Days from (
select c.Id as Course_Id,c.Credit_Hours,ce.Student_Id,c.Assignment_Weight,c.Attendance_Weight,c.Allowed_Absence_Days,ce.ABSENCE_DAYS from Courses c
        INNER JOIN Courses_Enrollments ce ON c.Id = ce.Course_Id
                inner join (select s.Id as Student_Id, b.Id as Batch_Id from (select Id,Batch_Id,Graduated,Active from Students where Batch_Id=:batchId) s
        INNER JOIN (select Id,Active from Batches where Id=:batchId) b ON b.Id = s.Batch_Id where  s.Graduated=0 and s.ACTIVE=1 and b.ACTIVE=1) sb on sb.Student_Id = ce.Student_Id
                                                                                                                                                                            ) sb inner join SECTION_ENROLLMENTS se on se.Student_Id=sb.Student_Id inner join Sections s on s.Id=se.Section_Id and sb.Course_Id=s.Course_Id) cs on cs.Section_Id=Att_L.Section_Id and cs.Student_Id=att_rec.Student_Id for update nowait' using p_batch_id,p_batch_id;


            execute immediate 'select 1 from GRADE_SCALE for update nowait';
            end lock_rows;
end stds_marks_pkg;