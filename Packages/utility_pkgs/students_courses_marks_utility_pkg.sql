 create or replace package stds_course_marks_utl_pkg
    as
        cursor cur_stds_marks(p_c_batch_id number) is WITH

    students_batches as
    (select s.Id as Student_Id, b.Id as Batch_Id from (select Id,Batch_Id,Graduated,Active from Students where Batch_Id=p_c_batch_id) s
        INNER JOIN (select Id,Active from Batches where Id=p_c_batch_id) b ON b.Id = s.Batch_Id where  s.Graduated=0 and s.ACTIVE=1 and b.ACTIVE=1
) /*+ MATERIALIZE */,


    course_enrollemnts as
        ( select c.Id as Course_Id,c.Credit_Hours,ce.Student_Id,c.Assignment_Weight,c.Attendance_Weight,c.Allowed_Absence_Days,ce.ABSENCE_DAYS from Courses c
        INNER JOIN Courses_Enrollments ce ON c.Id = ce.Course_Id inner join students_batches sb on sb.Student_Id = ce.Student_Id ) /*+ MATERIALIZE */,

    courses_sections as
        (select s.Id as Section_Id, sb.Course_Id,sb.Student_Id,sb.Assignment_Weight,sb.Attendance_Weight,sb.Absence_Days,sb.Allowed_Absence_Days from course_enrollemnts sb inner join SECTION_ENROLLMENTS se on se.Student_Id=sb.Student_Id inner join Sections s on s.Id=se.Section_Id and sb.Course_Id=s.Course_Id),


    exams_mark AS
        (
        SELECT
        ce.Student_Id,
        ce.Course_Id,
        ce.Credit_Hours,
        COALESCE(avg(se.Student_Mark)*c.EXAMS_WEIGHT, 0) AS exam_mark
    FROM
       Courses c
        inner join Exams ex on ex.Course_Id=c.Id
        inner join Exam_Type_Assignments ex_t_ass on c.Id=ex_t_ass.Course_Id and ex.Exam_Type_Id=ex_t_ass.Exam_Type_Id
        inner join Students_Exams se on se.Exam_Id=ex.Id
        inner join course_enrollemnts ce on ce.Student_Id=se.Student_Id
            group by ce.Student_Id,ce.Course_Id,ce.Credit_Hours, c.EXAMS_WEIGHT  ) /*+ MATERIALIZE */

    , assignments_mark as (
    SELECT
                ass_sub_sub.Student_Id,
                cs.Course_Id,
                COALESCE( AVG(ass_sub_sub.MARK) * cs.Assignment_Weight, 0) AS assignment_mark
            FROM
                ASSIGNMENTS ass
                INNER JOIN  ASSIGNMENTS_SUBMISSIONS ass_sub_sub ON ass.Id = ass_sub_sub.Assignment_Id
                INNER JOIN courses_sections cs on ass.Section_Id=cs.Section_Id and ass_sub_sub.Student_Id=cs.Student_Id
            GROUP BY
                ass_sub_sub.Student_Id, cs.Course_Id, cs.Assignment_Weight
        ),
    attendance_mark as (SELECT

                att_rec.Student_Id,
                cs.Course_Id,
                (CASE WHEN COUNT(*) > 0
                    THEN (1 - COALESCE(cs.Absence_Days / NULLIF(cs.Allowed_Absence_Days, 0), 0))
                    ELSE 1
                END) * cs.Attendance_Weight AS attend_mark
            FROM
                Attendance_Records att_rec
                INNER JOIN Attendance_Lists Att_L ON att_rec.Attendance_List_Id = Att_L.Id
                inner join courses_sections cs on cs.Section_Id=Att_L.Section_Id and cs.Student_Id=att_rec.Student_Id
            GROUP BY
                att_rec.Student_Id, cs.Course_Id, cs.Attendance_Weight, cs.Allowed_Absence_Days, cs.Absence_Days),
final_marks AS (
    SELECT
        cce.Student_Id,
        cce.Course_Id,
        cce.Credit_Hours,
       (Coalesce(ex_mark.exam_mark, 0) +
             Coalesce(ass_mark.assignment_mark, 0) +
             Coalesce(att_mark.attend_mark, 0)) * 100 AS final_mark
    FROM
        course_enrollemnts cce left join
        exams_mark ex_mark on ex_mark.Student_Id =cce.Student_Id and cce.Course_Id=ex_mark.Course_Id
            left join assignments_mark ass_mark on ass_mark.Student_Id=cce.Student_Id and ex_mark.Course_Id=ass_mark.Course_Id
    left join attendance_mark att_mark on att_mark.Student_Id=cce.Student_Id and ass_mark.Course_Id = att_mark.Course_Id

)
SELECT
    fm.Student_Id,
    fm.Course_Id,
    fm.Credit_Hours,
    fm.final_mark,
    gs.Id AS GradeScaleId,
    gs.Letter_Grade,
    gs.GPA_Points
FROM
    final_marks fm
    LEFT JOIN Grade_Scale gs ON fm.final_mark BETWEEN gs.Percentage_Min AND gs.Percentage_Max order by fm.Student_Id;

    end stds_course_marks_utl_pkg;

