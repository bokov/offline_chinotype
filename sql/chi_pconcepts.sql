create table data_builder.pconcepts as
select patient_num pn, concept_cd ccd -- your basic list of distinct patients and raw concept codes from the datamart (1)
from blueherondata.observation_fact obs
union
select obs.patient_num pn, c_basecode ccd -- distinct patients and certain branch nodes, as gathered from the ontology (3).(4)
from blueheronmetadata.heron_terms
join blueherondata.concept_dimension cd  		-- use obs_fact
on concept_path like c_dimcode||'%' 
join blueherondata.observation_fact obs 		-- use obs_fact
on cd.concept_cd = obs.concept_cd 	-- usje obs_fact
where -- selection criteria affecting all branch nodes
c_totalnum > 10 and c_visualattributes like 'F%' and c_basecode is not NULL and lower(c_tablename) = 'concept_dimension' --{7}
union -- same as above, but facts that are outside their reference ranges, i.e. labs
select patient_num pn,valueflag_cd||'_'||concept_cd ccd --c_basecode ccd 
from
/* blueheronmetadata.heron_terms
join blueherondata.concept_dimension cd  		-- use obs_fact
on concept_path like c_dimcode||'%' 
join */
blueherondata.observation_fact obs 		-- use obs_fact
/*on cd.concept_cd = obs.concept_cd 	-- use obs_fact */
where 
/*
-- the below used to work when we had LOINC folders with Epic COMPONENT_IDs within them, but now LOINC is mapped directly to CONCEPT_CD
-- An open question what to do for sites that do it the folder way
c_totalnum > 10 and c_visualattributes like '0%' and c_basecode is not NULL and lower(c_tablename) = 'concept_dimension'
AND */
valueflag_cd != '@'
;
--'''.format(pconcepts, self.schema, self.chipats, self.metaschema, self.termtable, self.branchnodes, self.vfnodes, self.allbranchnodes)
-- 539.557	0.0	35694483

alter table data_builder.pconcepts add primary key (ccd,pn);
-- Okay seem to have PCONCEPTS and PCOUNTS, now let's test it...
select * from data_builder.pcounts where prefix in ( 'ICD9','ICD10');
select * from data_builder.pcounts where CCD like 'ICD10:R41%';
select * from data_builder.pcounts where ccd like 'ICD9:211%';
select * from data_builder.pcounts where ccd like 'ICD9:V58%';
-- seems okay