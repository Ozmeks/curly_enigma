CREATE OR REPLACE PACKAGE pkg_sys_maintenance IS 
    PROCEDURE pkg_sys_maintenance(p_log_journal_type log_journal_type.jrn_type_id%TYPE);
END pkg_sys_maintenance;