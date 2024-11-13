# epg_describe_table

epg_describe_table is a shourtcut for obtaining information on a postgresql table including table privileges, columns, statistics and indexes. This is a replacement for a describe command on the database via sql instead of using \d on psql cli. 

Instead of running multiple commands for the detailed table information one function call pushes the information to the stdout with raise notice in plpgsql.

## installation

epg_describe_table.sql create a function with the same name as epg_decribe_table under the util schema. If util schema does not exists, scripts tries to create the schema. So mind the privileges of the user which is executing this sql script on the postgresql database. 

## using the function 

After the successful execution of the script you can call the epg_decribe_table function as below. 

```
call util.epg_describe_table('public','people');
```

## output details

This function writes the notice to the standart output and includes the following information about the table. 

- table/schema ownership
- table privileges
- table grantee: assigned roles
- table columns
- index
- table statistics

## sample output

```
information for table: public.people

----------------------
table/schema ownership
----------------------
relation (table): people
relation owner: postgres
relation acl (privileges): {postgres=arwdDxt/postgres,audit=r/postgres,skynet=arwdDxt/postgres,readonly=r/postgres}
namespace(schema): public
namespace owner: pg_database_owner

----------------
table privileges
----------------
postgres                        INSERT          
postgres                        SELECT          
postgres                        UPDATE          
postgres                        DELETE          
postgres                        TRUNCATE        
postgres                        REFERENCES      
postgres                        TRIGGER         
audit                           SELECT          
skynet                          INSERT          
skynet                          SELECT          
skynet                          UPDATE          
skynet                          DELETE          
skynet                          TRUNCATE        
skynet                          REFERENCES      
skynet                          TRIGGER         
readonly                        SELECT          

-----------------------------
table grantee: assigned roles
-----------------------------
audit:
postgres:
readonly:
reporting_user -> readonly, 
ro_user -> readonly, 
skynet:

-------------
table columns
-------------
tableoid                        oid                             
cmax                            cid                             
xmax                            xid                             
cmin                            cid                             
xmin                            xid                             
ctid                            tid                             
id                              text                            
firstname                       text                            
lastname                        text                            
phone                           text                            

-------------
index: 
-------------
ix_people_01

CREATE INDEX ix_people_01 ON public.people USING btree (id)

index columns: 
id

ix_people_02

CREATE INDEX ix_people_02 ON public.people USING btree (firstname, lastname)

index columns: 
firstname
lastname

----------------
table statistics
----------------
 dead_tuples: 0 
 live_tuples: 4 
 last_vacuum: <NULL> 
 last_autovacuum: <NULL> 
 vacuum_count: 0 
 autovacuum_count: 0 
```

