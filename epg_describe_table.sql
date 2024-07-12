-- drop procedure epg_describe_table (text, text);
create schema if not exists util;

CREATE OR replace PROCEDURE util.epg_describe_table (g_schema_name IN text, g_relation_name IN text)
LANGUAGE plpgsql
AS 
$$
DECLARE
	rel_oid integer;
	user_roles_list text = null;

	c_owner_info cursor (g_schema_name text, g_relation_name text) for 
		select
			pg_class.relname, 
			pg_class.relacl,
			pg_namespace.nspname as namepsace_name,
			nspowner.rolname as namespace_owner,
			relowner.rolname as relation_owner
		from
			pg_class
			left join pg_namespace on (pg_class.relnamespace = pg_namespace.oid) 
			left join pg_roles nspowner on (pg_namespace.nspowner = nspowner.oid) 
			left join pg_roles relowner on (pg_class.relowner = relowner.oid)
		where
			pg_class.relname = g_relation_name and
			pg_namespace.nspname = g_schema_name and
			pg_class.relkind = 'r' 
			;

	c_privilege_info cursor (g_schema_name text, g_relation_name text) for 
		select
			grantor,
			grantee, 
			table_catalog, 
			table_schema, 
			table_name, 
			privilege_type, 
			is_grantable	
		from
			information_schema.table_privileges
		where 
			table_name = g_relation_name and 
			table_schema = g_schema_name;

	c_distinct_users_info cursor (g_schema_name text, g_relation_name text) for 
		select
			distinct grantee
		from
			information_schema.table_privileges
		where 
			table_name = g_relation_name and 
			table_schema = g_schema_name;

	c_role_info cursor (g_role_name text) for 
		WITH RECURSIVE x AS
		(
		  SELECT member::regrole,
		         roleid::regrole AS role,
		         member::regrole || ' -> ' || roleid::regrole AS path
		  FROM pg_auth_members AS m
		  WHERE roleid > 16384
		  UNION ALL
		  SELECT x.member::regrole,
		         m.roleid::regrole,
		         x.path || ' -> ' || m.roleid::regrole
		 FROM pg_auth_members AS m
		    JOIN x ON m.member = x.role
		  )
		  SELECT member, role, path
		  FROM x
		  where x.role::text = g_role_name
		  ORDER BY member::text, role::text;

	c_column_info cursor (g_schema_name text, g_relation_name text) for 
		select
			pg_class.relname, 
			pg_attribute.attname,
			pg_type.typname
		from
			pg_class
			left join pg_namespace on (pg_class.relnamespace = pg_namespace.oid) 	
			left join pg_attribute on (pg_attribute.attrelid = pg_class.oid)
			left join pg_type on (pg_attribute.atttypid = pg_type.oid)
		where
			pg_class.relname = g_relation_name and
			pg_namespace.nspname = g_schema_name and
			pg_class.relkind = 'r' 
			;
		
	c_index_info cursor (g_schema_name text, g_relation_name text) for 
		select 
			pg_indexes.schemaname, 
			pg_indexes.tablename, 
			pg_indexes.indexname, 
			pg_indexes.indexdef,
			pg_class.relname,
			pg_class.oid as index_oid
		from 
			pg_indexes
			join pg_class on (pg_class.relname=pg_indexes.indexname)
		where 
			tablename=g_relation_name and 
			schemaname=g_schema_name
			;
		
	c_index_columns cursor (g_schema_name text, g_relation_name text, g_index_name text) for 
		select 
			pg_indexes.schemaname, 
			pg_indexes.tablename, 
			pg_indexes.indexname, 
			pg_indexes.indexdef,
			pg_class.relname,
			pg_class.oid as index_oid,
			pg_attribute.attname	
		from 
			pg_indexes
			join pg_class on (pg_class.relname=pg_indexes.indexname)
			join pg_attribute on (pg_class.oid=pg_attribute.attrelid)
		where 
			tablename=g_relation_name and 
			schemaname=g_schema_name and 
			indexname=g_index_name
			;	
				
	c_table_stats cursor (g_schema_name text, g_relation_name text)	 for
		select
			n_live_tup,
			n_dead_tup,
			last_vacuum,
			last_autovacuum,
			last_analyze, 
			last_autoanalyze,
			vacuum_count, 
			autovacuum_count, 
			analyze_count, 
			autoanalyze_count
		from
			pg_stat_all_tables
		where 
			relname = g_relation_name and 
			schemaname = g_schema_name 
			;
				
BEGIN
	--raise info 'information message %', now();
	raise info 'information for table: %.%', g_schema_name, g_relation_name;
		
	raise notice '%', chr(10);
	raise notice '----------------------';		
	raise notice 'table/schema ownership';		
	raise notice '----------------------';			
	raise notice '%', chr(10);

	for r_owner_info in c_owner_info(g_schema_name, g_relation_name)
	loop
		raise notice 'relation (table): %', r_owner_info.relname;
		raise notice 'relation owner: %', r_owner_info.relation_owner;	
		raise notice 'relation acl (privileges): %', r_owner_info.relacl;
		raise notice 'namespace(schema): %', r_owner_info.namepsace_name;
		raise notice 'namespace owner: %', r_owner_info.namespace_owner;				
	end loop;

	raise notice '%', chr(10);
	raise notice '----------------';		
	raise notice 'table privileges';		
	raise notice '----------------';			
	raise notice '%', chr(10);

	for r_privilege_info in c_privilege_info(g_schema_name, g_relation_name)
	loop
		raise notice '%', rpad(r_privilege_info.grantee,32,' ') || '' || rpad(r_privilege_info.privilege_type,16,' ');		
	end loop;
	
	raise notice '%', chr(10);
	raise notice '-----------------------------';		
	raise notice 'table grantee: assigned roles';		
	raise notice '-----------------------------';			
	raise notice '%', chr(10);
	for r_distinct_users_info in c_distinct_users_info (g_schema_name, g_relation_name)
	loop		
		raise notice '%:', r_distinct_users_info.grantee;			
			for r_role_info in c_role_info (r_distinct_users_info.grantee)
			loop
				raise notice '%, ', r_role_info.path;
			end loop;
			
			user_roles_list = '';			
	end loop;
	
	raise notice '%', chr(10);
	raise notice '-------------';		
	raise notice 'table columns';		
	raise notice '-------------';		
	raise notice '%', chr(10);

	for r_column_info in c_column_info(g_schema_name, g_relation_name)
	loop
		raise notice '%', rpad(r_column_info.attname,32,' ') || '' || rpad(r_column_info.typname,32,' ');		
	end loop;

	raise notice '%', chr(10);
	raise notice '-------------';		
	raise notice 'index: ';		
	raise notice '-------------';		
	raise notice '%', chr(10);
	for r_index_info in c_index_info(g_schema_name, g_relation_name)
	loop
		raise notice '%', r_index_info.indexname || chr(10);		
		raise notice '%', r_index_info.indexdef || chr(10);	
		
		raise notice 'index columns: %', chr(10);	
		for r_index_columns in c_index_columns(g_schema_name, g_relation_name,r_index_info.indexname)
		loop			
			raise notice '%', r_index_columns.attname;			
		end loop;
	    raise notice '%', chr(10);
			
	end loop;


	raise notice '%', chr(10);
	raise notice '----------------';		
	raise notice 'table statistics';		
	raise notice '----------------';		
	raise notice '%', chr(10);

	for r_table_stat in c_table_stats(g_schema_name, g_relation_name)
	loop
		/*
		raise notice 'dead_tuples: %', r_table_stat.n_dead_tup || chr(10);		
		raise notice 'live_tuples: %', r_table_stat.n_live_tup || chr(10);
		raise notice 'last_vacuum: %', r_table_stat.last_vacuum || chr(10);
		raise notice 'last_autovacuum: %', r_table_stat.last_autovacuum || chr(10);
		raise notice 'vacuum_count: %', r_table_stat.vacuum_count || chr(10);
		raise notice 'autovacuum_count: %', r_table_stat.autovacuum_count || chr(10);	
		*/
		raise notice E' dead_tuples: % \n live_tuples: % \n last_vacuum: % \n last_autovacuum: % \n vacuum_count: % \n autovacuum_count: % ' 					 , 
			r_table_stat.n_dead_tup, 
			r_table_stat.n_live_tup,
			r_table_stat.last_vacuum,
			r_table_stat.last_autovacuum,
			r_table_stat.vacuum_count,
			r_table_stat.autovacuum_count
			;
	end loop;

END
$$;


call util.epg_describe_table('public','t_test');

