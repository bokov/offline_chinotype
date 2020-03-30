

-- pcounts = {0}
-- pconcepts = {1}
-- schema = {2}
-- self.metaschema = {3} 
-- self.termtable = {4}
-- self.branchnodes = {5}
-- self.vfnodes = {6}
-- self.allbranchnodes = {7}
-- pat_totalcount = {8}
create table data_builder.pcounts as --- This seems to be the subquery that creates counts by concept
with np as (select count(distinct patient_num) np from blueherondata.observation_fact),
ttls as (
  select ccd, replace(replace(replace(ccd,'H_',''),'L_',''),'A_','') joinccd
  ,count(distinct pn) total from data_builder.pconcepts
  group by ccd
),/*, ttls2 as (
  select ccd, total from ttls where ccd like 'LOINC:%' or ccd like 
)*/
cd as(
    select concept_cd, min(name) name
    from (
      select c_basecode concept_cd,c_name name from blueheronmetadata.heron_terms --{3}.{4}
      where --({5} or {6}) and {7}
      c_totalnum > 10 and c_visualattributes like 'F%' and c_basecode is not NULL and lower(c_tablename) = 'concept_dimension'
      union all
      select concept_cd,name_char name from blueherondata.concept_dimension
      )
    group by concept_cd
    )
select 
case 
  when ttls.ccd like 'NAACCR|%' then 'NAACCR'
  when instr(joinccd, ':') > 0 then 
      substr(joinccd, 1, instr(joinccd, ':')-1)
  else joinccd
  end prefix
, ttls.ccd --select prefix, ccd
, case 
  when ttls.ccd like 'H~_%' escape '~' then '[ABOVE REFERENCE] '||name
  when ttls.ccd like 'L~_%' escape '~' then '[BELOW REFERENCE] '||name
  when ttls.ccd like 'A~_%' escape '~' then '[ABNORMAL] '||name
  else name
end name
/*
ttls.total is one of these...
the total patients with high values if t2.total is not NULL (so t2.total is the denominator)
the total patients with low values if t3.total is not NULL (so t3.total is the denominator)
the total patients with abnormal values if t4.total is not NULL (so t4.total is the denominator)
the total number of patients having the lab done if all tX.totals null (grand total should be the denominator)
definitely not a hardcoded value! wtf was I thinking
*/
, ttls.total --, ttls.total/coalesce(t2.total,t3.total,t4.total,{8}) frc_total 
, ttls.total/np.np frc_total
from ttls--, np
join np on 1=1
/*
left join ttls2 t2 on ttls.ccd = 'H_'||t2.ccd
left join ttls2 t3 on ttls.ccd = 'L_'||t3.ccd
left join ttls2 t4 on ttls.ccd = 'A_'||t4.ccd
*/
left join cd on cd.concept_cd = ttls.joinccd
where ttls.total > 10
union all
select 'TOTAL' prefix, 'TOTAL' ccd, 'All Patients in Population' name
, np total, 1 frc_total from np;
-- '''.format(pcounts, pconcepts, schema, self.metaschema, self.termtable, self.branchnodes, self.vfnodes, self.allbranchnodes, pat_totalcount)
-- 130 seconds
-- 124.874	0.0	70394
--122.911	0.0	70394
--123.104		70394

alter table data_builder.pcounts add primary key (prefix,ccd);
create unique index data_builder.pcounts_ccd_idx on data_builder.pcounts (ccd);
create index data_builder.pcounts_tl_idx on data_builder.pcounts (total);
