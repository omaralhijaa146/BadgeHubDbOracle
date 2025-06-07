create or replace type obj_stds_course_marks as object(
        Student_Id number,
        Course_Id number,
        Credit_Hours number,
        final_mark number,
        GradeScaleId number,
        Letter_Grade varchar2(2),
        GPA_Points number(3,1)
        );

create or replace type t_stds_course_marks is table of obj_stds_course_marks;

