create table Badges(
                       Id number(10) generated always as identity,
                       Image blob not null,
                       Name varchar2(30) not null,
                       constraint pk_badges primary key(Id) using index (create unique index idx_badges_id on Badges(Id)),
                       constraint uk_badges_name unique (Name) using index (create unique index idx_badges_name_uk on Badges(Name))
);



create table Roles(
                      Id number(10) generated always as identity(start with 100 increment by 10 order nomaxvalue minvalue 100),
                      Name varchar2(50) not null,
                      constraint pk_roles primary key (Id)  using index (create unique index idx_roles_id on Roles(Id)),
                      constraint uk_roles_name unique(Name) using index (create unique index idx_roles_name_uk on Roles(Name))
);

create table Users(
                      Id number(10) generated always as identity(start with 100  order nomaxvalue minvalue 100),
                      First_Name varchar2(50) not null,
                      Last_Name varchar2(50) not null,
                      Email varchar2(150) not null,
                      Password varchar2(500) not null ,
                      Image blob,
                      Role_Id number(10) not null,
                      Email_Confirmed number(1,0) default 0 not null,
                      User_Timezone varchar2(100) not null,
                      constraint pk_users primary key (Id) using index (create unique index idx_users_id on Users(Id)),
                      constraint fk_users_roles foreign key (Role_Id) references Roles(Id),
                      constraint uk_users_email unique(Email) using index(create unique index idx_users_email_uk on Users(Email))
);

create table user_tokens(
                            User_Id number(10),
                            Token_Type varchar2(50),
                            Value varchar2(500) not null,
                            constraint user_tokens_users_fk foreign key (User_Id) references users(Id) on delete cascade,
                            constraint pk_users_tokens primary key (User_Id,token_type) using index (create unique index idx_users_tokens_id ON user_tokens(User_Id,Token_Type))
);


create table Programs(
                         Id number(10) generated always as identity (start with 100  order nomaxvalue minvalue 100),
                         Name varchar2(100) not null,
                         Description varchar2(500) not null,
                         Active number(1,0) default 1 not null,
                         constraint pk_programs primary key (Id) using index (create unique index idx_programs_id on Programs(Id)),
                         constraint uk_program_name unique(Name) using index(create unique index idx_programs_name_uk on Programs(Name))
);


create table Plans(
                      Id number(10) generated always as identity (start with 100 increment by 10 order nomaxvalue minvalue 100),
                      Name varchar2(50) not null,
                      Plan_Date date not null,
                      Program_Id number(10) not null,
                      Active number(1,0) default 1 not null,
                      constraint pk_plans primary key (Id) using index (create unique index idx_plans_id on Plans(Id)),
                      constraint fk_plans_programs foreign key (Program_Id) references Programs(Id),
                      constraint uk_plans_name unique(Name) using index (create unique index idx_plans_name_uk on Plans(Name))
);


create table Learning_Periods(
                                 Id number(10) generated always as identity(start with 100 increment by 10 order nomaxvalue minvalue 100),
                                 Name varchar2(60) not null,
                                 Start_Date date not null ,
                                 End_Date date not null,
                                 Current_Period number(1,0) not null,
                                 constraint pk_learning_periods primary key ( Id ) using index (create unique index idx_period_id on Learning_Periods(Id)),
                                 constraint uk_periods_name_date unique(Name,Start_Date,End_Date) using index (create unique index idx_periods_name_date_uk on Learning_Periods(Name, Start_Date, End_Date))
);


create table Batches(
                        Id number(10) generated always as identity (start with 100 increment by 5 order nomaxvalue minvalue 100),
                        Name varchar2(50) not null,
                        Plan_Id number(10) not null,
                        Active number(1,0) default 1 not null,
                        Period_Id number(10) not null,
                        constraint pk_batches primary key(Id) using index(create unique index idx_batch_id on Batches(Id)),
                        constraint fk_batches_plans foreign key (Plan_Id) references Plans(Id),
                        constraint fk_batches_learnign_period foreign key (Period_Id) references Learning_Periods(Id),
                        constraint uk_batches_name_pl_lp unique(Name,Plan_Id,Period_Id) using index (create unique index idx_batches_name_date_uk on Batches(Name,Plan_Id,Period_Id))
);

create table Students(
                         Id number(10),
                         Graduated number(1,0) not null,
                         Gpa number(3,2) default 0 not null,
                         Program_Id number(10) not null,
                         Batch_Id number(10),
                         Active number(1,0) default 1 not null,
                         constraint fk_students_users foreign  key (Id) references Users(Id),
                         constraint fk_students_programs foreign key (Program_Id) references Programs(Id),
                         constraint FK_STUDENTS_GRADE_SCALE foreign key (Gpa) references Grade_Scale(Id),
                         constraint pk_students primary key (Id) using index (create unique index idx_student_id on Students(Id))
);

create table Teachers(
                         Id number(10),
                         Salary number(6,2),
                         Working number(1,0) default 1 not null,
                         constraint fk_teacher_users foreign key (Id) references Users(Id),
                         constraint pk_teachers primary key (Id) using index (create unique index idx_Teacher_id on Teachers(Id))
);

create table Courses(
                        Id number(10) generated always as identity(start with 100 order nomaxvalue minvalue 100),
                        Name varchar2(100) not null,
                        Course_Code number(10) not null,
                        Max_Grade number(5,2) not null,
                        Pass_Grade number(5,2) not null,
                        Exam_Weight NUMBER(3,2) DEFAULT 0.6 not null,
                        Assignment_Weight NUMBER(3,2) DEFAULT 0.3 not null,
                        Attendance_Weight NUMBER(3,2) DEFAULT 0.1,
                        Allowed_Absence_Days number(10) not null,
                        Credit_Hours number(10) not null,
                        constraint pk_courses primary key (Id) using index (create unique index idx_course_id on Courses(Id)),
                        constraint fk_courses_pass_grade_scale foreign key (Pass_Grade) refereneces Grade_Scale(Id),
                        constraint fk_courses_max_grade_scale foreign key (Max_Grade) references Grade_Scale(Id),
                        constraint uk_course_name_code unique (Name,Course_Code) using index (create unique index idx_course_name_code_uk on Courses(Name,Course_Code))
                    ,constraint check_courses_pass_max_grade check (Pass_Grade!=Max_Grade)
);

create table Sections(
                         Id number(10) generated always as identity(start with 100  order nomaxvalue minvalue 100),
                         Section_Number number(10) not null,
                         Start_Time timestamp(6) with time zone not null,
                         Duration number(2,1) not null,
                         Lecture_Link varchar2(500),
                         Image blob,
                         Teacher_Id number(10) not null,
                         Course_Id number(10) not null,
                         constraint pk_sections primary key (Id) using index (create unique index idx_section_id on Sections(Id)),
                         constraint fk_sections_teachers foreign key (Teacher_Id) references Teachers(Id),
                         constraint fk_section_course_id foreign key(Course_Id) references Courses(Id)
);


create table Materials(
                          Id number(10) generated always as identity (start with 100  order nomaxvalue minvalue 100),
                          Material_File blob not null,
                          Course_Id number(10) not null,
                          Teacher_Id number(10) not null,
                          constraint pk_materials primary key (Id) using index (create unique index idx_material_id on Materials(Id)),
                          constraint fk_materials_courses foreign key (Course_Id) references Courses(Id),
                          constraint fk_materials_teachers foreign key (Teacher_Id) references Teachers(Id)
);

create table Assignments(
                            Id number(10) generated always as identity (start with 100  order nomaxvalue minvalue 100),
                            Assignment_File blob not null,
                            Section_Id number(10) not null,
                            Teacher_Id number(10) not null,
                            Learning_Period_Id number(10) not null,
                            Upload_Date date not null,
                            Dead_Line timestamp with time zone not null,
                            constraint pk_assignments primary key (Id) using index (create unique index idx_assignment_id on Assignments(Id)),
                            constraint fk_assignments_sections foreign key (Section_Id) references Sections(Id),
                            constraint fk_assignments_teachers foreign key (Teacher_Id) references Teachers(Id),
                            constraint fk_assignments_lperiods foreign key (Learning_Period_Id) references Learning_Periods(Id)
);

create table Attendance_Lists(
                                 Id number(10) generated always as identity(start with 100  order nomaxvalue minvalue 100),
                                 List_Date timestamp with time zone not null,
                                 Section_Id number(10) not null,
                                 Teacher_Id number(10) not null,
                                 constraint pk_attendance_lists primary key (Id) using index (create unique index idx_attendance_list_id on Attendance_Lists(Id)),
                                 constraint fk_att_lists_sections foreign key (Section_Id) references Sections(Id),
                                 constraint fk_att_lists_teachers foreign key (Teacher_Id) references Teachers(Id)
);


create table Exam_Types(
                           Id number(10) generated always as identity (start with 100 increment by 10 order nomaxvalue minvalue 100),
                           Name varchar2(100) not null,
                           constraint pk_exam_types primary key (Id) using index (create unique index idx_exam_type_id on Exam_Types(Id)),
                           constraint uk_exam_types unique (Name) using index (create unique index idx_exam_types_uk on Exam_Types(Name))
);


create table Exams(
                      Id number(10) generated always as identity (start with 100 order nomaxvalue minvalue 100),
                      Start_Time timestamp with time zone not null,
                      End_Time timestamp with time zone not null,
                      Mark number(5,2) not null,
                      Expired number(1,0) default 0 not null,
                      Course_Id number(10) not null,
                      Exam_Type_Id number(10) not null,
                      Learning_Period_Id number(10) not null,
                      Teacher_Id number(10) not null,
                      constraint pk_exams primary key (Id) using index (create unique index idx_exam_id on Exams(Id)),
                      constraint fk_exams_courses foreign key (Course_Id) references Courses(Id),
                      constraint fk_exams_exam_types foreign key (Exam_Type_Id) references Exam_Types(Id),
                      constraint fk_exams_teachers foreign key (Teacher_Id) references Teachers(Id),
                      constraint fk_exams_lperiods foreign key (Learning_Period_Id) references Learning_Periods(Id),
                      constraint uk_exams_exam_type_lperiod unique (Course_Id,Exam_Type_Id,Learning_Period_Id) using index (create unique index idx_exams_exam_type_lperiod_uk on Exams(Course_Id,Exam_Type_Id,Learning_Period_Id))
);


create table Questions(
                          Id number(10) generated always as identity (start with 100 order nomaxvalue minvalue 100),
                          Question varchar2(500) not null,
                          mark number(5,2) not null,
                          Exam_Id number(10) not null,
                          constraint pk_questions primary key (Id) using index (create unique index idx_question_id on Questions(Id)),
                          constraint fk_questions_exams foreign key (Exam_Id) references Exams(Id),
                          constraint uk_question unique (Question) using index (create unique index idx_question_uk on Questions(Question))
);


create table Answers(
                        Id number(10) generated always as identity (start with 100 order nomaxvalue minvalue 100),
                        Answer varchar2(500) not null,
                        Correct_Answer number(1,0) not null,
                        Question_Id number(10) not null,
                        constraint pk_answers primary key (Id) using index (create unique index idx_answer_id on Answers(Id)),
                        constraint fk_answers_questions foreign key (Question_Id) references Questions(Id),
                        constraint uk_answer unique (Answer) using index (create unique index idx_answer_uk on Answers(Answer))
);

create table Work_days(
                          Id number(10) generated always as identity (start with 100 increment by 10 order nomaxvalue minvalue 100),
                          Day varchar2(20),
                          constraint pk_work_days primary key (Id) using index (create unique index idx_workday_id on Work_days(Id))
);


create table Teachers_Schedules(
                                   Day_Id number(10),
                                   Teacher_Id number(10),
                                   constraint fk_teachers_schedule_work_days foreign key (Day_Id) references Work_Days(Id),
                                   constraint fk_teachers_schedule_teachers foreign key (Teacher_Id) references Teachers(Id),
                                   constraint pk_teachers_schedule primary key (Day_Id,Teacher_Id) using index (create unique index idx_teachers_schedule_id on Teachers_Schedules(Day_Id,Teacher_Id) )
);


create table Sections_Schedules(
                                   Day_Id number(10),
                                   Section_Id number(10),
                                   constraint fk_sections_Schedule_work_days foreign key (Day_Id) references Work_Days(Id),
                                   constraint fk_sections_schedule_section foreign key (Section_Id) references Sections(Id),
                                   constraint pk_sections_schedule primary key (Day_Id,Section_Id) using index (create unique index idx_sections_schedule_id on Sections_Schedules(Day_Id,Section_Id))
);


create table Teaching_Assignments(
                                     Course_Id number(10),
                                     Teacher_Id number(10),
                                     constraint fk_teaching_assignment_courses foreign key (Course_Id) references Courses(Id),
                                     constraint fk_teaching_assignment_teachers foreign key (Teacher_Id) references Teachers(Id),
                                     constraint pk_teaching_assignment primary key (Course_Id,Teacher_Id) using index (create unique index idx_teaching_assignments_id on Teaching_Assignments(Course_Id,Teacher_Id))
);


create table Exam_Type_Assignments(
                                      Course_Id number(10),
                                      Exam_Type_Id number(10),
                                      constraint fk_exam_types_assignments_courses foreign key (Course_Id) references Courses(Id),
                                      constraint fk_exam_types_assignments_exam_types foreign key (Exam_Type_Id) references Exam_Types(Id),
                                      constraint pk_exam_type_assignments primary key (Course_Id,Exam_Type_Id) using index (create unique index idx_exam_type_assignments_id on Exam_Type_Assignments(Course_Id,Exam_Type_Id))
);

create table Assignments_Submissions(
                                        Assignment_Id number(10),
                                        Student_Id number(10),
                                        Submission_Date timestamp with time zone not null,
                                        Mark number(5,2),
                                        constraint fk_assignments_submissions_assignments foreign key (Assignment_Id) references Assignments(Id),
                                        constraint fk_assignments_submissions_students foreign key (Student_Id) references Students(Id),
                                        constraint pk_assignments_submissions primary key (Assignment_Id,Student_Id) using index (create unique index idx_assignments_submissions on Assignments_Submissions(Assignment_Id,Student_Id))
);

create table Attendance_Records(
                                   Attendance_List_Id number(10),
                                   Student_Id number(10),
                                   Absence number(1,0) not null,
                                   Record_Date timestamp with time zone not null,
                                   constraint fk_attendance_rec_attendance_lists foreign key (Attendance_List_Id) references Attendance_Lists(Id),
                                   constraint fk_attendance_rec_students foreign key (Student_Id) references Students(Id),
                                   constraint pk_attendance_records primary key (Attendance_List_Id,Student_Id) using index(create unique index idx_attendance_records_id on Attendance_Records(Attendance_List_Id,Student_Id))
);

create table Section_Enrollments(
                                    Section_Id number(10),
                                    Student_Id number(10),
                                    constraint fk_section_enrollments_sections foreign key (Section_Id) references Sections(Id),
                                    constraint fk_section_enrollments_students foreign key (Student_Id) references Students(Id),
                                    constraint pk_section_enrollments primary key(Section_Id,Student_Id) using index (create unique index idx_section_enrollments_id on Section_Enrollments(Section_Id,Student_Id))
);

create table Courses_Enrollments(
                                    Course_Id number(10),
                                    Student_Id number(10),
                                    Student_Mark number(5,2),
                                    Absence_Days number(10) default 0 not null,
                                    Letter_Grade number(10),
                                    constraint fk_courses_enrollments_grade_scale foreign key (Letter_Grade) references Grade_Scale(Id),
                                    constraint fk_course_enrollments_courses foreign key (Course_Id) references Courses(Id),
                                    constraint fk_course_enrollments_students foreign key (Student_Id) references Students(Id),
                                    constraint pk_course_enrollments primary key (Course_Id,Student_Id) using index(create unique index idx_course_enrollments_id on Courses_Enrollments(Course_Id,Student_Id))
);

create table Course_Plan(
                            Plan_Id number(10),
                            Course_Id number(10),
                            Prerequisite number(10),
                            constraint fk_course_plan_plans foreign key (Plan_Id) references Plans(Id),
                            constraint fk_course_plan_courses foreign key (Course_Id) references Courses(Id),
                            constraint fk_course_plan_prereq_courses foreign key (Prerequisite) references Courses(Id),
                            constraint pk_course_plan primary key (Plan_Id,Course_Id) using index (create unique index idx_course_plan_id on Course_Plan(Plan_Id,Course_Id)),
                            constraint check_prerequisite_course check(Course_Id!=Prerequisite)
    );

create table Students_Exams(
                               Exam_Id number(10),
                               Student_Id number(10),
                               Student_Mark number(5,2) not null,
                               Submission_Date timestamp with time zone not null,
                               constraint fk_student_exam_exams foreign key (Exam_Id) references Exams(Id),
                               constraint fk_student_exam_students foreign key (Student_Id) references Students(Id),
                               constraint pk_student_exam primary key (Exam_Id, Student_Id) using index(create unique index idx_student_exam_id on Students_Exams(Exam_Id, Student_Id))
);


create table Courses_Periods(
                                Course_Id number(10),
                                Period_Id number(10),
                                constraint fk_course_period_course foreign key (Course_Id) references Courses(Id),
                                constraint fk_course_period_lperiod foreign key (Period_Id) references Learning_Periods(Id),
                                constraint pk_course_period_id primary key (Course_Id,Period_Id) using index(
                                    create unique index idx_course_period_id on Courses_Periods(Course_Id,Period_Id))
);


create table Courses_Badges(
                               Course_Id number(10),
                               Badge_Id number(10),
                               constraint fk_courses_badges_course foreign key (Course_Id) references Courses(Id),
                               constraint fk_courses_badges_badge foreign key (Badge_Id) references Badges(Id),
                               constraint pk_courses_badges_id primary key (Course_Id,Badge_Id) using index (create unique index idx_courses_badges_id on Courses_Badges(Course_Id,Badge_Id))
);

create table Badges_Assignments(
                                   Student_Id number(10),
                                   Badge_Id number(10),
                                   constraint fk_badges_assignments_student foreign key (Student_Id) references Students(Id),
                                   constraint fk_badges_assignments_badge foreign key (Badge_Id) references Badges(Id),
                                   constraint pk_badges_assignments_id primary key (Student_Id,Badge_Id) using index (create unique index idx_badges_assignments_id on Badges_Assignments(Student_Id,Badge_Id))
);

CREATE TABLE Grade_Scale (
                             Id number(10) GENERATED ALWAYS AS IDENTITY,
                             Percentage_Min number(5,2) NOT NULL,
                             Percentage_Max number(5,2) NOT NULL,
                             Letter_Grade varchar2(2) NOT NULL,
                             GPA_Points number(3,1) NOT NULL,
                             CONSTRAINT pk_grade_scale PRIMARY KEY (Id) using index(create unique index idx_grade_scale_id on Grade_Scale(Id)),
                             CONSTRAINT uk_grade_scale_range UNIQUE (Percentage_Min, Percentage_Max)
);










