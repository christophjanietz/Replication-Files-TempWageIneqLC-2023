/*=============================================================================* 
* ANALYSIS - Robustness (Continuously employed workers)
*==============================================================================*
 	Project: Temporary Employment and Wage Inequality over the Life Course
	Author: Christoph Janietz, University of Amsterdam
	Last update: 21-04-2023
* ---------------------------------------------------------------------------- *

	INDEX: 
		0.  Settings
		1.  Declare Panel Data
		2.  Robustnesss analyses
		
* --------------------------------------------------------------------------- */
* 0. SETTINGS 
* ---------------------------------------------------------------------------- * 

*** Settings - run config file
	global dir 			"H:/Christoph/art2"
	do 					"${dir}/06_dofiles/config"
	
*** Open log file
	log using 			"${logfiles}/04_analysis_robustness.log", replace
	
	
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
* 2. ROBUSTNESS ANALYSES
* ---------------------------------------------------------------------------- * 
	
	
	**********************************************
	// A) Without education weight (time-constant)
	**********************************************
	
	// Model without education weights
		foreach ed of num 1/3 {
		* CUMULATIVE MODEL
		reghdfe log_real_hwage_rbst i.cntrct_lngth_hours##i.age ///
			c.te_cum c.te_cum_sqr i.industry i.sector i.ed_diff ///
			if edtc==`ed', absorb(id##c.(age age_sqr)) vce(cluster id)
		est store cum_feis_`ed'_ROBUST_A
	}
	*
	
	// RETRIEVE DECOMPOSITION STATISTICS
	foreach type in cum {
	putexcel set "${tables}/robustness/decomposition_`type'_ROBUST_A", sheet("decomposition") replace
	putexcel A1 = "edtc" B1 = "age" C1 = "Y" D1 = "x_temp" E1 = "x_te_cum" ///
		F1 = "x_te_cum_sqr" G1 = "b_temp" H1 = "b_te_cum" I1 = "b_te_cum_sqr" 
	
	* Average Wages over time by education group (Y)
	local row = 2
	foreach ed of num 1/3 {
		foreach age of num 0/12 {
			sum log_real_hwage_rbst if age==`age' & edtc==`ed' 
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
			sum cntrct_lngth_hours if age==`age' & edtc==`ed'
			putexcel D`row' = `r(mean)'
			sum te_cum if age==`age' & edtc==`ed'
			putexcel E`row' = `r(mean)'
			sum te_cum_sqr if age==`age' & edtc==`ed'
			putexcel F`row' = `r(mean)'
			local ++row
		}
	}
	*
	* Predicted effects (b)
	local row = 2
	foreach ed of num 1/3 {
		foreach age of num 0/12 {
			est restore `type'_feis_`ed'_ROBUST_A
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

	// DECOMPOSITION
	preserve
	
	// Load data
	import excel "H:\Christoph\art2\04_tables\robustness\decomposition_cum_ROBUST_A.xlsx", ///
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
	save "${tables}/robustness/decomposition_cum_ROBUST_A.dta", replace
	
	export excel using "H:\Christoph\art2\04_tables\robustness\decomposition_cum_ROBUST_A.xlsx", ///
		sheet("final") firstrow(variables) replace
	
	restore
	
	est clear
	
	
	***************************************
	// B) Joblessness (R2.5a)
	***************************************
	
	// Model with joblessness control
		foreach ed of num 1/3 {
		* CUMULATIVE MODEL
		reghdfe log_real_hwage_rbst i.cntrct_lngth_hours##i.age ///
			c.te_cum c.te_cum_sqr i.industry i.sector i.ed_diff i.jobless ///
			if edtc==`ed' [aw=wgt], absorb(id##c.(age age_sqr)) vce(cluster id)
		est store cum_feis_`ed'_ROBUST_B
	}
	*
	
	// RETRIEVE DECOMPOSITION STATISTICS
	foreach type in cum {
	putexcel set "${tables}/robustness/decomposition_`type'_ROBUST_B", sheet("decomposition") replace
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
			est restore `type'_feis_`ed'_ROBUST_B
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

	// DECOMPOSITION
	preserve
	
	// Load data
	import excel "H:\Christoph\art2\04_tables\robustness\decomposition_cum_ROBUST_B.xlsx", ///
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
	save "${tables}/robustness/decomposition_cum_ROBUST_B.dta", replace
	
	export excel using "H:\Christoph\art2\04_tables\robustness\decomposition_cum_ROBUST_B.xlsx", ///
		sheet("final") firstrow(variables) replace
	
	restore
	
	est clear
	
	
	***************************************
	// C) Simultaneouos job holding (R2.5c)
	***************************************
	
	recode parallel_jobs (0=0) (1/20=1), gen(parallel_jobs_model)
	
	// Model with parallel job control
	foreach ed of num 1/3 {
		* CUMULATIVE MODEL
		reghdfe log_real_hwage_rbst i.cntrct_lngth_hours##i.age ///
			c.te_cum c.te_cum_sqr i.industry i.sector i.ed_diff i.parallel_jobs_model ///
			if edtc==`ed' [aw=wgt], absorb(id##c.(age age_sqr)) vce(cluster id)
		est store cum_feis_`ed'_ROBUST_C
	}
	*
	
	// RETRIEVE DECOMPOSITION STATISTICS
	foreach type in cum {
	putexcel set "${tables}/robustness/decomposition_`type'_ROBUST_C", sheet("decomposition") replace
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
			est restore `type'_feis_`ed'_ROBUST_C
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

	// DECOMPOSITION
	preserve
	
	// Load data
	import excel "H:\Christoph\art2\04_tables\robustness\decomposition_cum_ROBUST_C.xlsx", ///
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
	save "${tables}/robustness/decomposition_cum_ROBUST_C.dta", replace
	
	export excel using "H:\Christoph\art2\04_tables\robustness\decomposition_cum_ROBUST_C.xlsx", ///
		sheet("final") firstrow(variables) replace
	
	restore
	
	est clear
	
	
	***************************************
	// D) Original wage measure
	***************************************
	
	// Model with alternative wage measure
	foreach ed of num 1/3 {
		* CUMULATIVE MODEL
		reghdfe log_real_hwage i.cntrct_lngth_hours##i.age ///
			c.te_cum c.te_cum_sqr i.industry i.sector i.ed_diff ///
			if edtc==`ed' [aw=wgt], absorb(id##c.(age age_sqr)) vce(cluster id)
		est store cum_feis_`ed'_ROBUST_D
	}
	*
	
	// RETRIEVE DECOMPOSITION STATISTICS
	foreach type in cum {
	putexcel set "${tables}/robustness/decomposition_`type'_ROBUST_D", sheet("decomposition") replace
	putexcel A1 = "edtc" B1 = "age" C1 = "Y" D1 = "x_temp" E1 = "x_te_cum" ///
		F1 = "x_te_cum_sqr" G1 = "b_temp" H1 = "b_te_cum" I1 = "b_te_cum_sqr" 
	
	* Average Wages over time by education group (Y)
	local row = 2
	foreach ed of num 1/3 {
		foreach age of num 0/12 {
			sum log_real_hwage if age==`age' & edtc==`ed' [aw=wgt]
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
			est restore `type'_feis_`ed'_ROBUST_D
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

	// DECOMPOSITION
	preserve
	
	// Load data
	import excel "H:\Christoph\art2\04_tables\robustness\decomposition_cum_ROBUST_D.xlsx", ///
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
	save "${tables}/robustness/decomposition_cum_ROBUST_D.dta", replace
	
	export excel using "H:\Christoph\art2\04_tables\robustness\decomposition_cum_ROBUST_D.xlsx", ///
		sheet("final") firstrow(variables) replace
	
	restore
	
	est clear
	
	
	
	***************************************
	// E) Mid vs. High (R2.7b)
	***************************************
	
	// Model as in main analysis
	foreach ed of num 1/3 {
		* CUMULATIVE MODEL
		reghdfe log_real_hwage_rbst i.cntrct_lngth_hours##i.age ///
			c.te_cum c.te_cum_sqr i.industry i.sector i.ed_diff ///
			if edtc==`ed' [aw=wgt], absorb(id##c.(age age_sqr)) vce(cluster id)
		est store cum_feis_`ed'_ROBUST_E
	}
	*
	
	// RETRIEVE DECOMPOSITION STATISTICS
	foreach type in cum {
	putexcel set "${tables}/robustness/decomposition_`type'_ROBUST_E", sheet("decomposition") replace
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
			est restore `type'_feis_`ed'_ROBUST_E
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

	// DECOMPOSITION
	preserve
	
	// Load data
	import excel "H:\Christoph\art2\04_tables\robustness\decomposition_cum_ROBUST_E.xlsx", ///
		sheet("decomposition") firstrow clear
	
	* Drop ISCED 1-2
	drop if edtc==1
	
	*Reshape to wide format
	reshape wide Y x_temp x_te_cum x_te_cum_sqr ///
		b_temp b_te_cum b_te_cum_sqr, i(age) j(edtc)
		
	*Rename variables
	rename (Y2 x_temp2 x_te_cum2 x_te_cum_sqr2 b_temp2 b_te_cum2 b_te_cum_sqr2 ///
		Y3 x_temp3 x_te_cum3 x_te_cum_sqr3 b_temp3 b_te_cum3 b_te_cum_sqr3) ///
		(Y_M x_temp_M x_te_cum_M x_te_cum_sqr_M b_temp_M b_te_cum_M b_te_cum_sqr_M ///
		Y_H x_temp_H x_te_cum_H x_te_cum_sqr_H b_temp_H b_te_cum_H b_te_cum_sqr_H)
		
	*Create variables holding baseline value
	foreach var of var Y_M-b_te_cum_sqr_H {
		gen `var'_s = `var' if age==0
		replace `var'_s = `var'_s[_n-1] if age!=0
	}
	*	
	* Derive Delta_Y (OUTCOME)
	order Y_H, after(Y_M)
	foreach ed in M H {
		gen delta_Y_`ed' = Y_`ed' - Y_`ed'_s
		replace delta_Y_`ed' = 0 if age==0
		order delta_Y_`ed', after(Y_`ed')
	}
	*
	gen delta_Y = delta_Y_H-delta_Y_M
	order delta_Y, after(delta_Y_H)
	
	* Derive Deltas R / V I (RISK, VULNERABILITY, INTERACTION
	foreach var in temp te_cum te_cum_sqr {
	    gen delta_R_`var' = ///
			((x_`var'_H-x_`var'_H_s)*b_`var'_H_s)-((x_`var'_M-x_`var'_M_s)*b_`var'_M_s)
		replace delta_R_`var'=. if age==0
		gen delta_V_`var' = ///
			(x_`var'_H_s*(b_`var'_H-b_`var'_H_s))-(x_`var'_M_s*(b_`var'_M-b_`var'_M_s))
		replace delta_V_`var'=. if age==0
		gen delta_I_`var' = ///
			((x_`var'_H-x_`var'_H_s)*(b_`var'_H-b_`var'_H_s))- ///
			((x_`var'_M-x_`var'_M_s)*(b_`var'_M-b_`var'_M_s))
		replace delta_I_`var'=. if age==0
	}
	*
	
	* Combine into one Variable Block
	gen delta_R = delta_R_temp + delta_R_te_cum + delta_R_te_cum_sqr
	gen delta_V = delta_V_temp + delta_V_te_cum + delta_V_te_cum_sqr
	gen delta_I = delta_I_temp + delta_I_te_cum + delta_I_te_cum_sqr
	
	* Cleanup
	drop Y_M_s-delta_I_te_cum_sqr
	
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
	save "${tables}/robustness/decomposition_cum_ROBUST_E.dta", replace
	
	export excel using "H:\Christoph\art2\04_tables\robustness\decomposition_cum_ROBUST_E.xlsx", ///
		sheet("final") firstrow(variables) replace
	
	restore
	
	est clear
	
	
	******************************************************
	// F) Alternative wage masure including parallel jobs
	******************************************************
	
	// Model with alternative wage measure (+ parallel jobs)
	foreach ed of num 1/3 {
		* CUMULATIVE MODEL
		reghdfe log_real_hwage_parallel i.cntrct_lngth_hours##i.age ///
			c.te_cum c.te_cum_sqr i.industry i.sector i.ed_diff ///
			if edtc==`ed' [aw=wgt], absorb(id##c.(age age_sqr)) vce(cluster id)
		est store cum_feis_`ed'_ROBUST_F
	}
	*
	
	// RETRIEVE DECOMPOSITION STATISTICS
	foreach type in cum {
	putexcel set "${tables}/robustness/decomposition_`type'_ROBUST_F", sheet("decomposition") replace
	putexcel A1 = "edtc" B1 = "age" C1 = "Y" D1 = "x_temp" E1 = "x_te_cum" ///
		F1 = "x_te_cum_sqr" G1 = "b_temp" H1 = "b_te_cum" I1 = "b_te_cum_sqr" 
	
	* Average Wages over time by education group (Y)
	local row = 2
	foreach ed of num 1/3 {
		foreach age of num 0/12 {
			sum log_real_hwage_parallel if age==`age' & edtc==`ed' [aw=wgt]
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
			est restore `type'_feis_`ed'_ROBUST_F
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

	// DECOMPOSITION
	preserve
	
	// Load data
	import excel "H:\Christoph\art2\04_tables\robustness\decomposition_cum_ROBUST_F.xlsx", ///
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
	save "${tables}/robustness/decomposition_cum_ROBUST_F.dta", replace
	
	export excel using "H:\Christoph\art2\04_tables\robustness\decomposition_cum_ROBUST_F.xlsx", ///
		sheet("final") firstrow(variables) replace
	
	restore
	
	est clear
