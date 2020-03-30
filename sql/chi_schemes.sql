create table data_builder.chischemes as
select c_key, prefix c_name, c_description 
from (select distinct prefix from data_builder.pcounts) pct
left join blueheronmetadata.schemes
on prefix = blueheronmetadata.schemes.c_name
where prefix is not null
;

update data_builder.chischemes set c_key = c_name where c_key is null;
update data_builder.chischemes set c_key = c_key||':' where c_key not like '%:';
update data_builder.chischemes set c_description = c_name where c_description is null;
alter table data_builder.chischemes add primary key (c_name);
