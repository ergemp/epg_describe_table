
-- owner info
select
	pg_class.relname, 
	pg_namespace.nspname as namepsace_name,
	nspowner.rolname as namespace_owner,
	relowner.rolname as relation_owner
from
	pg_class
	left join pg_namespace on (pg_class.relnamespace = pg_namespace.oid) 
	left join pg_roles nspowner on (pg_namespace.nspowner = nspowner.oid) 
	left join pg_roles relowner on (pg_class.relowner = relowner.oid)
where
	pg_class.relname = 'client' and
	pg_namespace.nspname = 'public' and
	pg_class.relkind = 'r' 
	;

-- column info
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
	pg_class.relname = 'client' and
	pg_namespace.nspname = 'public' and
	pg_class.relkind = 'r' 
	;

-- index info 
select * from pg_class where relkind='i' and relname like '%customers%';

select * from pg_class;

select 
	pg_indexes.schemaname, 
	pg_indexes.tablename, 
	pg_indexes.indexname, 
	pg_indexes.indexdef,
	pg_class.relname,
	pg_class.oid as index_oid,
	array_agg(pg_attribute.attname) as index_column
from 
	pg_indexes
	join pg_class on (pg_class.relname=pg_indexes.indexname)
	join pg_attribute on (pg_attribute.attrelid = pg_class.oid)
where 
	tablename='customers' and 
	schemaname='public'
group by 1,2,3,4,5,6	
	;



select * from pg_catalog.pg_attribute where attrelid = 16909 ;

-- index column info
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
	tablename='client' and 
	schemaname='public' and 
	indexname='Client_pkey'
	;

-- table acl 
select
	pg_class.relname, 
	pg_class.relacl
from
	pg_class
	left join pg_namespace on (pg_class.relnamespace = pg_namespace.oid) 
	left join pg_roles nspowner on (pg_namespace.nspowner = nspowner.oid) 
	left join pg_roles relowner on (pg_class.relowner = relowner.oid)
where
	pg_class.relname = 'customers' and
	pg_namespace.nspname = 'public' and
	pg_class.relkind = 'r' 
	;

-- table privileges
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
	table_name = 'customers' and 
	table_schema = 'public';

-- distinct user list granted any privilege on table
select
	distinct grantee
from
	information_schema.table_privileges
where 
	table_name = 'customers' and 
	table_schema = 'public';

with recursive cte as (
	select
		oid
	from
		pg_roles
	where
		rolname = 'readonly'
	union all
	select
		m.roleid
	from
		cte
	join pg_auth_members m on
		m.member = cte.oid
	   )
	select
		oid,
		oid::regrole::text as rolename
	from
		cte;
	
	
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
  where x.role::text = 'readonly'
  ORDER BY member::text, role::text

  ;
 

			
revoke postgres from test_user;
--
--
--

select length('ergemp');
select substring('ergemp',1,6);


select substring(',ergemp',1,1)
select substring(',ergemp',1)

select substring(trim('ergemp, '),length(trim('ergemp, ')),1)

--
--
--


create role test_role;
grant test_role to test_user;
grant postgres to test_user;

select * from pg_index;
select * from pg_tables;
select * from pg_class;


--
--
--

select * from pg_catalog.pg_class;
select * from pg_catalog.pg_namespace ;
select * from pg_catalog.pg_attribute;

select * from information_schema.table_privileges;

select * from pg_catalog.pg_roles;
select * from pg_catalog.pg_authid;
select * from pg_catalog.pg_auth_members;

select * from pg_catalog.pg_type;





