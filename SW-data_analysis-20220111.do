**Signature Work
**Coder: Xinyue Chen
**Date: 20210804
/**Purpose: 
1) 1FU dataset cleaning
2) merge BL and 1FU dataset
*/

clear
cd D:\DKU\CEBA\CEBA_Dataset-selected
use CEBA_BL+1FU_data-20210804
browse

cd D:\DKU\sig_work\SW-Data\Output

tab PHQ_2019 
tab PHQ_2020 if PHQ_2019 == .
tab PHQ_2020

*********************** Housekeeping *****************************

duplicates report RES_ID
tab RES_ID

*PHQ_CAT PHQ
drop StartDate_2019-UserLanguage_2019
drop StartDate_2020-UserLanguage_2020

browse
gen community = int(RES_ID/1000)
gen city = int(community/100)
gen town = int(community/10)


*Diabetes: 1 "Yes" 2 "No" 5 "Don't know"(5 -> 3 for 2021)
*Hypertension: 1 "Yes" 2 "No" 3 "Don't know"
*规则：含有1的都为1（includes 12 21 13 31），不含1的都为2
egen dia = concat(HLTH_DIA_1_2019 HLTH_DIA_1_2020)
egen htn = concat(HLTH_HTN_1_2019 HLTH_HTN_1_2020)
tab dia
tab htn

replace dia = "1" if strmatch(dia,"*1*")
replace dia = "2" if !strmatch(dia,"*1*")

replace htn = "1" if strmatch(htn,"*1*")
replace htn = "2" if !strmatch(htn,"*1*")


destring dia htn, replace
tab dia htn
drop if dia == 2 & htn == 2
tab dia htn

gen ncd_2019 = 0
gen ncd_2020 = 0

label define ncd_lbl 1 "Hypertension" 2 "Diabetes" 3 "Both"

forvalues y = 2019/2020{
	replace ncd_`y' = 1 if htn == 1 & dia == 2 
	replace ncd_`y' = 2 if htn == 2 & dia == 1 
	replace ncd_`y' = 3 if htn == 1 & dia == 1 
	label value ncd_`y' ncd_lbl
	label variable ncd_`y' "NCD"
}

 


*********************** Dependent Variable: PHQ-9 *****************************

/*gen PHQ_CAT = ""
replace PHQ_CAT = "Minimal depression" if PHQ <= 4
replace PHQ_CAT = "Mild depression" if PHQ > 4 & PHQ <=9
replace PHQ_CAT = "Moderate depression" if PHQ > 9 & PHQ <=14
replace PHQ_CAT = "Moderately severe depression" if PHQ > 14 & PHQ <=19
replace PHQ_CAT = "Severe depression" if PHQ > 19
*/
*drop depressed_2019 depressed_2020


forvalues y = 2019/2020{
	gen depressed_`y' = .
	replace depressed_`y' = 1 if PHQ_`y' >= 8 & PHQ_`y' < . 
	replace depressed_`y' = 0 if PHQ_`y' < 8
	tab depressed_`y'
}
tab depressed_2019 depressed_2020


gen incidence_2020 = depressed_2019 if depressed_2019 < 1
replace incidence_2020 = 1 if depressed_2019 == 0 & depressed_2020 == 1
replace incidence_2020 = . if depressed_2019 ==1
replace incidence_2020 = . if depressed_2020 ==. 
tab incidence_2020



*********************** Independent Variables *****************************

*********************** Individual level: Demographics *****************************
gen age_2019 = 2019 - DEMO_YEAR
gen age_2020 = age_2019 + 1
forvalues y = 2019/2020{
egen age_cat_`y' = cut(age_`y'), at(35,60,70,90)
recode age_cat_`y' 35=0 60=1 70=2
label define agegroup 0 "<60" 1 "60-69" 2 "≥70", replace
label value age_cat_`y' agegroup
label variable age_cat_`y' "Age"
}
sum age_cat_2019

gen gender = DEMO_GENDER_2019
replace gender = DEMO_GENDER_2020 if gender == .
label define gender_lbl 1 "Male" 2 "Female", replace
label value gender gender_lbl
label variable gender "Sex"

replace edu = "0" if edu == "Illiterate" 
replace edu = "1" if edu == "Primary school" 
replace edu = "2" if edu == "Secondary school" 
replace edu = "3" if edu == "High school or above"
destring edu, replace
label define edu_lbl 0 "Illiterate" 1 "Primary school" 2 "Secondary school" 3 "High school or above", replace
label value edu edu_lbl
label variable edu "Education"

forvalues y = 2019/2020{
replace incm_`y' = "1" if incm_`y' == "< 5000 RMB" 
replace incm_`y' = "2" if incm_`y' == "5000~10000 RMB" 
replace incm_`y' = "3" if incm_`y' == "> 10000 RMB"
destring incm_`y', replace
label define incm_lbl 1 "< 5000 RMB" 2 "5000-10000 RMB" 3 "> 10000 RMB", replace
label value incm_`y' incm_lbl
label variable incm_`y' "Monthly household income"

replace mari_`y' = "0" if mari_`y' == "Others" 
replace mari_`y' = "1" if mari_`y' == "Married"
destring mari_`y', replace
label define mari_lbl 0 "Others" 1 "Married", replace
label value mari_`y' mari_lbl
label variable mari_`y' "Marital Status"

replace job_`y' = "1" if job_`y' == "Blue-collar workers" 
replace job_`y' = "2" if job_`y' == "White-collar workers" 
replace job_`y' = "3" if job_`y' == "Retired blue collar workers"
replace job_`y' = "4" if job_`y' == "Retired white-collar workers" 
replace job_`y' = "5" if job_`y' == "Others" 
destring job_`y', replace
label define job_lbl 1 "Blue-collar workers" 2 "White-collar workers" 3 "Retired blue-collar workers" 4 "Retired white-collar workers" 5 "Others", replace 
label value job_`y' job_lbl
label variable job_`y' "Occupation"
}

*********************** Individual level: Lifestyle *****************************

forvalue y = 2019/2020{
	gen LS_IPAQ_`y' = LS_`y' +IPAQ_`y' 
}


*********************** Family level: APGAR  *****************************
forvalues y = 2019/2020{
    foreach Q of varlist FAM_1_`y'-FAM_5_`y'{
	    destring `Q', replace
		replace `Q' = 4 - `Q'
	}
}

label define fam_lbl 2 "Always" 1 "Sometimes" 0 "Hardly ever",modify
label value FAM_1_2019-FAM_5_2019 FAM_1_2020-FAM_5_2020 fam_lbl

forvalues y = 2019/2020{
    egen FAM_APGAR_`y' = rowtotal(FAM_1_`y'-FAM_5_`y')
	egen FAM_APGAR_CAT_`y' = cut(FAM_APGAR_`y'), at(0,4,6,10)
	recode FAM_APGAR_CAT_`y' 0=0 4=1 6=2
	cap label define famfunc 0 "0-3: severely dysfunctional family" 1 "4-6: moderately dysfunctional family" 2 "7-10: highly functional family"
	label value FAM_APGAR_CAT_`y' famfunc
}

*ref: https://cdn.mdedge.com/files/s3fs-public/jfp-archived-issues/1978-volume_6-7/JFP_1978-06_v6_i6_the-family-apgar-a-proposal-for-a-family.pdf

*********************** Community level: COEN *****************************

forvalues y = 2019/2020{
label var COEN_1_NOIZ_`y' "Noise"
label var COEN_1_AIR_`y' "Air quality"
label var COEN_1_CLN_`y' "Cleaness"
label var COEN_1_LHT_`y' "Light pollution"
label var COEN_1_SAF_1_`y' "Road safety"
label var COEN_1_SAF_2_`y' "Daily safety"
label var COEN_1_SCU_`y' "Security"
label var COEN_1_VIO_`y' "Violence"
label var COEN_1_FLCLT_`y' "Public facilities"
label var COEN_1_TRAF_`y' "Public tranportation"
label var COEN_1_OVERALL_`y' "Overall experience"


label var COEN_2_SMK_1_`y' "Tobacco accessibility"
label var COEN_2_SMK_2_`y' "Smoking regulation"
label var COEN_2_SMK_3_`y' "Smoking prevalence" 
label var COEN_2_SMK_4_`y' "Second-hand smoking"
label var COEN_2_ALCH_1_`y' "Alcohol accessibility"
label var COEN_2_ALCH_2_`y' "Drinking prevalence"
label var COEN_2_PA_1_`y' "Physical activity facilities"
label var COEN_2_PA_2_`y' "Resident physical activity"
label var COEN_2_PA_3_`y' "Activity togetherness"
label var COEN_2_FSAF_1_`y' "Food safety"
label var COEN_2_FSAF_2_`y' "Veggies & fruits accessibility"
label var COEN_2_HLKNW_`y' "Health knowledge level"
label var COEN_2_HLBLF_`y' "Motivation to be healthier"
label var COEN_2_HLHBT_`y' "Health habits"
label var COEN_2_HLSK_`y' "Health literacy"

label var COEN_3_MEN_`y' "Mental health"
label var COEN_3_HAP_`y' "Happiness"
label var COEN_3_RESC_`y' "Mental supports"
label var COEN_3_FAMI_`y' "Acquaintanceship"
label var COEN_3_COMM_`y' "Communication"
label var COEN_3_FRID_`y' "Friend number"
label var COEN_3_TRU_`y' "Trust level"
label var COEN_3_AST_`y' "Mutual assistance"
label var COEN_3_SUPR_`y' "Mutual mental supports"
label var COEN_3_SHAR_`y' "Sharing info"


label var COEN_4_HLEDU_`y' "Health edu"
label var COEN_4_SRV_`y' "NCD services"
label var COEN_4_HLSTAF_`y' "Number of medical staffs"
label var COEN_4_HLSRV_`y' "PHC service quality"
label var COEN_4_MED_`y' "Number of medicine & equipments"
label var COEN_4_CVN_`y' "PHC accessibility"
label var COEN_4_PRC_`y' "PHC Price"
label var COEN_4_ACCPT_`y' "PHC acceptance"
label var COEN_4_ENG_`y' "NCD autonomy"

label var COEN_5_SUG_`y' "Emphasis on resident suggestions"
capture drop COEN_5_DCS_`y'
label var COEN_5_INVL_`y' "Resident admin engagement"
label var COEN_5_RESORG_1_`y' "Abundance of resident organization"
capture drop COEN_5_RESORG_2_`y'-COEN_5_RESORG_6_HL_`y'
label var COEN_5_RESORG_7_`y' "Res org participation"
label var COEN_5_RESORG_8_`y' "Outcome of res org"
label var COEN_5_SOLORG_1_`y' "Abundance of social organization"
label var COEN_5_SOLORG_2_`y' "Outcome of social org"
label var COEN_5_COMORG_1_`y' "Community Activity"
capture drop COEN_5_COMORG_2_`y'-COEN_5_COMORG_6_`y'
label var COEN_5_COMORG_7_`y' "Community activity participation"
label var COEN_5_COMORG_8_`y' "Community activity admin"
label var COEN_5_COMORG_9_`y' "Outcome of community activity"
}




*********************** Description *****************************
*********************** Table 1: Demographics *****************************
forvalues y = 2019/2020{
table1,vars(age_cat_`y' cat \gender cat  \edu cat \mari_`y' cat\job_`y' cat\incm_`y' cat\ncd_`y' cat\FAM_APGAR_CAT_`y' cat) format(%8.3f) pdp(2) saving(SW_table1_`y'.xlsx, replace)
}


*********************** Analysis *****************************

*********************** Prevelance *****************************
forvalues y = 2019/2020{
    logistic depressed_`y' i.age_cat_`y' i.gender i.edu i.incm_`y' i.mari_`y' i.job_`y' ib3.ncd_`y' 
	logistic depressed_`y' ib3.PHM_SRQ_`y' /*add adjustment, serve as ref*/
	logistic depressed_`y' ib3.PHM_SRH_C_`y' 
	logistic depressed_`y' ib3.PHM_SRH_L_`y'
	logistic depressed_`y' LS_`y' /*reference, coding refinement*/
	logistic depressed_`y' IPAQ_`y' /*To-do: cat*/
	logistic depressed_`y' BMI_`y' //*Individual*/

	logistic depressed_`y'  ib3.FAM_APGAR_CAT_`y' 
	foreach fam of varlist FAM_1_`y'-FAM_5_`y'{ 
	    logistic depressed_`y'  i.`fam' /*Family*/
	}  
	
	logistic depressed_`y'  COEN_t_`y'
	foreach com of varlist COEN_1_`y'-COEN_5_`y'{ 
	    logistic depressed_`y'  `com' /*Community*/
	}  
}

*********************** Incidence *****************************
forvalues y = 2019/2020{
    logistic incidence_2020 i.age_cat_`y' i.gender i.edu i.incm_`y' i.mari_`y' i.job_`y' ib3.ncd_`y' 
	logistic incidence_2020 ib3.PHM_SRQ_`y' 
	logistic incidence_2020 ib3.PHM_SRH_C_`y' 
	logistic incidence_2020 ib3.PHM_SRH_L_`y' 
	logistic incidence_2020 LS_`y' 
	logistic incidence_2020 IPAQ_`y' 
	logistic incidence_2020 LS_IPAQ_`y' 
	logistic incidence_2020 BMI_`y' /*Individual*/
	
	logistic incidence_2020 ib3.FAM_APGAR_CAT_`y' 
	foreach fam of varlist FAM_1_`y'-FAM_5_`y'{ 
	    logistic incidence_2020 i.`fam' /*Family*/
	}  
	
	logistic incidence_2020 COEN_t_`y'
	foreach com of varlist COEN_1_`y'-COEN_5_`y'{ 
	    logistic incidence_2020 `com' /*Community*/
	} 
}



