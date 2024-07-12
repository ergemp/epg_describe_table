create role readonly;
grant select on table public.t_test to readonly;

create user reporting_user;
grant readonly to reporting_user;



--
--
--

select * from t_test;

create index ix_t_test_01 on t_test(generate_series);
alter table t_test add constraint pk_t_test_01 primary key (generate_series);

--
--
--

create index ix_customers_01 on customers using btree(first_name);
create index ix_customers_02 on customers using hash(gender);
create index ix_customers_03 on customers using btree(first_name, last_name);


alter table customers add constraint pk_customers_01 primary key (id);

