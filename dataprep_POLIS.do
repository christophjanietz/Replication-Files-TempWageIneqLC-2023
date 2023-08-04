/*=============================================================================* 
* DATA PREPARATIONS - Polis
*==============================================================================*
 	Project: Temporary Employment and Wage Inequality over the Life Course
	Author: Christoph Janietz, University of Amsterdam
	Last update: 21-04-2023
* ---------------------------------------------------------------------------- *

	INDEX: 
		0.  Settings 
		1. 	Prepare (S)POLIS
		2.  Identification of yearly main jobs
		3.  Preparation of variables and pooling
		4.  Pooled dataset
		5.  Finalize sample
		6.  Close log file
		
	SHORT DESCRIPTION:
		This dofile prepares the dataset for analyses. (S)Polis data from 2006 to 
		2020 is combined to form a panel of yearly main jobs of workers in the 
		Netherlands who were born in 1979 (27 years old in 2006).
	
* --------------------------------------------------------------------------- */
* 0. SETTINGS 
* ---------------------------------------------------------------------------- * 

*** Settings - run config file
	global dir 			"H:/Christoph/art2"
	do 					"${dir}/06_dofiles/config"
	
*** Open log file
	log using 			"$logfiles/01_polis.log", replace

* --------------------------------------------------------------------------- */
* 1. PREPARE (S)POLIS 
* ---------------------------------------------------------------------------- *

*** Set the sample identifiers (27 years old in 2006)
	use "${GBAPERSOON2009}", replace
	gen birthy = real(gbageboortejaar)
	gen agein2006 = 2006-birthy
	keep if agein2006==27
	keep rinpersoons rinpersoon
	sort rinpersoons rinpersoon
	
	save "${data}/sample_RIN_2009.dta", replace
	
	use "${GBAPERSOON2020}", replace
	gen birthy = real(gbageboortejaar)
	gen agein2006 = 2006-birthy
	keep if agein2006==27
	keep rinpersoons rinpersoon
	sort rinpersoons rinpersoon
	
	save "${data}/sample_RIN_2020.dta", replace
	
******************************************************************
*** Aggregate at BEID-Level
******************************************************************

*** 2006-2009: POLIS
	foreach year of num 2006/2009 {
		use rinpersoons rinpersoon baanrugid aanvbus eindbus baandagen basisloon ///
			basisuren bijzonderebeloning lnowrk overwerkuren voltijddagen ///
			contractsoort polisdienstverband beid caosector aanvbus eindbus ///
			datumaanvangikv datumeindeikv soortbaan ///
			using "${polis`year'}", replace
		
		*Reduce dataset to individuals in sample
		sort rinpersoons rinpersoon
		merge m:1 rinpersoons rinpersoon using "${data}/sample_RIN_2009.dta"
		keep if _merge==3
		drop _merge
		
		*Harmonize variable names
		foreach var of var baandagen basisloon basisuren bijzonderebeloning ///
			lnowrk overwerkuren voltijddagen contractsoort polisdienstverband ///
			beid caosector aanvbus eindbus datumaanvangikv datumeindeikv soortbaan {
			rename `var' s`var' 
		}
		
		*Prepare date indicators
		gen job_start_exact = date(saanvbus, "YMD")
		gen job_end_exact = date(seindbus, "YMD")
		gen job_start_caly = date(sdatumaanvangikv, "YMD")
		gen job_end_caly = date(sdatumeindeikv, "YMD")
		format job_start_exact job_end_exact job_start_caly job_end_caly %d
		drop saanvbus seindbus sdatumaanvangikv sdatumeindeikv
		
		* Contract duration
		gen cntrct = 0
		replace cntrct = 1 if scontractsoort=="B"
		replace cntrct = 1 if scontractsoort=="b"
		drop scontractsoort
		rename cntrct scontractsoort
		
		lab var scontractsoort "soort contract"
		lab def cntrct_lbl 0 "Permanent" 1 "Temporary"
		lab val scontractsoort cntrct_lbl
		
		* Full-time / Part-time
		gen dienstverband = real(spolisdienstverband)
		drop spolisdienstverband 
		bys rinpersoons rinpersoon sbeid: egen spolisdienstverband = min(dienstverband)
		drop dienstverband
		
		lab var spolisdienstverband "dienstverband"
		lab def dnst_lbl 1 "Full-time" 2 "Part-time"
		lab val spolisdienstverband dnst_lbl
		
		* Job type
		gen soortbaan = real(ssoortbaan)
		drop ssoortbaan
		recode soortbaan (1 = 10)
		bys rinpersoons rinpersoon sbeid: egen ssoortbaan = max(soortbaan)
		drop soortbaan
		
		lab var ssoortbaan "soort baan"
		lab def srt_lbl 2 "Stagiare" 3 "WSW-er" 4 "Uitzendkracht" ///
			5 "Oproepkracht" 9 "Rest" 10 "Directeur / Grot Aandeelhouder"
		lab val ssoortbaan srt_lbl
		
		
		************************************************************************
		*JOB Summary statistics for whole calendar year within BEID (all obs per unique job ID)
		************************************************************************
		
		/// Earnings & hours (by soortcontract)
		foreach var of var sbasisloon sbasisuren {
			bys rinpersoons rinpersoon sbeid scontractsoort: ///
				egen `var'_caly_beid_CONTRACT = total(`var')
		}
		*
		bys rinpersoons rinpersoon sbeid: egen loon_TEMP = ///
			max(sbasisloon_caly_beid_CONTRACT) if scontractsoort==1
		bys rinpersoons rinpersoon sbeid: egen uren_TEMP = ///
			max(sbasisuren_caly_beid_CONTRACT) if scontractsoort==1
		bys rinpersoons rinpersoon sbeid: egen loon_PERM = ///
			max(sbasisloon_caly_beid_CONTRACT) if scontractsoort==0
		bys rinpersoons rinpersoon sbeid: egen uren_PERM = ///
			max(sbasisuren_caly_beid_CONTRACT) if scontractsoort==0
			
		bys rinpersoons rinpersoon sbeid: egen sbasisloon_caly_beid_TEMP = ///
			max(loon_TEMP)
		bys rinpersoons rinpersoon sbeid: egen sbasisuren_caly_beid_TEMP = ///
			max(uren_TEMP)
		bys rinpersoons rinpersoon sbeid: egen sbasisloon_caly_beid_PERM = ///
			max(loon_PERM)
		bys rinpersoons rinpersoon sbeid: egen sbasisuren_caly_beid_PERM = ///
			max(uren_PERM)
		
		foreach var of var sbasisloon_caly_beid_TEMP-sbasisuren_caly_beid_PERM {
			replace `var' = 0 if `var'==.
		}
		* 
		drop sbasisloon_caly_beid_CONTRACT-uren_PERM
		
		/// Indicator: more hours Temp or Perm within BEID
		gen TorP = sbasisuren_caly_beid_PERM-sbasisuren_caly_beid_TEMP
		lab var TorP "Relative hours Temp vs. Perm (>0: more hours as perm)"
		
		
		/// All Earnings & hours
		foreach var of var sbaandagen-svoltijddagen {
			bys rinpersoons rinpersoon sbeid: egen `var'_caly_beid = total(`var')
		}
		*
		order sbaandagen_caly_beid-svoltijddagen_caly_beid, after(svoltijddagen)
		order sbasisloon_caly_beid_TEMP- TorP, after(svoltijddagen_caly_beid)
		drop sbaandagen-svoltijddagen
		
		
		************************************************************************
		// Temporary Contract Indicator (2 versions)
		************************************************************************
		
		// a. Dominance Criterium
		bys rinpersoons rinpersoon sbeid: egen temp = min(scontractsoort)
		drop scontractsoort
		rename temp scontractsoort
		
		lab var scontractsoort "soort contract"
		lab val scontractsoort cntrct_lbl
		
		// b. Relative number of hours criterium
		gen scontractsoort_hours = 0 if TorP>=0 & TorP!=.
		replace scontractsoort_hours = 1 if TorP<0 & TorP!=.
		
		// Recode some missclassified cases due to 0 base hours (later missing)
		replace scontractsoort_hours=1 if scontractsoort==1 & scontractsoort_hours==0
		
		lab var scontractsoort_hours "soort contract (hours based)"
		lab val scontractsoort_hours cntrct_lbl
		drop TorP

		************************************************************************
		*JOB Summary statistics for whole calendar year within BEID (all obs per unique job ID)
		************************************************************************

		*Select only one exact observation per job ID to reduce file-size
		gen rndm = runiform()
		sort rinpersoons rinpersoon sbeid rndm

		egen select = tag(rinpersoons rinpersoon sbeid)
		keep if select==1
		drop select rndm job_start_exact job_end_exact
		
		*Create full-time-factor on job-level
		gen ft_factor = svoltijddagen_caly_beid / sbaandagen_caly_beid
		
		sort rinpersoons rinpersoon sbeid
		
		
		************************************************************************
		*Merge additional variables
		************************************************************************
		
		*Merge GKSBS from BETAB
		rename sbeid beid
		merge m:1 beid using "${betab`year'}", keepusing (gksbs) ///
			keep(master match) nogen
		rename beid sbeid
		
		sort rinpersoons rinpersoon

		*Merge Geslacht / Migratieachtergrond / Geboortejaar
		merge m:1 rinpersoons rinpersoon using "${GBAPERSOON2009}", ///
			keepusing(gbageslacht gbageneratie gbageboortejaar gbageboortemaand) ///
			nogen keep(match master)
	
		*Merge Hoogste Opleiding
		merge m:1 rinpersoons rinpersoon using "${hoogsteopl`year'}", ///
			keepusing(oplnrhb oplnrhg gewichthoogsteopl) ///
			nogen keep(match master)
	
		save "${data}/fullpolis_`year'.dta", replace
	}
	*
	
*** 2010-2012: SPOLIS
	foreach year of num 2010/2012 {
		use RINPERSOONS RINPERSOON IKVID SDATUMAANVANGIKO SDATUMEINDEIKO ///
			SBAANDAGEN SBASISLOON SBASISUREN SBIJZONDEREBELONING SLNOWRK ///
			SOVERWERKUREN SVOLTIJDDAGEN SCONTRACTSOORT SPOLISDIENSTVERBAND ///
			SBEID SCAOSECTOR SDATUMAANVANGIKV SDATUMEINDEIKV SSOORTBAAN ///
			using "${spolis`year'}", replace
			
		rename RINPERSOONS-SSOORTBAAN, lower
			
		*Reduce dataset to individuals in sample
		sort rinpersoons rinpersoon
		merge m:1 rinpersoons rinpersoon using "${data}/sample_RIN_2020.dta"
		keep if _merge==3
		drop _merge
		
		*Prepare date indicators
		gen job_start_exact = date(sdatumaanvangiko, "YMD")
		gen job_end_exact = date(sdatumeindeiko, "YMD")
		gen job_start_caly = date(sdatumaanvangikv, "YMD")
		gen job_end_caly = date(sdatumeindeikv, "YMD")
		format job_start_exact job_end_exact job_start_caly job_end_caly %d
		drop sdatumaanvangiko sdatumeindeiko sdatumaanvangikv sdatumeindeikv
	
		* Contract duration
		gen cntrct = 0
		replace cntrct = 1 if scontractsoort=="B"
		replace cntrct = 1 if scontractsoort=="b"
		drop scontractsoort
		rename cntrct scontractsoort
		
		lab var scontractsoort "soort contract"
		lab def cntrct_lbl 0 "Permanent" 1 "Temporary"
		lab val scontractsoort cntrct_lbl
		
		* Full-time / Part-time
		gen dienstverband = real(spolisdienstverband)
		drop spolisdienstverband 
		bys rinpersoons rinpersoon sbeid: egen spolisdienstverband = min(dienstverband)
		drop dienstverband
		
		lab var spolisdienstverband "dienstverband"
		lab def dnst_lbl 1 "Full-time" 2 "Part-time"
		lab val spolisdienstverband dnst_lbl
		
		* Job type
		gen soortbaan = real(ssoortbaan)
		drop ssoortbaan
		recode soortbaan (1 = 10)
		bys rinpersoons rinpersoon sbeid: egen ssoortbaan = max(soortbaan)
		drop soortbaan
		
		lab var ssoortbaan "soort baan"
		lab def srt_lbl 2 "Stagiare" 3 "WSW-er" 4 "Uitzendkracht" ///
			5 "Oproepkracht" 9 "Rest" 10 "Directeur / Grot Aandeelhouder"
		lab val ssoortbaan srt_lbl
		
		
		************************************************************************
		*JOB Summary statistics for whole calendar year within BEID (all obs per unique job ID)
		************************************************************************
		
		/// Earnings & hours (by soortcontract)
		foreach var of var sbasisloon sbasisuren {
			bys rinpersoons rinpersoon sbeid scontractsoort: ///
				egen `var'_caly_beid_CONTRACT = total(`var')
		}
		*
		bys rinpersoons rinpersoon sbeid: egen loon_TEMP = ///
			max(sbasisloon_caly_beid_CONTRACT) if scontractsoort==1
		bys rinpersoons rinpersoon sbeid: egen uren_TEMP = ///
			max(sbasisuren_caly_beid_CONTRACT) if scontractsoort==1
		bys rinpersoons rinpersoon sbeid: egen loon_PERM = ///
			max(sbasisloon_caly_beid_CONTRACT) if scontractsoort==0
		bys rinpersoons rinpersoon sbeid: egen uren_PERM = ///
			max(sbasisuren_caly_beid_CONTRACT) if scontractsoort==0
			
		bys rinpersoons rinpersoon sbeid: egen sbasisloon_caly_beid_TEMP = ///
			max(loon_TEMP)
		bys rinpersoons rinpersoon sbeid: egen sbasisuren_caly_beid_TEMP = ///
			max(uren_TEMP)
		bys rinpersoons rinpersoon sbeid: egen sbasisloon_caly_beid_PERM = ///
			max(loon_PERM)
		bys rinpersoons rinpersoon sbeid: egen sbasisuren_caly_beid_PERM = ///
			max(uren_PERM)
		
		foreach var of var sbasisloon_caly_beid_TEMP-sbasisuren_caly_beid_PERM {
			replace `var' = 0 if `var'==.
		}
		* 
		drop sbasisloon_caly_beid_CONTRACT-uren_PERM
		
		/// Indicator: more hours Temp or Perm within BEID
		gen TorP = sbasisuren_caly_beid_PERM-sbasisuren_caly_beid_TEMP
		lab var TorP "Relative hours Temp vs. Perm (>0: more hours as perm)"
		
		
		/// All Earnings & hours
		foreach var of var sbaandagen-svoltijddagen {
			bys rinpersoons rinpersoon sbeid: egen `var'_caly_beid = total(`var')
		}
		*
		order sbaandagen_caly_beid-svoltijddagen_caly_beid, after(svoltijddagen)
		order sbasisloon_caly_beid_TEMP- TorP, after(svoltijddagen_caly_beid)
		drop sbaandagen-svoltijddagen
		
		
		************************************************************************
		// Temporary Contract Indicator (2 versions)
		************************************************************************
		
		// a. Dominance Criterium
		bys rinpersoons rinpersoon sbeid: egen temp = min(scontractsoort)
		drop scontractsoort
		rename temp scontractsoort
		
		lab var scontractsoort "soort contract"
		lab val scontractsoort cntrct_lbl
		
		// b. Relative number of hours criterium
		gen scontractsoort_hours = 0 if TorP>=0 & TorP!=.
		replace scontractsoort_hours = 1 if TorP<0 & TorP!=.
		
		// Recode some missclassified cases due to 0 base hours (later missing)
		replace scontractsoort_hours=1 if scontractsoort==1 & scontractsoort_hours==0
		
		lab var scontractsoort_hours "soort contract (hours based)"
		lab val scontractsoort_hours cntrct_lbl
		drop TorP

		************************************************************************
		*JOB Summary statistics for whole calendar year within BEID (all obs per unique job ID)
		************************************************************************

		*Select only one exact observation per job ID to reduce file-size
		gen rndm = runiform()
		sort rinpersoons rinpersoon sbeid rndm

		egen select = tag(rinpersoons rinpersoon sbeid)
		keep if select==1
		drop select rndm job_start_exact job_end_exact
		
		*Create full-time-factor on job-level
		gen ft_factor = svoltijddagen_caly_beid / sbaandagen_caly_beid
		
		sort rinpersoons rinpersoon sbeid
		
		
		************************************************************************
		*Merge additional variables
		************************************************************************
		
		*Merge GKSBS from BETAB
		rename sbeid beid
		merge m:1 beid using "${betab`year'}", keepusing (gksbs) ///
			keep(master match) nogen
		rename beid sbeid
		
		sort rinpersoons rinpersoon
		
		*Merge Geslacht / Migratieachtergrond / Geboortejaar
		capture merge m:1 rinpersoons rinpersoon using "${GBAPERSOON2020}", ///
			keepusing(gbageslacht gbageneratie gbageboortejaar gbageboortemaand) ///
			nogen keep(match master)
		
		*Merge Hoogste Opleiding
		capture merge m:1 rinpersoons rinpersoon using "${hoogsteopl`year'}", ///
			keepusing(oplnrhb oplnrhg gewichthoogsteopl) ///
			nogen keep(match master)
	
		save "${data}/fullpolis_`year'.dta", replace
	}
	*

*** 2013-2020: SPOLIS
	foreach year of num 2013/2020 {
		use rinpersoons rinpersoon ikvid sdatumaanvangiko sdatumeindeiko sbaandagen ///
			sbasisloon sbasisuren sbijzonderebeloning slnowrk soverwerkuren ///
			svoltijddagen scontractsoort spolisdienstverband sbeid scaosector ///
			sdatumaanvangikv sdatumeindeikv ssoortbaan using "${spolis`year'}", replace
			
		*Reduce dataset to individuals in sample
		sort rinpersoons rinpersoon
		merge m:1 rinpersoons rinpersoon using "${data}/sample_RIN_2020.dta"
		keep if _merge==3
		drop _merge
		
		*Prepare date indicators
		gen job_start_exact = date(sdatumaanvangiko, "YMD")
		gen job_end_exact = date(sdatumeindeiko, "YMD")
		gen job_start_caly = date(sdatumaanvangikv, "YMD")
		gen job_end_caly = date(sdatumeindeikv, "YMD")
		format job_start_exact job_end_exact job_start_caly job_end_caly %d
		drop sdatumaanvangiko sdatumeindeiko sdatumaanvangikv sdatumeindeikv
	
		* Contract duration
		gen cntrct = 0
		replace cntrct = 1 if scontractsoort=="B"
		replace cntrct = 1 if scontractsoort=="b"
		drop scontractsoort
		rename cntrct scontractsoort
		
		lab var scontractsoort "soort contract"
		lab def cntrct_lbl 0 "Permanent" 1 "Temporary"
		lab val scontractsoort cntrct_lbl
		
		* Full-time / Part-time
		gen dienstverband = real(spolisdienstverband)
		drop spolisdienstverband 
		bys rinpersoons rinpersoon sbeid: egen spolisdienstverband = min(dienstverband)
		drop dienstverband
		
		lab var spolisdienstverband "dienstverband"
		lab def dnst_lbl 1 "Full-time" 2 "Part-time"
		lab val spolisdienstverband dnst_lbl
		
		* Job type
		gen soortbaan = real(ssoortbaan)
		drop ssoortbaan
		recode soortbaan (1 = 10)
		bys rinpersoons rinpersoon sbeid: egen ssoortbaan = max(soortbaan)
		drop soortbaan
		
		lab var ssoortbaan "soort baan"
		lab def srt_lbl 2 "Stagiare" 3 "WSW-er" 4 "Uitzendkracht" ///
			5 "Oproepkracht" 9 "Rest" 10 "Directeur / Grot Aandeelhouder"
		lab val ssoortbaan srt_lbl
		
		
		************************************************************************
		*JOB Summary statistics for whole calendar year within BEID (all obs per unique job ID)
		************************************************************************
		
		/// Earnings & hours (by soortcontract)
		foreach var of var sbasisloon sbasisuren {
			bys rinpersoons rinpersoon sbeid scontractsoort: ///
				egen `var'_caly_beid_CONTRACT = total(`var')
		}
		*
		bys rinpersoons rinpersoon sbeid: egen loon_TEMP = ///
			max(sbasisloon_caly_beid_CONTRACT) if scontractsoort==1
		bys rinpersoons rinpersoon sbeid: egen uren_TEMP = ///
			max(sbasisuren_caly_beid_CONTRACT) if scontractsoort==1
		bys rinpersoons rinpersoon sbeid: egen loon_PERM = ///
			max(sbasisloon_caly_beid_CONTRACT) if scontractsoort==0
		bys rinpersoons rinpersoon sbeid: egen uren_PERM = ///
			max(sbasisuren_caly_beid_CONTRACT) if scontractsoort==0
			
		bys rinpersoons rinpersoon sbeid: egen sbasisloon_caly_beid_TEMP = ///
			max(loon_TEMP)
		bys rinpersoons rinpersoon sbeid: egen sbasisuren_caly_beid_TEMP = ///
			max(uren_TEMP)
		bys rinpersoons rinpersoon sbeid: egen sbasisloon_caly_beid_PERM = ///
			max(loon_PERM)
		bys rinpersoons rinpersoon sbeid: egen sbasisuren_caly_beid_PERM = ///
			max(uren_PERM)
		
		foreach var of var sbasisloon_caly_beid_TEMP-sbasisuren_caly_beid_PERM {
			replace `var' = 0 if `var'==.
		}
		* 
		drop sbasisloon_caly_beid_CONTRACT-uren_PERM
		
		/// Indicator: more hours Temp or Perm within BEID
		gen TorP = sbasisuren_caly_beid_PERM-sbasisuren_caly_beid_TEMP
		lab var TorP "Relative hours Temp vs. Perm (>0: more hours as perm)"
		
		
		/// All Earnings & hours
		foreach var of var sbaandagen-svoltijddagen {
			bys rinpersoons rinpersoon sbeid: egen `var'_caly_beid = total(`var')
		}
		*
		order sbaandagen_caly_beid-svoltijddagen_caly_beid, after(svoltijddagen)
		order sbasisloon_caly_beid_TEMP- TorP, after(svoltijddagen_caly_beid)
		drop sbaandagen-svoltijddagen
		
		
		************************************************************************
		// Temporary Contract Indicator (2 versions)
		************************************************************************
		
		// a. Dominance Criterium
		bys rinpersoons rinpersoon sbeid: egen temp = min(scontractsoort)
		drop scontractsoort
		rename temp scontractsoort
		
		lab var scontractsoort "soort contract"
		lab val scontractsoort cntrct_lbl
		
		// b. Relative number of hours criterium
		gen scontractsoort_hours = 0 if TorP>=0 & TorP!=.
		replace scontractsoort_hours = 1 if TorP<0 & TorP!=.
		
		// Recode some missclassified cases due to 0 base hours (later missing)
		replace scontractsoort_hours=1 if scontractsoort==1 & scontractsoort_hours==0
		
		lab var scontractsoort_hours "soort contract (hours based)"
		lab val scontractsoort_hours cntrct_lbl
		drop TorP

		************************************************************************
		*JOB Summary statistics for whole calendar year within BEID (all obs per unique job ID)
		************************************************************************

		*Select only one exact observation per job ID to reduce file-size
		gen rndm = runiform()
		sort rinpersoons rinpersoon sbeid rndm

		egen select = tag(rinpersoons rinpersoon sbeid)
		keep if select==1
		drop select rndm job_start_exact job_end_exact
		
		*Create full-time-factor on job-level
		gen ft_factor = svoltijddagen_caly_beid / sbaandagen_caly_beid
		
		sort rinpersoons rinpersoon sbeid
		
		
		************************************************************************
		*Merge additional variables
		************************************************************************
		
		*Merge GKSBS from BETAB
		rename sbeid beid
		merge m:1 beid using "${betab`year'}", keepusing (gksbs) ///
			keep(master match) nogen
		rename beid sbeid
		
		sort rinpersoons rinpersoon
		
		*Merge Geslacht / Migratieachtergrond / Geboortejaar
		capture merge m:1 rinpersoons rinpersoon using "${GBAPERSOON2020}", ///
			keepusing(gbageslacht gbageneratie gbageboortejaar gbageboortemaand) ///
			nogen keep(match master)
		
		*Merge Hoogste Opleiding
		capture merge m:1 rinpersoons rinpersoon using "${hoogsteopl`year'}", ///
			keepusing(oplnrhb oplnrhg gewichthoogsteopl) ///
			nogen keep(match master)
	
		save "${data}/fullpolis_`year'.dta", replace
	}
	*
	
	****************************************************************
	*** Add Education variables to 2012 and 2020
	****************************************************************

	*Missing due to inconsistencies in the variable names provided by CBS

	foreach year of num 2012 2020 {
		use "${data}/fullpolis_`year'.dta", replace
		rename (rinpersoons rinpersoon) (RINPERSOONS RINPERSOON)
		merge m:1 RINPERSOONS RINPERSOON using "${hoogsteopl`year'}", ///
			keepusing(OPLNRHB OPLNRHG GEWICHTHOOGSTEOPL) ///
			nogen keep(match master)
		rename (RINPERSOONS RINPERSOON) (rinpersoons rinpersoon)
		rename (OPLNRHB OPLNRHG GEWICHTHOOGSTEOPL) (oplnrhb oplnrhg gewichthoogsteopl)
		order oplnrhb oplnrhg gewichthoogsteopl, after(gbageboortemaand)
	
		save "${data}/fullpolis_`year'.dta", replace
	}
	*
	
	
* --------------------------------------------------------------------------- */
* 2. IDENTIFICATION OF YEARLY MAIN JOBS
* ---------------------------------------------------------------------------- *	
	
**********************************************************
*** Aggregate at BEID-Level & Prepare for further analysis
**********************************************************
	
*** 
	local row = 2
	foreach year of num 2006/2020 {
		use "${data}/CPI.dta", replace
		keep if YEAR==`year'
		tempfile temp
		save "`temp'" 
	
		use "${data}/fullpolis_`year'.dta", replace
		gen YEAR = `year'
		merge m:1 YEAR using "`temp'", nogen
		
		************************************************************************
		// Identify mainjob
		************************************************************************

		bys rinpersoons rinpersoon: egen max_hours = max(sbasisuren_caly_beid)
		gen mainjob= 0
		replace mainjob=1 if max_hours==sbasisuren_caly_beid
		lab var mainjob "Mainjob of a person"
		
		// In few cases: double main job within RIN due to identical hours 
		
		// next criterium: maximum wage (only among most hours jobs)
		duplicates tag rinpersoons rinpersoon mainjob if mainjob==1 , generate(dupl)
		bys rinpersoons rinpersoon: egen max_loon = max(sbasisloon_caly_beid) if ///
			max_hours==sbasisuren_caly_beid
		replace mainjob=0 if dupl!=0 & mainjob==1 & max_loon!=sbasisloon_caly_beid
		
		// next criterium: random pick (handful of cases)
		duplicates tag rinpersoons rinpersoon mainjob if mainjob==1 , generate(dupl2)
		egen tag = tag(rinpersoons rinpersoon)
		replace mainjob=0 if dupl2!=0 & mainjob==1 & tag!=1
		
		// some cases without identified mainjob get random pick
		bys rinpersoons rinpersoon: egen n_mainjob = total(mainjob)
		egen tag2 = tag(rinpersoons rinpersoon) if n_mainjob==0
		replace mainjob=1 if mainjob==0 & tag2==1
		
		drop max_hours dupl-tag2
		
		************************************************************************
		// Identify jobs parallel to mainjob (during same time)
		************************************************************************
		
		gen job_start_mainjob = job_start_caly if mainjob==1
		gen job_end_mainjob = job_end_caly if mainjob==1
		
		bys rinpersoons rinpersoon: egen start_mj = max(job_start_mainjob)
		bys rinpersoons rinpersoon: egen end_mj = max(job_end_mainjob)
		format start_mj end_mj %d
		
		gen parallel = 0
		replace parallel = 1 if mainjob==0 & job_start_caly>=start_mj & ///
			job_start_caly<=end_mj 
		bys rinpersoons rinpersoon: egen parallel_jobs = total(parallel)
		lab var parallel_jobs "Nr. of jobs next to mainjob"
		
		// Prepare for alternative wage measure incl. all parallel jobs
		gen loon = sbasisloon_caly_beid_TEMP if scontractsoort_hours==1
		replace loon = sbasisloon_caly_beid_PERM if scontractsoort_hours==0
		gen uren = sbasisuren_caly_beid_TEMP if scontractsoort_hours==1
		replace uren = sbasisuren_caly_beid_PERM if scontractsoort_hours==0
		
		bys rinpersoons rinpersoon: egen loon_incl_parallel = total(loon) ///
			if mainjob==1 | parallel==1
		bys rinpersoons rinpersoon: egen uren_incl_parallel = total(uren) ///
			if mainjob==1 | parallel==1	
		
		drop job_start_mainjob-parallel loon uren
		
		************************************************************************
		// Identify number of total jobs
		************************************************************************
		
		// Count the number of total beid affiliations
		egen tag = tag(rinpersoons rinpersoon sbeid)
		bys rinpersoons rinpersoon: egen nr_jobs = total(tag)
		lab var nr_jobs "Total number of jobs"
		drop tag
		
		// Table: Nr. of BEID Affiliations (jobs)
		putexcel set "${tables}/fp_descr", sheet("PERS_BEID") modify
		putexcel A1 = ("Year") B1 = ("Unique_PERS_BEID") C1 = ("Unique_PERS"), colwise
		putexcel A`row' = (`year')
		egen rin_beid = tag(rinpersoons rinpersoon sbeid)
		count if rin_beid==1
		putexcel B`row' = (r(N))
		egen rin = tag(rinpersoons rinpersoon)
		count if rin==1
		putexcel C`row' = (r(N))
		drop rin_beid rin
		
		
		*************************************************************************
		// SELECTION - Reduce to one observation per PERSON (MAINJOB)
		************************************************************************
		
		keep if mainjob==1
		drop mainjob

		*************************************************************************
		// Wage measures
		************************************************************************

		// Generate two hourly wage measures
		* Basis
		gen hwage = sbasisloon_caly_beid / sbasisuren_caly_beid
		* With Boni
		gen hwage_bonus = (sbasisloon_caly_beid + sbijzonderebeloning_caly_beid) / sbasisuren_caly_beid
		
		* Robustness measure (use only wages generated based on assigned contract type)
		gen hwage_rbst = .
		replace hwage_rbst = sbasisloon_caly_beid_TEMP / sbasisuren_caly_beid_TEMP ///
			if scontractsoort_hours==1
		replace hwage_rbst = sbasisloon_caly_beid_PERM / sbasisuren_caly_beid_PERM ///
			if scontractsoort_hours==0
		* Robustness measure (all wages & hours in parallel jobs)
		gen hwage_parallel = loon_incl_parallel / uren_incl_parallel

		* Adjust for inflation (2015 prices)
		gen real_hwage = hwage/CPI
		gen real_hwage_bonus = hwage_bonus/CPI
		gen real_hwage_rbst = hwage_rbst/CPI
		gen real_hwage_parallel = hwage_parallel/CPI
		
		*Round up wages below 1 Euro to 1
		replace real_hwage = 1 if real_hwage<1
		replace real_hwage_bonus = 1 if real_hwage_bonus<1
		replace real_hwage_rbst = 1 if real_hwage_rbst<1
		replace real_hwage_parallel = 1 if real_hwage_parallel<1
		
		*Cap wages above 100 Euro (1,361 cases in total)
		replace real_hwage = 100 if real_hwage>100 & real_hwage!=.
		replace real_hwage_bonus = 100 if real_hwage_bonus>100 & real_hwage_bonus!=.
		replace real_hwage_rbst = 100 if real_hwage_rbst>100 & real_hwage_rbst!=.
		replace real_hwage_parallel = 100 if real_hwage_parallel>100 & real_hwage_parallel!=.
		
		*Create log of hourly wages
		gen log_real_hwage = log(real_hwage)
		gen log_real_hwage_bonus = log(real_hwage_bonus)
		gen log_real_hwage_rbst = log(real_hwage_rbst)
		gen log_real_hwage_parallel = log(real_hwage_parallel)
		
		************************************************************************
		// Age measure
		************************************************************************

		* Generate age variable (26 = 0)
		gen byear = real(gbageboortejaar)
		gen age = `year'-2007
		gen age_sqr = age*age
		replace age_sqr = . if YEAR==2006
		drop byear
		
		save "${data}/fullpolis_mainjob_`year'.dta", replace
		local ++row
	}
	*
	
*******************************
*** Merge SECMBUS (Joblessness)
*******************************

		use RINPERSOONS RINPERSOON AANVSECM EINDSECM SECM using "${SECMBUS}", replace
		
		rename RINPERSOONS RINPERSOON, lower 
		rename (AANVSECM EINDSECM SECM) (start end status)
		
		// Keep only unemployment insurance records
		keep if status=="21"
		drop status
		
		// Generate variable
		gen joblessness=1
		
		// Extract Year
		gen year_start = date(start, "YMD")
		gen year_end = date(end, "YMD")
		gen year_s = year(year_start)
		gen year_e = year(year_end)
		drop start end year_start year_end
		
		// Truncate from before 2006
		drop if year_e<=2005
		
		// Expand data wide
		gen diff = year_e-year_s
		foreach diff of num 1/20 {
		    gen year_`diff' = year_s+`diff' if diff>=`diff' & diff!=.
		}
		*
		drop year_e diff
		rename year_s year_0
		gen n = _n
		
		// Reshape to long
		reshape long year_, i(rinpersoons rinpersoon n) j(YEAR)
		
		// Reduce to one record per ID-YEAR
		drop n YEAR
		drop if year_==.
		egen tag = tag(rinpersoons rinpersoon year_)
		keep if tag==1
		drop tag
		rename year_ YEAR
		
		save "${data}/secmbus.dta", replace
		
		************************************************************************
		// Merge to POLIS data
		************************************************************************
		
		foreach year of num 2006/2020 {
			use "${data}/fullpolis_mainjob_`year'.dta", replace
			
			sort rinpersoons rinpersoon YEAR
			
			merge 1:1 rinpersoons rinpersoon YEAR using "${data}/secmbus.dta", ///
				keepusing(joblessness) keep(master match) nogen
			
			rename joblessness jobless
			replace jobless=0 if jobless==.
			order jobless, after(nr_jobs)
			
			save "${data}/fullpolis_mainjob_`year'.dta", replace
		}
		*
	
*********************
*** Merge SBI & GEMHV
*********************

	*Changing variable names over time --> several loops
	
		foreach year of num 2006/2009 {
		use "${data}/fullpolis_mainjob_`year'.dta", replace
		rename sbeid beid
		sort beid
	
		merge m:1 beid using "${betab`year'}", keepusing (SBI2008V`year' GEMHV`year') ///
			keep(master match) nogen
		rename (SBI2008V`year' GEMHV`year') (SBI2008VJJJJ gemhvjjjj)
		order SBI2008VJJJJ gemhvjjjj, after(gksbs)
		rename beid sbeid
	
		sort rinpersoons rinpersoon
	
		save "${data}/fullpolis_mainjob_`year'.dta", replace
	}
	*
	foreach year of num 2010/2013 {
		use "${data}/fullpolis_mainjob_`year'.dta", replace
		rename sbeid beid
		sort beid
	
		merge m:1 beid using "${betab`year'}", keepusing (SBI2008V`year' GEMHV`year') ///
			keep(master match) nogen
		rename (SBI2008V`year' GEMHV`year') (SBI2008VJJJJ gemhvjjjj)
		order SBI2008VJJJJ gemhvjjjj, after(gksbs)
		rename beid sbeid

		sort rinpersoons rinpersoon
	
		save "${data}/fullpolis_mainjob_`year'.dta", replace
	}
	*
	foreach year of num 2014/2018 {
		use "${data}/fullpolis_mainjob_`year'.dta", replace
		rename sbeid beid
		sort beid
	
		merge m:1 beid using "${betab`year'}", keepusing (SBI2008VJJJJ gemhvjjjj) ///
			keep(master match) nogen
		order SBI2008VJJJJ gemhvjjjj, after(gksbs)
		rename beid sbeid
	
		sort rinpersoons rinpersoon
	
		save "${data}/fullpolis_mainjob_`year'.dta", replace
	}
	*	
	foreach year of num 2019/2020 {
		use "${data}/fullpolis_mainjob_`year'.dta", replace
		rename sbeid beid
		sort beid
	
		merge m:1 beid using "${betab`year'}", keepusing (sbi2008vjjjj gemhvjjjj) ///
			keep(master match) nogen
		rename (sbi2008vjjjj) (SBI2008VJJJJ)
		order SBI2008VJJJJ gemhvjjjj, after(gksbs)
		rename beid sbeid
	
		sort rinpersoons rinpersoon
	
		save "${data}/fullpolis_mainjob_`year'.dta", replace
	}
	*

* --------------------------------------------------------------------------- */
* 3. PREPARATION OF VARIABLES AND POOLING
* ---------------------------------------------------------------------------- *

	
****************************************************************
*** Prepare and reduce variable set
****************************************************************

	foreach year of num 2006/2020 {
		use "${data}/fullpolis_mainjob_`year'.dta", replace
		keep rinpersoons rinpersoon sbeid scaosector parallel_jobs nr_jobs ///
			jobless gksbs SBI2008VJJJJ gemhvjjjj gbageslacht gbageneratie ///
			oplnrhb gewichthoogsteopl YEAR soverwerkuren_caly_beid ft_factor ///
			job_start_caly job_end_caly scontractsoort scontractsoort_hours ///
			spolisdienstverband ssoortbaan real_hwage real_hwage_bonus ///
			real_hwage_rbst real_hwage_parallel log_real_hwage ///
			log_real_hwage_bonus log_real_hwage_rbst log_real_hwage_parallel ///
			age age_sqr
			
		// Sector
		replace scaosector = substr(scaosector,1,1)
		gen sector = real(scaosector)
		drop scaosector
		
		lab def sector_lbl 1"Private" 2 "Subsidized" 3 "State"
		lab val sector sector_lbl
		
		// Employer size
		gen emplsize = real(gksbs)
		drop gksbs
		recode emplsize (10 = 1) (21 22 = 2) (30 = 3) (40 = 4) ///
			(50 = 5) (60 = 6) (71 72 = 7) (81 82 = 8) (91 92 = 9) (93 = 10)
		drop if emplsize==20 // 20 miscoded cases
		
		lab def size_lbl 0 "0 employees" 1 "1 employees" 2 "2-4 employees" ///
			3 "5-9 employees" 4 "10-19 employees" 5 "20-49 employees" ///
			6 "50-99 employees" 7 "100-199 employees" 8 "200-499 employees" ///
			9 "500-1999 employees" 10 ">=2000 employees"
		lab val emplsize size_lbl
		
		// Industry
		replace SBI2008VJJJJ = substr(SBI2008VJJJJ,1,2)
		gen industry = real(SBI2008VJJJJ)
		drop SBI2008VJJJJ
		recode industry (1/3 = 1) (6/9 = 2) (10/33 = 3) (35 = 4) (36/39 = 5) ///
			(41/43 = 6) (45/47 = 7) (49/53 = 8) (55/56 = 9) (58/63 = 10) ///
			(64/66 = 11) (68 = 12) (69/75 = 13) (77/82 = 14) (84=15) (85 = 16) ///
			(86/88 = 17) (90/93 = 18) (94/96 = 19) (97/98 = 20) (99 = 21)
			
		lab def industry_lbl 1"Agriculture, forestry, and fishing" 2"Mining and quarrying" ///
			3"Manufacturing" 4"Electricity, gas, steam, and air conditioning supply" ///
			5"Water supply; sewerage, waste management and remidiation activities" ///
			6"Construction" 7"Wholesale and retail trade; repair of motorvehicles and motorcycles" ///
			8"Transportation and storage" 9"Accomodation and food service activities" ///
			10"Information and communication" 11"Financial institutions" ///
			12"Renting, buying, and selling of real estate" ///
			13"Consultancy, research and other specialised business services" ///
			14"Renting and leasing of tangible goods and other business support services" ///
			15"Public administration, public services, and compulsory social security" ///
			16"Education" 17"Human health and social work activities" ///
			18"Culture, sports, and recreation" 19"Other service activities" ///
			20"Activities of households as employers" ///
			21"Extraterritorial organizations and bodies" 
		lab val industry industry_lbl
		
		// Gender
		gen gender = real(gbageslacht)
		drop gbageslacht
		
		lab def gender_lbl 1 "Male" 2 "Female"
		lab val gender gender_lbl
		
		// Migration background
		gen migback = real(gbageneratie)
		drop gbageneratie
		
		lab def migback_lbl 0 "No migration background" 1 "1st generation" ///
			2 "2nd generation"
		lab val migback migback_lbl
		
		// Education
		rename oplnrhb oplnr
		sort oplnr
		merge m:1 oplnr using "${OPLNR}", keepusing (soi2016niveau) ///
			keep(master match) nogen
		gen edu = real(soi2016niveau)
		drop soi2016niveau
		
		recode edu (10 20 = 1) (31 32 33 = 2) (41 42 = 3) (43 = 4) (51 52 53 = 5) ///
			(60 70 = 6)
			
		gen ed = edu
		recode ed (1 2 = 1) (3 4 = 2) (5 6 = 3)
			
		lab def edu_lbl 1"Basic education" 2"Lower secondary" 3"Upper secondary (low)" ///
			4"Upper secondary (high)" 5"Bachelor" 6"Master, Doctor"
		lab val edu edu_lbl
		
		lab def ed_lbl 1"Low" 2"Mid" 3"High"
		lab val ed ed_lbl
		
		rename gewichthoogsteopl wgt_edu
		
		// Overwork
		rename soverwerkuren_caly_beid overwork
		replace overwork = 1 if overwork!=0 & overwork!=.
		
		// Contract duration
		rename scontractsoort cntrct_lngth
		rename scontractsoort_hours cntrct_lngth_hours
		
		lab val cntrct_lngth cntrct_lbl
		lab val cntrct_lngth_hours cntrct_lbl
		
		// Full-time / Part-time
		rename spolisdienstverband ft_cat
		lab val ft_cat dnst_lbl
		
		* Job type
		rename ssoortbaan job_type
		lab val job_type srt_lbl
		
		*********
		*Order of variables
		*********
		order YEAR, before(rinpersoons)
		order sector industry emplsize gemhvjjjj, after(sbeid)
		rename (job_start_caly job_end_caly) (job_start job_end)
		order job_start job_end ft_factor ft_cat, after(gemhvjjjj)
		order cntrct_lngth cntrct_lngth_hours job_type overwork, after(ft_cat)
		order age age_sqr, after(gender)
		order oplnr wgt_edu, after(ed)
		
		save "${data}/fullpolis_mainjob_`year'.dta", replace
	}
	*
	

*********************************************************
*** Pooling of all Main Jobs + Define Population
*********************************************************

	local row = 2
	foreach year of num 2006/2019 {
		use "${data}/fullpolis_mainjob_`year'.dta", replace
		
		// Combine person identifier
		gen RIN = rinpersoons+rinpersoon
		
		// Table: Selection cuts
		putexcel set "${tables}/fp_descr", sheet("Selection cuts") modify
		putexcel A1 = ("Year") B1 = ("Unique_PERS") C1 = ("After job type") ///
			D1 = ("After industry 21") E1 = ("After emplsize 0"), colwise
		putexcel A`row' = (`year')
		
		count 
		putexcel B`row' = (r(N))
		
		// Remove Interns / WSW-ers & Directeur / Grote Aandeelhouders
		drop if job_type==2 | job_type==3 | job_type==10 
		
		count 
		putexcel C`row' = (r(N))
		
		// Remove the industry category "21" (Extraterritorial organizations and bodies)
		* (0.03%)
		drop if industry==21
		
		count 
		putexcel D`row' = (r(N))
		
		// Remove the emplsize category "0" (0-employees in '06, '07, '18)
		* (0.03%)
		drop if emplsize==0
		
		count 
		putexcel E`row' = (r(N))
		
		tempfile temp`year'
		save "`temp`year''"
		
		local ++row
	}
	*
	
	append using "`temp2006'" "`temp2007'" "`temp2008'" "`temp2009'" "`temp2010'" ///
		"`temp2011'" "`temp2012'" "`temp2013'" "`temp2014'" "`temp2015'" ///
		"`temp2016'" "`temp2017'" "`temp2018'"
		
		
	save "${data}/chrt79.dta", replace	

* --------------------------------------------------------------------------- */
* 4. POOLED DATASET
* ---------------------------------------------------------------------------- *
	
	use "${data}/chrt79.dta", replace
	
	sort rinpersoons rinpersoon
	
*********************************************************
*** Time-constant education codes
*********************************************************
	
	// Check consistency of education codes
	bys RIN: egen ed_min = min(ed)
	bys RIN: egen ed_max = max(ed)
	
	// Identify observations before a switch
	gen ed_diff = ed-ed_max
	recode ed_diff (-1=1) (-2=2)
	replace ed_diff = 0 if ed_diff==. & ed_max!=.
	
	// Time-constant education
	gen edtc = ed_max
	lab val edtc ed_lbl
	
	// Time-constant education weight. Assign average of all observed weights
	bys RIN: egen wgt = mean(wgt_edu)


*********************************************************
*** Transition variables
*********************************************************
	
	sort RIN YEAR
	
	// Create year counter
	by RIN: gen n=_n
	
	// Create variable that indicates panel (re)entries
	* entry = a first initial observation of that person after 2006
	* re-entry = a first observation after this person left the data
	gen re_enter=.
	foreach year of num 2007/2019 {
		by RIN: replace re_enter = 0 if (YEAR==`year') & (YEAR[_n-1]==(`year'-1))
		by RIN: replace re_enter = 1 if (YEAR==`year') & (YEAR[_n-1]!=(`year'-1)) & n==1
		by RIN: replace re_enter = 2 if (YEAR==`year') & (YEAR[_n-1]!=(`year'-1)) & n!=1
	}
	*
	lab var re_enter "(Re-)Entries into Panel"
	lab def re_enter_lbl 0"No" 1"Entry" 2"Re-Entry"
	lab val re_enter re_enter_lbl
	
	
	* Contract type in t-1 (previous year)
	by RIN: gen temp_tminus1 = cntrct_lngth_hour[_n-1]
	lab var temp_tminus1 "Temporary contract in t-1 ('07-'19)"
	replace temp_tminus1=. if re_enter==1 |re_enter==2
	
	
	* Job switch 
	gen switch = .
	foreach year of num 2007/2019 {
		by RIN: replace switch=1 if YEAR==`year' & (YEAR[_n-1]==`year'-1) & ///
			(sbeid[_n-1]!=sbeid)
		by RIN: replace switch=0 if YEAR==`year' & (YEAR[_n-1]==`year'-1) & ///
			(sbeid[_n-1]==sbeid)
	}
	*
	by RIN: replace switch=0 if re_enter==1 | re_enter==2
	
	
	* Labour Market Events
	egen lmevents = group(temp_tminus1 switch re_enter)
	replace lmevents = lmevents-1
	lab def lmevents_lbl 0"Perm Stay" 1"Perm Switch" 2"Temp Stay" 3"Temp Switch"
	lab val lmevents lmevents_lbl
	
	
	* Labour Market Events (detailed)
	egen lmevents_detail = group(temp_tminus1 switch cntrct_lngth_hours re_enter)
	replace lmevents_detail = lmevents_detail-1
	lab def lmevents_det_lbl 0"Perm Stay Perm" 1"Perm Stay Temp" 2"Perm Switch Perm" ///
		3"Perm Switch Temp" 4"Temp Stay Perm" 5"Temp Stay Temp" 6"Temp Switch Perm" ///
		7"Temp Switch Temp"
	lab val lmevents_detail lmevents_det_lbl
	
	* Wage change
	sort RIN YEAR
	by RIN: gen wg_chng = log_real_hwage-log_real_hwage[_n-1]
	
	
	**************************
	// Cases per year [Full]
	**************************
	putexcel set "${tables}/descr/descr_n", sheet("n") modify
	putexcel A1 = ("year") B1 = ("n_cont_employed") C1 = ("n_sample") D1 = ("n_full")
	tab YEAR, matrow(rows) matcell(cells)
	putexcel A2 = matrix(rows) D2 = matrix(cells)
	
	
* --------------------------------------------------------------------------- */
* 5. FINALIZE SAMPLE
* ---------------------------------------------------------------------------- *
	
	*********************************
	// Select on available education
	*********************************
	
	*Reduce to sample with education codes
	drop if edtc==.
	
	// Remove missing cases
	drop if log_real_hwage==.
	drop if log_real_hwage_rbst==.
	
	* Percentiles for analysis across the wage distribution
	/*egen pctl = xtile(real_hwage), w(wgt) n(100) by(YEAR) */
	
	*********************************
	// Cases per year [Education Sample]
	*********************************
	putexcel set "${tables}/descr/descr_n", sheet("n") modify
	tab YEAR, matcell(cells)
	putexcel C2 = matrix(cells)
	
	*********************************
	// Descriptives: Jobs [Education Sample]
	*********************************
	putexcel set "${tables}/descr/descr_jobs", sheet("jobs") modify
	putexcel A1 = ("countjobs") G1 = ("paralleljobs") L1 = ("nrjobs") Q1 = ("jobless") 
	putexcel A2 = ("Year") B2 = ("Total") C2 = ("ISCED 1-2") D2 = ("ISCED 3-4") E2 = ("ISCED 5-8") ///
		G2 = ("Total") H2 = ("ISCED 1-2") I2 = ("ISCED 3-4") J2 = ("ISCED 5-8") ///
		L2 = ("Total") M2 = ("ISCED 1-2") N2 = ("ISCED 3-4") O2 = ("ISCED 5-8") ///
		Q2 = ("Total") R2 = ("ISCED 1-2") S2 = ("ISCED 3-4") T2 = ("ISCED 5-8")
	local row=3
	foreach year of num 2006/2019 {
		putexcel A`row' = (`year')
		count if YEAR==`year'
		putexcel B`row' = (r(N))
		sum parallel_jobs if YEAR==`year' [aw=wgt]
		putexcel G`row' = (r(mean))
		sum nr_jobs if YEAR==`year' [aw=wgt]
		putexcel L`row' = (r(mean))
		sum jobless if YEAR==`year' [aw=wgt]
		putexcel Q`row' = (r(mean))
		
		count if YEAR==`year' & edtc==1
		putexcel C`row' = (r(N))
		sum parallel_jobs if YEAR==`year' & edtc==1 [aw=wgt]
		putexcel H`row' = (r(mean))
		sum nr_jobs if YEAR==`year' & edtc==1 [aw=wgt]
		putexcel M`row' = (r(mean))
		sum jobless if YEAR==`year' & edtc==1 [aw=wgt]
		putexcel R`row' = (r(mean))
		
		count if YEAR==`year' & edtc==2
		putexcel D`row' = (r(N))
		sum parallel_jobs if YEAR==`year' & edtc==2 [aw=wgt]
		putexcel I`row' = (r(mean))
		sum nr_jobs if YEAR==`year' & edtc==2 [aw=wgt]
		putexcel N`row' = (r(mean))
		sum jobless if YEAR==`year' & edtc==2 [aw=wgt]
		putexcel S`row' = (r(mean))
		
		count if YEAR==`year' & edtc==3
		putexcel E`row' = (r(N))
		sum parallel_jobs if YEAR==`year' & edtc==3 [aw=wgt]
		putexcel J`row' = (r(mean))
		sum nr_jobs if YEAR==`year' & edtc==3 [aw=wgt]
		putexcel O`row' = (r(mean))
		sum jobless if YEAR==`year' & edtc==3 [aw=wgt]
		putexcel T`row' = (r(mean))
		
		local ++row
	}
	*
	
	
	save "${posted}/chrt79_ana.dta", replace	
		
	
* --------------------------------------------------------------------------- */
* 6. CLOSE LOG FILE
* ---------------------------------------------------------------------------- *

	log close

	
	