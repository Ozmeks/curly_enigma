Here is a package for launching regulatory procedures for Oracle Database, such as loading, deleting or gathering data. The idea of the package is base constructions of logging with using autonomous transactions and launching different procedures.
Here are the scripts:

1. The “0_test_data.sql” create some tables and data for testing. The tables are not real and without any comments, they are here to show how the package works.
2. The “1_pkg_sys_maintenance_tables.sql” create log tables. You need it to use the package.
3. The “2_pkg_sys_maintenance_spec.sql” create a package specification.
4. The “3_pkg_sys_maintenance_body.sql” create a package body. You should check before if your user has grant select on view v_$session.
5. The “4_result_query.sql” contains a query with results of the package executing.

When you executed the first four scripts, you will have the compiled package with two test procedures: deleting and gathering data.
