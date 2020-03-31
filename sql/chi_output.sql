@set maxrows -1;
@export on;
@export set filename="/tmp/${chi_name}$.tsv"
        format="csv"
        ShowNullAs='';
/*
God, this is awful. 
*/
with 
cohort as (
    select ${chi_name}$ pat_count from data_builder.pcounts where ccd = 'TOTAL'
)
, data as (
    select prefix, c_description category, ccd
    , name
    , ${ref||total}$
    , frc_${ref||total}$ 
    , ${chi_name}$
    , frc_${chi_name}$
    -- , power({0} - (cohort.pat_count * frc_{3}), 2) / (cohort.pat_count * frc_{3}) chisq
    -- oops, that's not really chisq df=1, but the below is...
    , case 
      when frc_${ref||total}$ = frc_${chi_name}$ then 0
      when frc_${ref||total}$ = 1 or frc_${chi_name}$ = 1 then null
      else
      power(${chi_name}$ - (cohort.pat_count * frc_${ref||total}$), 2)*(1/(cohort.pat_count * frc_${ref||total}$) + 
      1/((cohort.pat_count-${chi_name}$) * frc_${ref||total}$) + 1/(cohort.pat_count * (1-frc_${ref||total}$)) + 
      1/((cohort.pat_count-${chi_name}$) * (1-frc_${ref||total}$))) 
      end chisq
    , case 
      when frc_${chi_name}$=frc_${ref||total}$ then 1 
      when frc_${chi_name}$ in (0,1) or frc_${ref||total}$ in (0,1) then 0
      else
      (1-frc_${ref||total}$)*frc_${chi_name}$/((1-frc_${chi_name}$)*frc_${ref||total}$) 
      end odds_ratio
    , case when frc_${ref||total}$ = frc_${chi_name}$ then 0 when frc_${ref||total}$ < frc_${chi_name}$ then 1 else -1 end dir
    from data_builder.pcounts left join data_builder.chischemes on prefix = data_builder.chischemes.c_name
    , cohort
    where frc_${ref||total}$ > 0   -- reference patient set frequency
    --{5}
    --where frc_{3} > 0 or frc_{0} > 0
)
, ranked_data as (
    select data.*
    --, row_number() over (order by chisq*dir desc) as rank
    --, row_number() over (order by chisq*dir asc) as revrank  -- this is not a useless line
    , row_number() over (order by odds_ratio desc) as rank
    , row_number() over (order by odds_ratio asc) as revrank  -- this is not a useless line
    from data   
    --join patterns on data.prefix = patterns.c_name 
    where ccd != 'TOTAL'
    order by rank
) 
select prefix, category, ccd, name, ${ref||total}$, frc_${ref||total}$, ${chi_name}$, frc_${chi_name}$, chisq, odds_ratio, dir
from data where ccd = 'TOTAL'
union all
select prefix, category, ccd, name, ${ref||total}$, frc_${ref||total}$, ${chi_name}$, frc_${chi_name}$, chisq, odds_ratio, dir
from ranked_data --{2}
--'''.format(self.chi_name, self.pcounts, limstr, self.ref, filterStr, cutoff, self.chischemes)
-- 0.526	13.653	70394 efi000
-- 0.669	14.343	70394 efibt000010
-- 0.674	14.972	70394 efibt010020
-- 0.678	13.991	70394 efigt020