/*=============================================================================* 
* ANALYSIS - Models (Continuously observed workers)
*==============================================================================*
 	Project: Temporary Employment and Wage Inequality over the Life Course
	Author: Christoph Janietz, University of Amsterdam
	Last update: 29-07-2023
* ---------------------------------------------------------------------------- *

	INDEX: 
		0.  Settings
		1.  Declare Panel Data
		2.  Risk estimation
		3.  Vulnerability estimation
		4.  Decomposition of change in wage gap
		5.  Close log file
		
* --------------------------------------------------------------------------- */
* 0. SETTINGS 
* ---------------------------------------------------------------------------- * 

*** Settings - run config file
	global dir 			"H:/Christoph/art2"
	do 					"${dir}/06_dofiles/config"
	
*** Open log file
	log using 			"${logfiles}/03_analysis_models.log", replace
	
	
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
	
	* Identify workers with temporary employment in 2006
	gen tag = 0
	replace tag = 1 if temp_tminus1==1 & age==0
	bys id: egen id_tag = max(tag)
	* Add +1 to workers with temp in 2006
	replace te_cum = te_cum+1 if id_tag==1
	drop tag id_tag
	*Create squared version
	gen te_cum_sqr = (te_cum*te_cum)
	
	///
	* Keep only complete careers
	keep if N == 13
	///
	
	
	*Create Dummy indicator of time since Temporary Employment
	sort id age
	
	foreach x of num 1/12 {
		gen te_`x' = 0
		by id: replace te_`x' = 1 if temp_tminus1[_n-`x']==1
	}
	*
	foreach x of num 12/1 {
		local y = `x'+ 1
		rename te_`x' te_`y'
	}
	*
	
	*Create dummy that groups together 5+ years after temp
	gen te_5plus = 0
	replace te_5plus = 1 if (te_5==1 | te_6==1 | te_7==1 | te_8==1 | te_9==1 | ///
		te_10==1 | te_11==1 | te_12==1 | te_13==1)
	
* --------------------------------------------------------------------------- */
* 2. RISK ESTIMATION
* ---------------------------------------------------------------------------- *

	*Pooled logit model  (state-probability analysis)
	logit cntrct_lngth_hours ib1.edtc##ib2007.YEAR ib1.gender##ib0.migback [iw=wgt]
	
	*Retrieving Predicted Probabilities
	margins edtc, at(YEAR=(2007(1)2019)) asobserved
	matrix risk = r(table)
	
	// Saving estimated margins
	putexcel set "${tables}/margins/margins_risk_allempl", sheet("RISK") replace
	putexcel A1 = matrix(risk), names
	
	// Saving model estimates
	esttab using "${tables}/models/risk_logit_allempl.csv", ///
		replace se r2 ar2 nobaselevels 
	est clear
	
	// --> Figure 4: Predicted temporary employment probabilities by education
	

* --------------------------------------------------------------------------- */
* 3. VULNERABILITY ESTIMATION
* ---------------------------------------------------------------------------- *
	
	****************************************************************************
	* FIXED EFFECT INDIVIDUAL SLOPES (FEIS) REGRESSION
	****************************************************************************
	
	/*Test for Necessity of FEIS
	tab YEAR, gen(y)
	tab lmevents, gen(l)
	
	foreach ed of num 1/3 {
		* (Causal) effect of Temporary employment 
		xtfeis log_real_hwage cntrct_lngth y1-y13 if edtc==`ed', ///
			slope(age age_sqr) cluster(id)
		xtart
		* (Causal) effect of Temporary employment over time
		xtfeis log_real_hwage cntrct_lngth temp_tminus1 te_2-te_4 ///
			te_5plus y1-y13 if edtc==`ed', slope(age age_sqr) cluster(id)
		xtart
		* (Causal) effect of Temporary employment & STAY / SWITCH
		xtfeis log_real_hwage l2 l3 l4 y1-y13 if edtc==`ed', ///
			slope(age age_sqr) cluster(id)
		xtart
	}
	*
	drop y1-l4
	
	// Compare whether improvement over FE model (xtart)
	// --> Yes, continue with FEIS */
	
	
	* Implementing models
	foreach ed of num 1/3 {
		* (Causal) effect of Temporary employment 
		eststo: reghdfe log_real_hwage_rbst i.cntrct_lngth_hours i.industry i.sector ///
			i.ed_diff i.YEAR if edtc==`ed' [aw=wgt], absorb(id##c.(age age_sqr)) vce(cluster id)
		* (Causal) effect of Temporary employment & STAY / SWITCH
		eststo: reghdfe log_real_hwage_rbst i.lmevents_detail i.industry i.sector ///
			i.ed_diff i.YEAR if edtc==`ed' [aw=wgt], absorb(id##c.(age age_sqr)) vce(cluster id)
	}
	*
			
	// Saving model estimates
	esttab using "${tables}/models/vuln_feis_allempl.csv", ///
		replace se r2 ar2 nobaselevels 

	est clear
	
	
	// --> Figure 4: Marginal effect of Temp on Wages
	
	// --> Figure 5: Marginal effect of Temp (t-1) & Switch / Stay on Wages
	
	
* --------------------------------------------------------------------------- */
* 4. DECOMPOSITION OF CHANGE IN WAGE GAP
* ---------------------------------------------------------------------------- *
	
	/* Estimate the growth curve models with reghdfe
	* Issue: xtoaxaca doesn't work with reghdfe (components do not sum up to 
	* the correct delta_y)
	* Solution: Estimate the GC models and retrieve the relevant statistics individually.
	
	* Baseline model
	reghdfe log_real_hwage ib1.edtc##i.age i.industry i.sector, ///
		absorb(id##c.(age age_sqr)) vce(cluster id)
	est store base_feis
	* CONTEMPORARY MODELS
	reghdfe log_real_hwage ib1.edtc##i.cntrct_lngth_hours##i.age ///
		i.industry i.sector, absorb(id##c.(age age_sqr)) vce(cluster id)
	est store temp_feis
	* CUMULATIVE MODEL
	// Model adds a cumulated temporary employment years (+ squared) as a predictor. 
	// Effect is constrained to be time-constant as variable value range induces 
	// variation in the size of the point estimate.
	reghdfe log_real_hwage ib1.edtc##i.cntrct_lngth_hours##i.age ///
		ib1.edtc##c.te_cum ib1.edtc##c.te_cum_sqr i.industry i.sector, ///
		absorb(id##c.(age age_sqr)) vce(cluster id) 
	est store cum_feis */
	
	foreach ed of num 1/3 {
		* Baseline model
		reghdfe log_real_hwage_rbst i.age i.industry i.sector i.ed_diff  ///
			if edtc==`ed' [aw=wgt], absorb(id##c.(age age_sqr)) vce(cluster id)
		est store base_feis_`ed'
		* CONTEMPORARY MODELS
		reghdfe log_real_hwage_rbst i.cntrct_lngth_hours##i.age i.industry i.sector ///
			i.ed_diff if edtc==`ed' [aw=wgt], absorb(id##c.(age age_sqr)) vce(cluster id)
		est store temp_feis_`ed'
		* CUMULATIVE MODEL
		// Model adds a cumulated temporary employment years (+ squared) as a predictor. 
		// Effect is constrained to be time-constant as variable value range induces 
		// variation in the size of the point estimate.
		reghdfe log_real_hwage_rbst i.cntrct_lngth_hours##i.age ///
			c.te_cum c.te_cum_sqr i.industry i.sector i.ed_diff ///
			if edtc==`ed' [aw=wgt], absorb(id##c.(age age_sqr)) vce(cluster id)
		est store cum_feis_`ed'
	}
	*
	
	// Produce Model Table
	esttab base_feis_1 base_feis_2 base_feis_3 ///
		temp_feis_1 temp_feis_2 temp_feis_3 ///
		cum_feis_1 cum_feis_2 cum_feis_3 ///
		using "${tables}/models/gc_feis_allempl.csv", ///
		se nobaselevels nomtitles replace
	
	****************************************************************************
	* RETRIEVE DECOMPOSITION STATISTICS
	****************************************************************************
	
foreach type in temp cum {
	putexcel set "${tables}/decomposition/decomposition_`type'_allempl", sheet("decomposition") replace
	putexcel A1 = "edtc" B1 = "age" C1 = "Y" D1 = "x_temp" E1 = "x_te_cum" ///
		F1 = "x_te_cum_sqr" G1 = "b_temp" H1 = "b_te_cum" I1 = "b_te_cum_sqr" 
	
	* Average Wages over time by education group (Y)
	local row = 2
	foreach ed of num 1/3 {
		foreach age of num 0/12 {
			sum log_real_hwage_rbst if age==`age' & edtc==`ed' [aw=wgt]
			putexcel A`row' = `ed'
			putexcel B`row' = `age'
			putexcel C`row' = `r(mean)'
			local ++row
		}
	}
	*
	* Sample means over time by education group (X)
	local row = 2
	foreach ed of num 1/3 {
		foreach age of num 0/12 {
			sum cntrct_lngth_hours if age==`age' & edtc==`ed' [aw=wgt]
			putexcel D`row' = `r(mean)'
			sum te_cum if age==`age' & edtc==`ed' [aw=wgt]
			putexcel E`row' = `r(mean)'
			sum te_cum_sqr if age==`age' & edtc==`ed' [aw=wgt]
			putexcel F`row' = `r(mean)'
			local ++row
		}
	}
	*
	* Predicted effects (b)
	local row = 2
	foreach ed of num 1/3 {
		foreach age of num 0/12 {
			est restore `type'_feis_`ed'
			local b_temp = _b[1.cntrct_lngth_hours]+_b[1.cntrct_lngth_hours#`age'.age]
			putexcel G`row' = `b_temp'
			capture local b_te_cum = _b[te_cum]
			capture putexcel H`row' = `b_te_cum'
			capture local b_te_cum_sqr = _b[te_cum_sqr]
			capture putexcel I`row' = `b_te_cum_sqr'
			local ++row
		}
	}
}
*
	
	****************************************************************************
	* DECOMPOSITION
	****************************************************************************
	
	**********************
	// Contemporary effect
	**********************
	preserve
	
	// Load data
	import excel "H:\Christoph\art2\04_tables\decomposition\decomposition_temp_allempl.xlsx", ///
		sheet("decomposition") firstrow clear
	
	* Drop ISCED 3-4
	drop if edtc==2
	
	* Drop cumulative variables 
	drop x_te_cum x_te_cum_sqr b_te_cum b_te_cum_sqr
	
	*Reshape to wide format
	reshape wide Y x_temp b_temp , i(age) j(edtc)
		
	*Rename variables
	rename (Y1 x_temp1 b_temp1 Y3 x_temp3 b_temp3) ///
		(Y_L x_temp_L b_temp_L Y_H x_temp_H b_temp_H)
		
	*Create variables holding baseline value
	foreach var of var Y_L-b_temp_H {
		gen `var'_s = `var' if age==0
		replace `var'_s = `var'_s[_n-1] if age!=0
	}
	*	
	* Derive Delta_Y (OUTCOME)
	order Y_H, after(Y_L)
	foreach ed in L H {
		gen delta_Y_`ed' = Y_`ed' - Y_`ed'_s
		replace delta_Y_`ed' = 0 if age==0
		order delta_Y_`ed', after(Y_`ed')
	}
	*
	gen delta_Y = delta_Y_H-delta_Y_L
	order delta_Y, after(delta_Y_H)
	
	* Derive Deltas R / V I (RISK, VULNERABILITY, INTERACTION
	foreach var in temp {
	    gen delta_R = ///
			((x_`var'_H-x_`var'_H_s)*b_`var'_H_s)-((x_`var'_L-x_`var'_L_s)*b_`var'_L_s)
		replace delta_R=. if age==0
		gen delta_V = ///
			(x_`var'_H_s*(b_`var'_H-b_`var'_H_s))-(x_`var'_L_s*(b_`var'_L-b_`var'_L_s))
		replace delta_V=. if age==0
		gen delta_I = ///
			((x_`var'_H-x_`var'_H_s)*(b_`var'_H-b_`var'_H_s))- ///
			((x_`var'_L-x_`var'_L_s)*(b_`var'_L-b_`var'_L_s))
		replace delta_I=. if age==0
	}
	*
	
	* Cleanup
	drop Y_L_s-b_temp_H_s
	
	* Calculate Relative Percentage Share per Component
	foreach comp in R V I {
		gen `comp' = (delta_`comp'/delta_Y)*100
	}
	*
	* Estimate total contribution
	gen T = delta_R+delta_V+delta_I
	gen TOTAL = R+V+I
	
	* Re-center age variable
	replace age = age+28
	
	* Save estimates
	save "${tables}/decomposition/decomposition_temp_allempl.dta", replace
	
	export excel using "H:\Christoph\art2\04_tables\decomposition\decomposition_temp_allempl.xlsx", ///
		sheet("final") firstrow(variables) replace
	
	restore
	
	********************
	// CUMULATIVE EFFECT
	********************
	preserve
	
	// Load data
	import excel "H:\Christoph\art2\04_tables\decomposition\decomposition_cum_allempl.xlsx", ///
		sheet("decomposition") firstrow clear
	
	* Drop ISCED 3-4
	drop if edtc==2
	
	*Reshape to wide format
	reshape wide Y x_temp x_te_cum x_te_cum_sqr ///
		b_temp b_te_cum b_te_cum_sqr, i(age) j(edtc)
		
	*Rename variables
	rename (Y1 x_temp1 x_te_cum1 x_te_cum_sqr1 b_temp1 b_te_cum1 b_te_cum_sqr1 ///
		Y3 x_temp3 x_te_cum3 x_te_cum_sqr3 b_temp3 b_te_cum3 b_te_cum_sqr3) ///
		(Y_L x_temp_L x_te_cum_L x_te_cum_sqr_L b_temp_L b_te_cum_L b_te_cum_sqr_L ///
		Y_H x_temp_H x_te_cum_H x_te_cum_sqr_H b_temp_H b_te_cum_H b_te_cum_sqr_H)
		
	*Create variables holding baseline value
	foreach var of var Y_L-b_te_cum_sqr_H {
		gen `var'_s = `var' if age==0
		replace `var'_s = `var'_s[_n-1] if age!=0
	}
	*	
	* Derive Delta_Y (OUTCOME)
	order Y_H, after(Y_L)
	foreach ed in L H {
		gen delta_Y_`ed' = Y_`ed' - Y_`ed'_s
		replace delta_Y_`ed' = 0 if age==0
		order delta_Y_`ed', after(Y_`ed')
	}
	*
	gen delta_Y = delta_Y_H-delta_Y_L
	order delta_Y, after(delta_Y_H)
	
	* Derive Deltas R / V I (RISK, VULNERABILITY, INTERACTION
	foreach var in temp te_cum te_cum_sqr {
	    gen delta_R_`var' = ///
			((x_`var'_H-x_`var'_H_s)*b_`var'_H_s)-((x_`var'_L-x_`var'_L_s)*b_`var'_L_s)
		replace delta_R_`var'=. if age==0
		gen delta_V_`var' = ///
			(x_`var'_H_s*(b_`var'_H-b_`var'_H_s))-(x_`var'_L_s*(b_`var'_L-b_`var'_L_s))
		replace delta_V_`var'=. if age==0
		gen delta_I_`var' = ///
			((x_`var'_H-x_`var'_H_s)*(b_`var'_H-b_`var'_H_s))- ///
			((x_`var'_L-x_`var'_L_s)*(b_`var'_L-b_`var'_L_s))
		replace delta_I_`var'=. if age==0
	}
	*
	
	* Combine into one Variable Block
	gen delta_R = delta_R_temp + delta_R_te_cum + delta_R_te_cum_sqr
	gen delta_V = delta_V_temp + delta_V_te_cum + delta_V_te_cum_sqr
	gen delta_I = delta_I_temp + delta_I_te_cum + delta_I_te_cum_sqr
	
	* Cleanup
	drop Y_L_s-delta_I_te_cum_sqr
	
	* Calculate Relative Percentage Share per Component
	foreach comp in R V I {
		gen `comp' = (delta_`comp'/delta_Y)*100
	}
	*
	* Estimate total contribution
	gen T = delta_R+delta_V+delta_I
	gen TOTAL = R+V+I
	
	* Re-center age variable
	replace age = age+28
	
	* Save estimates
	save "${tables}/decomposition/decomposition_cum_allempl.dta", replace
	
	export excel using "H:\Christoph\art2\04_tables\decomposition\decomposition_cum_allempl.xlsx", ///
		sheet("final") firstrow(variables) replace
	
	restore
	
	// --> Table 3: Decomposition results
	
	est clear
		
* --------------------------------------------------------------------------- */
* 5. CLOSE LOG FILE
* ---------------------------------------------------------------------------- *

	log close
	