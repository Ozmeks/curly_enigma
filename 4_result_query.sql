SELECT jrn.osuser, op_inf.oper_name, op.start_date, op.end_date,
       op.oper_duration, res.res_name, op.cmnt, op.rec_count, op.oper_lev, op.ord
FROM log_operations op 
JOIN log_journal jrn ON op.jrn_id = jrn.jrn_id
JOIN log_oper_type op_inf ON op_inf.oper_type_id = op.oper_type_id
JOIN log_results res ON op.oper_result = res.res_id
WHERE op.jrn_id = (SELECT MAX(jrn_id) FROM log_journal
                   WHERE jrn_type_id = 2)
ORDER BY op.oper_lev, op.ord;