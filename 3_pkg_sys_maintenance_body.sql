CREATE OR REPLACE PACKAGE BODY pkg_sys_maintenance IS
    
    -- Initiate a log journal:
    PROCEDURE journal_log(p_log_entry log_journal%ROWTYPE) IS
    PRAGMA AUTONOMOUS_TRANSACTION;
    BEGIN
      UPDATE log_journal  
      SET ROW = p_log_entry 
      WHERE jrn_id = p_log_entry.jrn_id;

      IF (0 = SQL%ROWCOUNT) THEN
        INSERT INTO log_journal VALUES p_log_entry;
      END IF;
      
      COMMIT;
    END journal_log;

    -- Initiate a log operation:
    PROCEDURE init_oper_log(p_journal_id log_journal.jrn_id%TYPE, 
                            p_oper_id log_operations.oper_type_id%TYPE , 
                            p_indent log_operations.oper_lev%TYPE,
                            p_ord log_operations.ord%TYPE, 
                            p_oper_log OUT log_operations%ROWTYPE,
                            p_sql_text VARCHAR2 DEFAULT NULL) IS
    PRAGMA AUTONOMOUS_TRANSACTION;
    BEGIN
      SELECT seq_log_journal.nextval INTO p_oper_log.rec_id FROM dual;
          
      p_oper_log.jrn_id := p_journal_id; 
      p_oper_log.oper_type_id := p_oper_id;  
      p_oper_log.start_date := sysdate; 
      p_oper_log.end_date := sysdate; 
      p_oper_log.rec_count := 0; 
      p_oper_log.oper_result := 0; 
      p_oper_log.oper_lev := p_indent;
      p_oper_log.ord := p_ord;
      p_oper_log.cmnt := 'Text of SQL query: ' ||p_sql_text;
    END init_oper_log;
  
    -- End a log operation:
    PROCEDURE oper_log(p_oper_log IN OUT log_operations%ROWTYPE,
                                         p_rec_count log_operations.rec_count%TYPE, 
                                         p_result log_operations.oper_result%TYPE, 
                                         p_cmnt log_operations.cmnt%TYPE) IS
    PRAGMA AUTONOMOUS_TRANSACTION;
    BEGIN
      p_oper_log.rec_count := p_rec_count; 
      p_oper_log.end_date := SYSDATE; 
      p_oper_log.oper_duration := (p_oper_log.end_date - p_oper_log.start_date) DAY TO SECOND; 
      p_oper_log.oper_result := p_result;
      p_oper_log.cmnt := p_cmnt;

      INSERT INTO log_operations VALUES p_oper_log;
      COMMIT;
      
      -- Clean a record.
      p_oper_log.jrn_id := NULL;  
    END oper_log;  

    PROCEDURE del_by_stage_id(p_journal_id log_journal.jrn_id%TYPE,
                              p_res_id OUT log_results.res_id%TYPE) AS
        l_exists pls_integer;
        l_count NUMBER := 0; 
        l_count_res NUMBER := 0;
        l_oper_main_log log_operations%ROWTYPE;
        l_oper_log log_operations%ROWTYPE;
        l_msg VARCHAR2(4000);        
    BEGIN
      init_oper_log(p_journal_id, 1, 0, 1, l_oper_main_log);
          
       -- 1. Define a list of titles for deleting.
      init_oper_log(p_journal_id, 6, 1, 1, l_oper_log);
       
      INSERT INTO title_list_by_id
      SELECT tl.id
      FROM title tl 
      JOIN stage stg ON tl.stage_id = stg.ID 
      WHERE (stg.code = 'PP' -- Select titles with mark "to delete" or inactive titles, which are older than 2 weeks.
      AND (tl.delete_date IS NOT NULL OR (tl.isactive = 'N' AND tl.create_date < TRUNC(SYSDATE,'dd')-13)))
      OR (stg.code = 'GP' AND tl.create_date < TRUNC(SYSDATE,'dd')-90); 
      -- Select titles from plan "Recycle", where update date is older than 90 days.
          
      l_count := SQL%ROWCOUNT;
      l_count_res := l_count_res + l_count;
      
      IF l_count = 0 THEN 
          oper_log (l_oper_log, l_count, 1, ' Not found deleted titles.');
      ELSE
          oper_log (l_oper_log, l_count, 1, ' Created list of titles with '||TO_CHAR(l_count)||' records.');
          
          -- 2. Fact indicators.
          init_oper_log(p_journal_id, 5, 1, 2, l_oper_log);
              
          DELETE title_fact_indicator
          WHERE title_id IN (SELECT title_id FROM title_list_by_id);  
              
          l_count := SQL%ROWCOUNT;
          l_count_res := l_count_res + l_count;
          oper_log (l_oper_log, l_count, 1, ' Deleted '||TO_CHAR(l_count)||' records from table TITLE_FACT_INDICATOR.');  

          -- 3. Titles.
          init_oper_log(p_journal_id, 5, 1, 3, l_oper_log);
                  
          DELETE title
          WHERE id IN (SELECT title_id FROM title_list_by_id);
          
          l_count := SQL%ROWCOUNT;
          l_count_res := l_count_res + l_count;
          oper_log (l_oper_log, l_count, 1, ' Deleted '||TO_CHAR(l_count)||' records from table TITLE.');                    
          
      END IF;
      
      -- Close the journal.
      oper_log (l_oper_main_log, l_count_res, 1, 'Processed '||TO_CHAR(l_count_res)||' records.'); 
      p_res_id := 1;
          
      EXCEPTION WHEN OTHERS THEN
          l_msg := 'Error executing the query: ' || SQLCODE || ' - ' || SQLERRM;     
          IF l_oper_log.jrn_id IS NOT NULL THEN 
              oper_log (l_oper_log, 0, 0, l_msg); 
          END IF;
          IF l_oper_main_log.jrn_id IS NOT NULL THEN
              oper_log (l_oper_main_log, 0, 0, l_msg); 
          END IF;

    END del_by_stage_id;
    
    PROCEDURE gather_ind_info(p_journal_id log_journal.jrn_id%TYPE,
                              p_res_id OUT log_results.res_id%TYPE) AS
      l_exists pls_integer;
      l_count NUMBER := 0; 
      l_count_res NUMBER := 0;
      l_oper_main_log log_operations%ROWTYPE;
      l_oper_log log_operations%ROWTYPE;
      l_msg VARCHAR2(4000);        
    BEGIN
      init_oper_log(p_journal_id, 1, 0, 1, l_oper_main_log);
       
      -- 1. Count of titles, which have less than 5 types of indicators.
      init_oper_log(p_journal_id, 4, 1, 2, l_oper_log);
      
      SELECT COUNT(DISTINCT title_number) cnt INTO l_count 
      FROM (SELECT tl.title_number title_number
            FROM title tl
            JOIN title_fact_indicator tlf ON tl.id = tlf.title_id
            LEFT JOIN fact_indicator fi ON fi.ID = tlf.fact_indicator_id
            WHERE tl.isactive = 'Y'
            GROUP BY tl.title_number, tl.ID
            HAVING COUNT(fact_indicator_type_id) < 5); 

      l_count_res := l_count_res + l_count;        
      oper_log (l_oper_log, l_count, 1, 'Count of titles, which have less than 5 types of indicators: '||TO_CHAR(l_count));                        

      -- 2. Count of titles, which refer to a few identical records of table Fact_indicator_classifier.
      init_oper_log(p_journal_id, 4, 1, 3, l_oper_log);
      
      SELECT COUNT(DISTINCT tl.title_number) cnt INTO l_count 
      FROM title tl
      JOIN title_fact_indicator tlf ON tlf.title_id = tl.id
      WHERE tlf.fact_indicator_id IN (SELECT fi.id 
                                      FROM fact_indicator fi
                                      JOIN fact_indicator_item fitm ON fitm.fact_indicator_id = fi.id
                                      JOIN fact_indicator_classifier fclsf ON fitm.fact_indicator_classifier_id = fclsf.id
                                      WHERE fi.fact_indicator_type_id = 1
                                      GROUP BY fi.id, fclsf.financing_source_id, fclsf.power_id
                                      HAVING COUNT(DISTINCT fclsf.id) > 1);
      
      l_count_res := l_count_res + l_count;        
      oper_log (l_oper_log, l_count, 1, 'Count of titles, which refer to a few identical records of table Fact_indicator_classifier: '||TO_CHAR(l_count));

      -- Close the journal.
      oper_log (l_oper_main_log, l_count_res, 1, 'Gather information about indicators.'); 
      p_res_id := 1;
          
      EXCEPTION WHEN OTHERS THEN
          l_msg := 'Error executing the query: ' || SQLCODE || ' - ' || SQLERRM;     
          IF l_oper_log.jrn_id IS NOT NULL THEN 
              oper_log (l_oper_log, 0, 0, l_msg); 
          END IF;
          IF l_oper_main_log.jrn_id IS NOT NULL THEN
              oper_log (l_oper_main_log, 0, 0, l_msg); 
          END IF;

    END gather_ind_info;
    
    PROCEDURE pkg_sys_maintenance(p_log_journal_type log_journal_type.jrn_type_id%TYPE) IS
      l_exists pls_integer;
      l_log_entry log_journal%ROWTYPE;
    BEGIN
      -- Check if the package is starting in another session.
      BEGIN
          SELECT COUNT(*) INTO l_exists 
          FROM log_journal jrn
          WHERE jrn.res_id = 0
          AND jrn.jrn_type_id = p_log_journal_type
          AND EXISTS (SELECT 1 FROM v$session sn
                      WHERE sn.audsid = jrn.audsid AND sn.sid = jrn.sid);
                                      
      EXCEPTION
      WHEN NO_DATA_FOUND THEN l_exists := 0;
      END;                          

      SELECT seq_log_journal.NEXTVAL INTO l_log_entry.jrn_id FROM dual;

      l_log_entry.dat := SYSDATE;
      l_log_entry.osuser := SYS_CONTEXT('USERENV', 'OS_USER');
      l_log_entry.terminal := SYS_CONTEXT('USERENV', 'TERMINAL');
      l_log_entry.ipaddress := SYS_CONTEXT('USERENV', 'IP_ADDRESS');
      l_log_entry.audsid := SYS_CONTEXT('USERENV', 'SESSIONID');
      l_log_entry.sid := SYS_CONTEXT('USERENV', 'SID');
      l_log_entry.jrn_type_id := p_log_journal_type;
      
      IF l_exists > 0 THEN
          l_log_entry.res_id  := 4; -- The package is already started (Dictionary of types is LOG_TASK_RESULTS).
          journal_log(l_log_entry);
      ELSE
          -- Start.
          l_log_entry.res_id := 0;
          
          journal_log(l_log_entry);
          
          CASE p_log_journal_type
          -- Delete titles with mark "to delete".
          WHEN 1 THEN del_by_stage_id(l_log_entry.jrn_id, l_log_entry.res_id);
          -- Gather information about indicators with mistakes.
          WHEN 2 THEN gather_ind_info(l_log_entry.jrn_id, l_log_entry.res_id);
          ELSE RAISE_APPLICATION_ERROR(-29999, 'The procedure is not created. ID = '||p_log_journal_type);
      END CASE;
          
          journal_log(l_log_entry);
          
          IF l_log_entry.res_id = 1 THEN COMMIT;
          ELSE  ROLLBACK;    
          END IF;
          
      END IF;
    END pkg_sys_maintenance;

END pkg_sys_maintenance;