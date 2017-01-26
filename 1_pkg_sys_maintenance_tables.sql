  -- 1. log_journal_type  
  CREATE TABLE log_journal_type
    (jrn_type_id NUMBER NOT NULL ENABLE, 
     jrn_type_name VARCHAR2(500 BYTE) NOT NULL ENABLE, 
    CONSTRAINT pk_log_journal_type PRIMARY KEY (jrn_type_id));
  
  COMMENT ON COLUMN log_journal_type.jrn_type_id IS 'Journal type ID';
  COMMENT ON COLUMN log_journal_type.jrn_type_name IS 'Journal type name';
  COMMENT ON TABLE log_journal_type IS 'Dictionary of journal types';
  
  INSERT INTO log_journal_type (jrn_type_id, jrn_type_name) VALUES ('1','Delete titles with mark "to delete"');
  INSERT INTO log_journal_type (jrn_type_id, jrn_type_name) VALUES ('2','Gather information about indicators with mistakes');
  
  -- 2. log_results
  CREATE TABLE log_results
    (res_id NUMBER NOT NULL ENABLE, 
     res_name VARCHAR2(300 BYTE) NOT NULL ENABLE, 
     res_desc VARCHAR2(4000 BYTE), 
     ord NUMBER NOT NULL ENABLE, 
    CONSTRAINT pk_log_results PRIMARY KEY (res_id));
  
  COMMENT ON COLUMN log_results.res_id IS 'Result ID';
  COMMENT ON COLUMN log_results.res_name IS 'Result name';
  COMMENT ON COLUMN log_results.res_desc IS 'Description';
  COMMENT ON COLUMN log_results.ord IS 'Order';
  COMMENT ON TABLE log_results IS 'Dictionary of options for completing a task';

  INSERT INTO log_results (res_id, res_name, res_desc, ord) VALUES ('0','Executing',NULL,'0');
  INSERT INTO log_results (res_id, res_name, res_desc, ord) VALUES ('1','Success',NULL,'1');
  INSERT INTO log_results (res_id, res_name, res_desc, ord) VALUES ('2','No data',NULL,'2');
  INSERT INTO log_results (res_id, res_name, res_desc, ord) VALUES ('3','Not done',NULL,'3');
  INSERT INTO log_results (res_id, res_name, res_desc, ord) VALUES ('4','Duplicated start',NULL,'4');  
  
  -- 3. log_journal
  CREATE TABLE log_journal
   (jrn_id NUMBER NOT NULL ENABLE, 
    dat DATE, 
    osuser VARCHAR2(30 BYTE), 
    terminal VARCHAR2(30 BYTE), 
    ipaddress VARCHAR2(30 BYTE), 
    res_id NUMBER, 
    errors NUMBER, 
    warnings NUMBER, 
    audsid NUMBER, 
    sid NUMBER, 
    jrn_type_id NUMBER, 
    CONSTRAINT pk_log_journal PRIMARY KEY (jrn_id), 
    CONSTRAINT fk_jrn_type FOREIGN KEY (jrn_type_id)
      REFERENCES log_journal_type (jrn_type_id) ENABLE, 
    CONSTRAINT fk_log_result FOREIGN KEY (res_id)
      REFERENCES log_results (res_id) ENABLE);

  COMMENT ON COLUMN log_journal.jrn_id IS 'Journal ID';
  COMMENT ON COLUMN log_journal.dat IS 'Start date';
  COMMENT ON COLUMN log_journal.osuser IS 'Operation system user';
  COMMENT ON COLUMN log_journal.terminal IS 'Terminal, where the task was started';
  COMMENT ON COLUMN log_journal.ipaddress IS 'IP address, where the task was started';
  COMMENT ON COLUMN log_journal.res_id IS 'Result ID';
  COMMENT ON COLUMN log_journal.errors IS 'The number of errors';
  COMMENT ON COLUMN log_journal.warnings IS 'The number of warnings';
  COMMENT ON COLUMN log_journal.audsid IS 'Session ID';
  COMMENT ON COLUMN log_journal.sid IS 'User SID';
  COMMENT ON COLUMN log_journal.jrn_type_id IS 'Journal type ID';
  COMMENT ON TABLE log_journal IS 'Journals';
  
  CREATE INDEX indx_jrn_type ON log_journal (jrn_type_id);
  
  CREATE INDEX indx_res ON log_journal (res_id);

  -- 4. log_oper_type
  CREATE TABLE log_oper_type
    (oper_type_id NUMBER NOT NULL ENABLE, 
     oper_name VARCHAR2(300 BYTE) NOT NULL ENABLE, 
     ord NUMBER DEFAULT 0, 
    CONSTRAINT pk_log_oper_type PRIMARY KEY (oper_type_id));
  
  COMMENT ON COLUMN log_oper_type.oper_type_id IS 'Operation type ID';
  COMMENT ON COLUMN log_oper_type.oper_name IS 'Operation type name';
  COMMENT ON COLUMN log_oper_type.ord IS 'Order';
  COMMENT ON TABLE log_oper_type IS 'Dictionary of operation types';
   
  INSERT INTO log_oper_type (oper_type_id, oper_name, ord) VALUES ('1','Start','1');
  INSERT INTO log_oper_type (oper_type_id, oper_name, ord) VALUES ('2','Insert data','2');
  INSERT INTO log_oper_type (oper_type_id, oper_name, ord) VALUES ('3','Add partitions','3');
  INSERT INTO log_oper_type (oper_type_id, oper_name, ord) VALUES ('4','Gather statistics','4');
  INSERT INTO log_oper_type (oper_type_id, oper_name, ord) VALUES ('5','Delete data','5');
  INSERT INTO log_oper_type (oper_type_id, oper_name, ord) VALUES ('6','Prepare data','6');
  
  -- 5. log_operations  
  CREATE TABLE log_operations
    (rec_id NUMBER NOT NULL ENABLE, 
     jrn_id NUMBER NOT NULL ENABLE, 
     oper_type_id NUMBER NOT NULL ENABLE, 
     start_date DATE, 
     end_date DATE, 
     oper_duration INTERVAL DAY (1) TO SECOND (0), 
     rec_count NUMBER, 
     oper_result NUMBER, 
     cmnt VARCHAR2(4000 BYTE), 
     oper_lev NUMBER DEFAULT 0, 
     ord NUMBER, 
    CONSTRAINT pk_log_operations PRIMARY KEY (rec_id), 
    CONSTRAINT fk_log_oper FOREIGN KEY (oper_type_id)
      REFERENCES log_oper_type (oper_type_id) ENABLE, 
    CONSTRAINT fk_log_oper_jrn FOREIGN KEY (jrn_id)
      REFERENCES log_journal (jrn_id) ON DELETE CASCADE ENABLE);

  COMMENT ON COLUMN log_operations.rec_id IS 'Operation ID';
  COMMENT ON COLUMN log_operations.jrn_id IS 'Journal ID';
  COMMENT ON COLUMN log_operations.oper_type_id IS 'Operation type ID';
  COMMENT ON COLUMN log_operations.start_date IS 'Start time operation';
  COMMENT ON COLUMN log_operations.end_date IS 'End time operation';
  COMMENT ON COLUMN log_operations.oper_duration IS 'The duration of the operation';
  COMMENT ON COLUMN log_operations.rec_count IS 'Record count';
  COMMENT ON COLUMN log_operations.oper_result IS 'Operation result (success or not)';
  COMMENT ON COLUMN log_operations.cmnt IS 'Comment';
  COMMENT ON COLUMN log_operations.oper_lev IS 'Operation level (use for the reports)';
  COMMENT ON COLUMN log_operations.ord IS 'Order';
  COMMENT ON TABLE log_operations IS 'Protocols operations';
  
  CREATE INDEX indx_journal ON log_operations (jrn_id);
  
  CREATE INDEX indx_oper_type ON log_operations (oper_type_id);
  
  -- 6. sequence
  CREATE SEQUENCE seq_log_journal MINVALUE 1 MAXVALUE 9999999999999999999999999999 INCREMENT BY 1 START WITH 1 CACHE 20 NOORDER NOCYCLE;
  

  