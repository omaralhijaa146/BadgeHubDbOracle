create or replace package error_codes_pkg as

    gc_invalid_batch_id constant number := -20001;
    gc_batch_has_no_stds constant number := -20002;
    gc_batch_has_no_current_period constant number := -20003;
    gc_invalid_batch_requirements constant number := -20004;
    gc_batch_has_remaining_exams constant number := -20005;
    gc_locked_rows constant number := -20054;
    gc_too_many_rows constant number := -1422;
    gc_ora_to_app_base constant number := -20000;
    gc_unknown_error constant number := -20999;

    gc_msg_invalid_batch_id constant varchar2(100) := 'Invalid batch id';
    gc_msg_batch_has_no_stds constant varchar2(100) := 'Batch has no students';
    gc_msg_batch_has_no_current_period constant varchar2(100) := 'Batch has no current period';
    gc_msg_invalid_batch_requirements constant varchar2(100) := 'Invalid batch requirements';
    gc_msg_batch_has_remaining_exams constant varchar2(100) := 'Batch has remaining exams';
    gc_msg_locked_rows constant varchar2(100) := 'Locked rows';
    gc_msg_too_many_rows constant varchar2(100) := 'too many rows fetched instead of one';
end error_codes_pkg;