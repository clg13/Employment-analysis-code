*shift work and COVID using version 11 of biobank 

* COVID-19 in UK Biobank 

count
*502537

** DATA EXCLUSIONS **

**** 1) Remove participants from Wales and Scotland
tab country 
keep if country=="eng"
*56,649 obs dropped


**** 2) Exclude those who died before first covid censoring - 16/03/2020
tab death2
sort dod3
* up to 16mar2020 - need to check this manually (i.e. go to dod3 and up to row #25318# (last death date of 18/09/2020))
drop in 1/25318


** COVID-19 Groups **
* Severe covid (hospital tested) vs no severe covid
tab sevcovid, missing

* generate a new variable for severe infection (positive hospital test or covid death, +ve outpatient covid tests removed unless also had a covid death)
gen coviddeath = 1 if death2 == 1 & strpos(primarydeathcause,"U")
replace coviddeath = 0 if missing(coviddeath)
tab coviddeath death2
tab sevcovid coviddeath, missing

gen sevinfect=0
*remove +ve outpatient tests (n=667)
replace sevinfect=. if sevcovid==.
replace sevinfect=1 if sevcovid==1 | coviddeath==1
 
tab sevinfect sevcovid, missing 


***merging database with occupation database
use "job and shift data.dta", clear
keep n_eid n_826_0_0 n_3426_0_0 n_132_0_0 n_132_1_0 n_132_2_0
rename n_eid id
rename n_826_0_0 shift_work
rename n_3426_0 night_shift_work
save "jobshift.dta", replace

use "analysisv11.dta", clear
rename n_eid id
drop _merge
merge 1:1 id using jobshift
drop if _merge ==2

lab var eth2 "Ethnicity"

tab shift_work

***LOSE "don't know" and "prefer not to say" from SHIFTWORK AND NIGHT SHIFTWORK
replace shift_work =. if shift_work < 0
tab shift_work 

*Healthcare workers
gen 	healthworker=1 if n_132_0_0>=2211001 & n_132_0_0<=2216012
replace healthworker=1 if n_132_1_0>=2211001 & n_132_1_0<=2216012
replace healthworker=1 if n_132_2_0>=2211001 & n_132_2_0<=2216012
replace healthworker=0 if healthworker==.

*remove retired from healthcarer worker=yes (checked and already removed for shift_work and night_shift_work)
tab healthworker employment
gen healthworker_curr =healthworker
recode healthworker_curr 1=0 if employment==2

tab sevinfect shift_work

*"usually" small numbers so collapsing into never/rarely, soemtimes, usually/always
gen shift_work_2 = shift_work
recode shift_work_2 4=3
lab def shift_work_2 1 "Never/rarely" 2 "Sometimes" 3 "Usually/always"
lab values shift_work_2 shift_work_2

*collapsing into 2 catefories, never/rarely, sometimes/usually/always
gen shift_work_3 = shift_work_2
recode shift_work_3 3=2
lab def shift_work_3 1 "Never/rarely" 2 "Sometimes/Usually/always"
lab values shift_work_3 shift_work_3
tab shift_work_2 shift_work_3

*generate cancer yes/no variables from cancers (number of self-reported cancers)
gen cancer=cancers
recode cancer 2/10=1

*generate co-morbidities yes/no variables from ncancers (number of self-reported non cancer illnesses)
gen comorb=ncancers
recode comorb 2/30=1

*generate combined shift worker/health worker variables
gen health_shift=healthworker_curr
recode health_shift 0/1=0 if healthworker_curr==0 & shift_work_3==1
recode health_shift 0/1=1 if healthworker_curr==0 & shift_work_3==2
recode health_shift 0/1=2 if healthworker_curr==1 & shift_work_3==1
recode health_shift 0/1=3 if healthworker_curr==1 & shift_work_3==2
recode health_shift 0/3=. if shift_work_3==.
tab health_shift
lab def health_shift 0 "Not shift or health worker" 1 "Not healthworker but shift worker" 2 "Healthworker not shift worker" 3 "Health and shift worker"
lab values health_shift health_shift

*logistic reg final models
logistic sevinfect i.health_shift covidage sex imd bmi cancer i.smoking i.eth2 comorb
*for baseline table (incldued participants only)
tab sevinfect if e(sample)
tab health_shift if e(sample)
tab sex if e(sample)
tab eth2 if e(sample)
tab cancer if e(sample)
tab smoking if e(sample)
tab comorb if e(sample)
sum covidage imd bmi if e(sample)
by sevinfect, sort:tab health_shift if e(sample)
by sevinfect, sort:tab sex if e(sample)
by sevinfect, sort:tab eth2 if e(sample)
by sevinfect, sort:tab cancer if e(sample)
by sevinfect, sort:tab smoking if e(sample)
by sevinfect, sort:tab comorb if e(sample)
by sevinfect, sort:sum covidage if shift_work!=. & e(sample)

*stratify by sex
logistic sevinfect i.health_shift covidage imd bmi cancer i.smoking i.eth2 comorb if sex==0
logistic sevinfect i.health_shift covidage imd bmi cancer i.smoking i.eth2 comorb if sex==1

*stratify by ethnicity
logistic sevinfect i.health_shift covidage sex imd bmi cancer i.smoking comorb if eth2==1
logistic sevinfect i.health_shift covidage sex imd bmi cancer i.smoking comorb if eth2==2
logistic sevinfect i.health_shift covidage sex imd bmi cancer i.smoking comorb if eth2==3

*sensitivity analyses *stratified by retirement age in UK =66)
logistic sevinfect i.health_shift covidage imd bmi cancer i.smoking i.eth2 comorb if covidage2<=65
logistic sevinfect i.health_shift covidage imd bmi cancer i.smoking i.eth2 comorb if covidage2>65

*sensitivity analsyes additionally controlling for self-reported sleep duration

*logistic reg final models
logistic sevinfect i.health_shift covidage sex imd bmi cancer i.smoking i.eth2 comorb sleep_dur

*stratify by sex
logistic sevinfect i.health_shift covidage imd bmi cancer i.smoking i.eth2 comorb sleep_dur if sex==0
logistic sevinfect i.health_shift covidage imd bmi cancer i.smoking i.eth2 comorb sleep_dur if sex==1

*stratify by ethnicity
logistic sevinfect i.health_shift covidage sex imd bmi cancer i.smoking comorb sleep_dur if eth2==1
logistic sevinfect i.health_shift covidage sex imd bmi cancer i.smoking comorb sleep_dur if eth2==2
logistic sevinfect i.health_shift covidage sex imd bmi cancer i.smoking comorb sleep_dur if eth2==3


