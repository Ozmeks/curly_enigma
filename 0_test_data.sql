-- // Create test data structure
 CREATE TABLE stage(ID NUMBER, 
                    NAME VARCHAR2(300 BYTE),
                    code VARCHAR2(100 BYTE),
                    CONSTRAINT pk_stage PRIMARY KEY (ID));
        
 CREATE TABLE title(ID NUMBER, 
                    title_number NUMBER, 
                    stage_id NUMBER, 
                    create_date DATE, 
                    delete_date DATE,
                    isactive VARCHAR2(1 CHAR),
                    CONSTRAINT pk_title PRIMARY KEY (ID),
                    CONSTRAINT fk_tl_stage FOREIGN KEY (stage_id)
                    REFERENCES stage (ID) ENABLE);
 
 CREATE TABLE fact_indicator_classifier(ID NUMBER, 
                                        financing_source_id NUMBER, 
                                        power_id NUMBER,
                                        CONSTRAINT pk_fact_indicator_classifier PRIMARY KEY (ID));
 
 CREATE TABLE fact_indicator(ID NUMBER, 
                             fact_indicator_type_id NUMBER,
                             CONSTRAINT pk_fact_indicator PRIMARY KEY (ID));
 
 CREATE TABLE fact_indicator_item(ID NUMBER, 
                                  fact_indicator_id NUMBER, 
                                  fact_indicator_classifier_id NUMBER,
                                  CONSTRAINT pk_fact_indicator_item PRIMARY KEY (ID),
                                  CONSTRAINT fk_item_clsf FOREIGN KEY (fact_indicator_classifier_id)
                                  REFERENCES fact_indicator_classifier (ID) ENABLE,
                                  CONSTRAINT fk_item_ind FOREIGN KEY (fact_indicator_id)
                                  REFERENCES fact_indicator (ID) ENABLE);
                                  
 CREATE TABLE title_fact_indicator(title_id NUMBER, 
                                   fact_indicator_id NUMBER,
                                   CONSTRAINT fk_tlf_tl FOREIGN KEY (title_id)
                                   REFERENCES title (ID) ENABLE,
                                   CONSTRAINT fk_tlf_ind FOREIGN KEY (fact_indicator_id)
                                   REFERENCES fact_indicator (ID) ENABLE);
 
 CREATE GLOBAL TEMPORARY TABLE title_list_by_id(title_id NUMBER) ON COMMIT DELETE ROWS;

-- // Insert test data
-- 1. stage
INSERT INTO stage(ID, NAME, code)
VALUES(1, 'General plan', 'GP');

INSERT INTO stage(ID, NAME, code)
VALUES(2, 'Private plan', 'PP');

-- 2. title
INSERT INTO title(ID, title_number, stage_id, create_date, delete_date, isactive)
VALUES(1, 5, 1, TO_DATE('09.01.2017 14:01','dd.mm.yyyy hh24:mi'), NULL, 'Y');

INSERT INTO title(ID, title_number, stage_id, create_date, delete_date, isactive)
VALUES(2, 23, 2, TO_DATE('17.12.2016 11:01','dd.mm.yyyy hh24:mi'), TO_DATE('10.01.2017 14:31','dd.mm.yyyy hh24:mi'), 'N');

INSERT INTO title(ID, title_number, stage_id, create_date, delete_date, isactive)
VALUES(3, 23, 2, TO_DATE('10.01.2017 14:32','dd.mm.yyyy hh24:mi'), NULL, 'Y');

-- 3. fact_indicator
INSERT INTO fact_indicator(ID, fact_indicator_type_id)
VALUES(1, 1);

INSERT INTO fact_indicator(ID, fact_indicator_type_id)
VALUES(2, 1);

INSERT INTO fact_indicator(ID, fact_indicator_type_id)
VALUES(4, 1);

-- 4. fact_indicator_classifier
INSERT INTO fact_indicator_classifier(ID, financing_source_id, power_id)
VALUES(1, 4, 16);

INSERT INTO fact_indicator_classifier(ID, financing_source_id, power_id)
VALUES(2, 4, 16);

-- 5. fact_indicator_item
INSERT INTO fact_indicator_item(ID, fact_indicator_id, fact_indicator_classifier_id)
VALUES(1, 1, 1);

INSERT INTO fact_indicator_item(ID, fact_indicator_id, fact_indicator_classifier_id)
VALUES(2, 2, 1);

INSERT INTO fact_indicator_item(ID, fact_indicator_id, fact_indicator_classifier_id)
VALUES(3, 2, 2);

-- 6. title_fact_indicator
INSERT INTO title_fact_indicator(title_id, fact_indicator_id)
VALUES(1,1);

INSERT INTO title_fact_indicator(title_id, fact_indicator_id)
VALUES(1,2);

INSERT INTO title_fact_indicator(title_id, fact_indicator_id)
VALUES(2,4);

INSERT INTO title_fact_indicator(title_id, fact_indicator_id)
VALUES(3,4);

COMMIT;


