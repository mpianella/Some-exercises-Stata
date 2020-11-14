*********************************************************************************************************************************************************
*********************************************************************************************************************************************************
*This program is my solution to the Data Manipulation Task (Task 2)
*
*dataset used: scp-1205.csv
*
*output: county-level dataset that identifies the number of plans and total enrollment in each county as specified in Medicare Advantage Instruction.pdf
*
*author: Matteo Pianella
*
*date: October 2020
*********************************************************************************************************************************************************
*********************************************************************************************************************************************************
cap log close 
log using ./log/me_medicare_manipulation.log, replace
clear 

import delimited "C:\Users\Matteo\Desktop\RESEARCH_POSITIONS\Sample_task\Medicare_Advantage\scp-1205.csv", clear

cd C:\Users\Matteo\Desktop\RESEARCH_POSITIONS\Sample_task\me_sample_task_solution\me_medicare_advantage

*rename and label the variables in the .csv file with the info in Medicare Advantage Instruction.pdf
rename v1 countyname
rename v2 state
rename v3 healthplanname
rename v4 healthplanname_description
rename v5 typeofplan
rename v6 countyssa
rename v7 eligibles
rename v8 enrollees
rename v9 penetration
rename v10 ABrate

label variable countyname "name of the county"
label variable state "state postal code"
label variable typeofplan "type of healh plan"
label variable healthplanname "name of the health plan"
label variable healthplanname_description "name of the health plan"
label variable countyssa "Social Security Administration county code"
label variable eligibles "number of individuals in the county that are Medicare eligible"
label variable enrollees "number of individuals enrolled in the specific health plan"
label variable penetration "percent of individuals in the county enrolled in the plan, defined as 100 X"
label variable ABrate "Medicare's monthly payments to the health plan"

*destring variables eligibles enrollees and penetration and substitute missing values with zeros as asked in Medicare Advantage Instruction.pdf
foreach v of varlist eligibles enrollees penetration{
destring `v', replace
replace `v'=0 if `v'==.
}

*A) generate the variable typeofplan1 and typeofplan2

*A1) gen a variable typeofplan_1 that has value 1 if enrollees>10 and 0 otherwise 
by countyname healthplanname, sort: gen typeofplan_1=1 if enrollees>10 
replace typeofplan_1=0 if typeofplan_1==.

*A2) gen a variable typeofplan_2 that has value 1 if penetration>0.5 and 0 otherwise
by countyname healthplanname, sort: gen typeofplan_2=1 if penetration>.5
replace typeofplan_2=0 if typeofplan_2==.

*A3) 
foreach v of varlist typeofplan_1 typeofplan_2 {
sort countyname healthplanname `v'
quietly by countyname healthplanname `v': gen dup =cond(_N==1, 0, _n -1) // To avoid that some of the health plans that respect that two previous conditions (enrollees>10 and penetration>0.5) would be counted twice, I use cond() to create dup that has value 0 if countyname healthplanname and `v' uniquely identify the obs and when it is the first obs not identified by the three variables 
by countyname: egen `v'_ = total(`v') if dup==0 // variable `v' is the sum of all the *different* health plans that respect the conditions for each county
drop `v' dup
}

by countyname: egen typeofplan1 = max(typeofplan_1_)  // since max() ignores missing values, the following associates a single value for each county 
by countyname: egen typeofplan2 = max(typeofplan_2_)

label variable typeofplan1 "number of health plans with more than 10 enrollees"
label variable typeofplan2 "number of health plans with penetration>0.5"

*B) gen variables totalenrolees and totalpenetration

collapse (sum) enrollees, by(countyname state countyssa eligibles typeofplan1 typeofplan2) // N.B: the variables countyname, state, countyssa, eligibles and typeofplan1 typeofplan2 do not change by countyname

rename enrollees totalenrolees

label variable totalenrolees "number of individuals in the county with an MA health plan"

gen totalpenetration=(totalenrolees/eligible)*100
label variable totalpenetration "100 X totalenrolees/eligibles"

sort state countyname 

* drop county name "UNDER-11" and "Unusual SCounty Code"
drop in 1/57 

save me_sol_sampletask, replace

log close 
