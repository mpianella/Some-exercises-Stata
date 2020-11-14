*********************************************************************************************************************
*********************************************************************************************************************
*This program contains the solution to some of the questions in the word document "pianella_project2" that I sent you
*
*dataset used: grade5.dta
*
*author: Matteo Pianella
*
*date: October 2020
*********************************************************************************************************************
*********************************************************************************************************************

cap log close 
clear 
log using ./log/project2.log, text replace

use "./dta/grade5.dta", clear


* solution to question 4
ssc install binscatter, replace

*4a)
binscatter classize school_enrollment if inrange(school_enrollment, 20, 60), rd(40.5) discrete line(qfit) // This draws binned scatter plot with size of the class on the y-axis and number of people enrolled in the school on the x-axis. A quadratic regression line fits better the data.
graph export ./png/classize_schoolenrollment.png, replace

*4b) 
binscatter avgmath school_enrollment if inrange(school_enrollment, 20, 60), rd(40.5) discrete line(lfit) savegraph(./gph/avgmath.gph) replace //binned scatter plot with average score in the math test on the y-axis and the number of people enrolled in the school on the x-axis.  
binscatter avgverb school_enrollment if inrange(school_enrollment, 20, 60), rd(40.5) discrete line(lfit) savegraph(./gph/avgverb.gph) replace // the same for the verbal test
graph combine ./gph/avgmath.gph ./gph/avgverb.gph
graph export ./png/avgmath_verb_schoolenrollment.png, replace

*4c)
binscatter disadvantaged school_enrollment if inrange(school_enrollment, 20, 60), rd(40.5) discrete line(qfit) savegraph(./gph/disadvantaged.gph) replace // binned scatter plot with the percentage of disadvantages students on the y-axis and number of people enrolled in the school on the x-axis

binscatter religious school_enrollment if inrange(school_enrollment, 20, 60), rd(40.5) discrete line(lfit) savegraph(./gph/religious.gph) replace //binned scatter plot with the fraction of religious schools on the y-axis and number of people enrolled in the school on the x-axis

binscatter female school_enrollment if inrange(school_enrollment, 20, 60), rd(40.5) discrete line(lfit) savegraph(./gph/female.gph) replace //binned scatter plot with the fraction of female students on the y-axis and number of people enrolled in the school on the x-axis

graph combine ./gph/disadvantaged.gph ./gph/religious.gph ./gph/female.gph
graph export ./png/disadvantaged_religious_female_enrollment.png, replace

*4d)

preserve

collapse (mean) school_enrollment, by(schlcode) // collapse the dataset to the mean school enrollement for each school

twoway (histogram school_enrollment if inrange(school_enrollment,20,60), discrete frequency), xline(40.5) // show  the frequency enrollements 
graph export ./png/school_distribution.png, replace

restore 

*5)
* this generates an indicator variable for school_enrollment being above 40
gen above40 = 0 
replace above40 = 1 if school_enrollment>40

*this generates a variable with value school_enrollment - 40
gen x = school_enrollment - 40

*this generates the interaction term between the previous two vbs
gen x_above40 = x*above40

*we run a regression clustering by schools. We do this because the residuals may not be independent within each school.
foreach v of varlist classize avgmath avgverb {
reg `v' above40 x x_above40 if inrange(school_enrollment, 0, 80), cluster(schlcode)
}

log close 