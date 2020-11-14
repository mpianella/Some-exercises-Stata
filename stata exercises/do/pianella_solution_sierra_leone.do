********************************************************************************
********************************************************************************
*This program contains the solution to "Data Cleaning Sierra Leone"

*Author: Matteo Pianella

********************************************************************************
********************************************************************************

cap log close
clear
log using .\log\pianella_solution_sierra_leone.log, text replace

*first task: Survey design reconciliation

use .\dta\hh_nr_round1.dta, clear

split crop_l 

forvalues i=1/7 {
generate cropl_`i' = 1 if crop_l1=="`i'" | crop_l2=="`i'" | crop_l3=="`i'" | crop_l4=="`i'" | crop_l5=="`i'" | crop_l6=="`i'" | crop_l7=="`i'"
replace cropl_`i'=0 if cropl_`i'==.
} //generate dummy that assumes value 1 if a particular crop is cultivated and 0 if it is not. Treated -111 as 0

drop crop_l crop_l1 crop_l2 crop_l3 crop_l4 crop_l5 crop_l6 crop_l7

save .\dta\modified_hh_nr_round1.dta, replace

use .\dta\hh_round1.dta, clear


append using ".\dta\modified_hh_nr_round1.dta"
drop cropl_9
replace cropl_7=0 if cropl_7==.
label variable cropl_7 "Sorghum grown in any plot"
move cropl_7 div_mon

save .\dta\final_hh_round1.dta, replace

*second task: String matching 

use .\dta\hh_round1_cand.dta, clear

preserve
sort village first_choice_cand
by village first_choice_cand: egen first_choice_count = count(first_choice_cand) // generate a variable that counts for each candidate and for each village the number of people that voted him/her as their first choice
collapse (mean) first_choice_count, by(village first_choice_cand)
rename first_choice_cand candidate

save .\dta\first_choice_count.dta, replace
restore

sort village second_choice_cand
by village second_choice_cand: egen second_choice_count = count(second_choice_cand) 
collapse (mean) second_choice_count, by (village second_choice_cand)
rename second_choice_cand candidate

merge 1:1 village  candidate using "C:\Users\Matteo\Desktop\RESEARCH_POSITIONS\from_Daniel\Helemo\pianella_solution\dta\first_choice_count.dta"

replace first_choice_count= 0 if first_choice_count==.
replace second_choice_count=0 if second_choice_count==.

bysort village: generate final_count = first_choice_count + second_choice_count
bysort village: egen cand_rank=rank(final_count), field
replace cand_rank=2 if cand_rank==1 & cand_rank[_n]==cand_rank[_n+1] //I assume that the ranking is calculated by counting the total - first choice plus second choice - number of votes. I break ties using first choices.  
sort village cand_rank first_choice_count
drop if cand_rank>2

generate party = substr(candidate, strpos(candidate, "(") + 1, strpos(candidate, ")") - strpos(candidate, "(") - 1)
bysort party: gen party_seats = _N

save .\dta\final_cand_choice.dta, replace

log close