/*=============================================================================* 
* ANALYSIS - Descriptives (Continuously employed workers)
*==============================================================================*
 	Project: Temporary Employment and Wage Inequality over the Life Course
	Author: Christoph Janietz, University of Amsterdam
	Last update: 29-07-2023
* ---------------------------------------------------------------------------- *

	INDEX: 
		0.  Settings 
		1. 	Declare Panel Data
		2.  Descriptives - Sample with continuously employed workers
		3.  Close log file
		
		
* --------------------------------------------------------------------------- */
* 0. SETTINGS 
* ---------------------------------------------------------------------------- * 

*** Settings - run config file
	global dir 			"H:/Christoph/art2"
	do 					"${dir}/06_dofiles/config"
	
*** Open log file
	log using 			"$logfiles/02_analysis_descriptives.log", replace
	

	
	use "${posted}/chrt79_ana.dta", replace
	
* --------------------------------------------------------------------------- */
* 1. DECLARE PANEL DATA
* ---------------------------------------------------------------------------- * 

	egen id = group(RIN)

	sort id YEAR
	
	* Set longitudinal data
	xtset id age
	
	* Drop 2006
	drop if age<0
	
	* Indicator of realized person years (2007-2019)
	bys id: gen N = _N
	
	* Cumulative indicator (2007-2019)
	* Total number of years in temporary employment
	bys id: egen te_tot = total(cntrct_lngth_hours)
	* Cumulative number of years in temporary employment
	bys id: gen te_cum = sum(cntrct_lngth_hours)
	
	* Identify workers with temp in 2006
	gen tag = 0
	replace tag = 1 if temp_tminus1==1 & age==0
	bys id: egen id_tag = max(tag)
	* Add +1 to workers with temp in 2006
	replace te_cum = te_cum+1 if id_tag==1
	drop tag id_tag
	*Create squared version
	gen te_cum_sqr = (te_cum*te_cum)
	
	// DESCRIPTIVES - Table of education switchers
	egen tag = tag(RIN)
	putexcel set "${tables}/descr/descr_edu", sheet("Edu Switchers") modify
	putexcel A1 = ("Min Ed") B1 = ("Low") C1 = ("Middle") D1 = ("High")
	tab ed_min ed_max if tag==1, matrow(rows) matcell(cells)
	putexcel A2 = matrix(rows) B2 = matrix(cells)
	drop tag
	
	// DESCRIPTIVES - Observed pys by education
	egen pers = tag(id)
	putexcel set "${tables}/descr/descr_py", sheet("py") replace
	putexcel A1 = ("py") B1 = ("ISCED 1-2") C1 = ("ISCED 3-4") D1 = ("ISCED 5-8")
	tab N edtc if pers==1, matrow(rows) matcell(cells)
	putexcel A2 = matrix(rows) B2 = matrix(cells)
	
	*--> Table Appendix
	
	///
	* Keep if continiuously observed employment career
	keep if N==13
	///
	
	// DESCRIPTIVES - Sample size allempl
	putexcel set "${tables}/descr/descr_n", sheet("n") modify
	tab YEAR, matcell(cells)
	putexcel B3 = matrix(cells)
	
	save "${posted}/chrt79_ana_allempl.dta", replace

	
* --------------------------------------------------------------------------- */
* 2. DESCRIPTIVES - SAMPLE WITH CONTINUOUSLY EMPLOYED WORKERS
* ---------------------------------------------------------------------------- * 

	
	****************************************************************************
	// DESCRIPTIVE STATISTICS 
	****************************************************************************
	
	* Descriptives full sample
	preserve
	tab edtc, gen(edtc)
	tab gender, gen(g)
	tab migback, gen(m)
	tab lmevents_detail, gen(l)
	collapse (mean) wage=real_hwage_rbst ft_equi=ft_factor ///
		low=edtc1 mid=edtc2 high=edtc3 ///
		men=g1 women=g2 nomig=m1 fsrt=m2 scnd=m3 ///
		temp=cntrct_lngth_hours temp_t1=temp_tminus1 te_cum=te_cum ///
		p_stay_p=l1 p_stay_t=l2 p_jm_p=l3 p_jm_t=l4 t_stay_p=l5 t_stay_t=l6 ///
		t_jm_p=l7 t_tjm_t=l8 ///
		(sd) sd_wage=real_hwage_rbst sd_ft_equi=ft_factor ///
		sd_low=edtc1 sd_mid=edtc2 sd_high=edtc3 ///
		sd_men=g1 sd_women=g2 sd_nomig=m1 sd_fsrt=m2 sd_scnd=m3 ///
		sd_temp=cntrct_lngth_hours sd_temp_t1=temp_tminus1 sd_te_cum=te_cum ///
		sd_p_stay_p=l1 sd_p_stay_t=l2 sd_p_jm_p=l3 sd_p_jm_t=l4 ///
		sd_t_stay_p=l5 sd_t_stay_t=l6 sd_t_jm_p=l7 sd_t_tjm_t=l8 [aw=wgt], by(YEAR)
	save "${posted}/descr_all_allempl.dta", replace
	restore
	
	* Descriptives by education
	preserve
	tab gender, gen(g)
	tab migback, gen(m)
	tab lmevents_detail, gen(l)
	collapse (mean) wage=real_hwage_rbst ft_equi=ft_factor ///
		men=g1 women=g2 nomig=m1 fsrt=m2 scnd=m3 ///
		temp=cntrct_lngth_hours temp_t1=temp_tminus1 te_cum=te_cum ///
		p_stay_p=l1 p_stay_t=l2 p_jm_p=l3 p_jm_t=l4 t_stay_p=l5 t_stay_t=l6 ///
		t_jm_p=l7 t_tjm_t=l8 ///
		(sd) sd_wage=real_hwage_rbst sd_ft_equi=ft_factor ///
		sd_men=g1 sd_women=g2 sd_nomig=m1 sd_fsrt=m2 sd_scnd=m3 ///
		sd_temp=cntrct_lngth_hours sd_temp_t1=temp_tminus1 sd_te_cum=te_cum ///
		sd_p_stay_p=l1 sd_p_stay_t=l2 sd_p_jm_p=l3 sd_p_jm_t=l4 ///
		sd_t_stay_p=l5 sd_t_stay_t=l6 sd_t_jm_p=l7 sd_t_tjm_t=l8 [aw=wgt], by(YEAR edtc) 
	save "${posted}/descr_bygrp_allempl.dta", replace
	restore
	
	* Descriptives by education & temporary employment
	preserve
	tab gender, gen(g)
	tab migback, gen(m)
	tab lmevents_detail, gen(l)
	collapse (mean) wage=real_hwage_rbst ft_equi=ft_factor ///
		men=g1 women=g2 nomig=m1 fsrt=m2 scnd=m3 ///
		p_stay_p=l1 p_stay_t=l2 p_jm_p=l3 p_jm_t=l4 t_stay_p=l5 t_stay_t=l6 ///
		t_jm_p=l7 t_tjm_t=l8 ///
		(sd) sd_wage=real_hwage_rbst sd_ft_equi=ft_factor ///
		sd_men=g1 sd_women=g2 sd_nomig=m1 sd_fsrt=m2 sd_scnd=m3 ///
		sd_p_stay_p=l1 sd_p_stay_t=l2 sd_p_jm_p=l3 sd_p_jm_t=l4 ///
		sd_t_stay_p=l5 sd_t_stay_t=l6 sd_t_jm_p=l7 sd_t_tjm_t=l8 [aw=wgt], ///
		by(edtc cntrct_lngth_hours) 
	save "${posted}/descr_bytemp_allempl.dta", replace
	restore
	
	* Investigate % of always and never treated
	bys id: egen te = sum(cntrct_lngth_hours)
	tab te edtc if pers==1 [aw=wgt], col
	* --> Shares are in rows 0 and 13
	
	sort id age
	drop te pers


	****************************************************************************
	//Figure 1 - Average Wages over time by education group
	****************************************************************************
	
	preserve
	collapse (mean) avg_wage=real_hwage_rbst ///
		(semean) se=real_hwage_rbst [aw=wgt], by(YEAR edtc)
	gen ci_up = avg_wage+(1.96*se)
	gen ci_low = avg_wage-(1.96*se)
	
	lab def isced_lbl 1 "ISCED 1-2" 2 "ISCED 3-4" 3 "ISCED 5-8"
	lab val edtc isced_lbl
	
	save "${posted}/descr_avg_wages_allempl.dta", replace
	restore
	
	****************************************************************************
	//Figure 2 - Ridgeplot
	****************************************************************************
	
	* Uses complete wage data ("${posted}/chrt79_ana.dta") in R to compute 
	* ridgelineplots.
	
	****************************************************************************
	//Within Person change (not used in final manuscript)
	****************************************************************************
	
	preserve
	keep YEAR RIN edtc wgt real_hwage_rbst
	keep if YEAR==2007 | YEAR==2019
	
	reshape wide real_hwage_rbst wgt, i(RIN) j(YEAR)
	
	gen chng = real_hwage_rbst2019-real_hwage_rbst2007
	
	save "${posted}/descr_indv_chng_allempl.dta", replace
	restore
	
* --------------------------------------------------------------------------- */
* 3. CLOSE LOG FILE
* ---------------------------------------------------------------------------- *

	log close
	