# epg_describe_table

## installation

epg_describe_table.sql create a function with the same name as epg_decribe_table under the util schema. If util schema does not exists, scripts tries to create the schema. So mind the privileges of the user which is executing this sql script on the postgresql database. 

After the successful execution of the script you can call the epg_decribe_table function as below. 

call util.epg_describe_table('public','people');

This function writes the notice to the standart output and includes the following information about the table. 

