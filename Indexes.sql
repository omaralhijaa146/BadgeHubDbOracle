-- Roles
create index idx_role_upper on Roles(upper(NAME));
create index idx_role_upper_like on Roles(Name) indextype is ctxsys.context;
drop index idx_role_upper_like;
--Users
create index idx_users_role_id on Users(Role_Id);

-- Students
create index idx_students_program_id on Students(Program_Id);

-- Programs
create index idx_Plans_program_id on Plans(Program_Id);

-- Batches
create index idx_batches_plan_id on Batches(Plan_Id);


-- Teachers_Schedules
create index idx_t_sched_days_id on Teachers_Schedules(Day_Id);
create index idx_t_sched_teacher_id on Teachers_Schedules(Teacher_Id);

-- Sections_Schedules
create index idx_sec_schedules_sec_id on Sections_Schedules(Section_Id);
create unique index idx_sec_schedules_day_id on Sections_Schedules(Day_Id);

-- Sections
create index idx_sections_teacher_id on Sections(Teacher_Id);
create index idx_sections_course_id on Sections(Course_Id);

 -- Courses_Plans
create index idx_cp_course_id on Course_Plan(Course_Id);
create index idx_cp_program_id on Course_Plan(Plan_Id);

-- Courses_Periods
create index idx_clp_course_id on Courses_Periods(Course_Id);
create index idx_clp_lp_id on Courses_Periods(Period_Id);

-- Learning Periods
create index idx_lp_current_plan on LEARNING_PERIODS(CURRENT_PERIOD);