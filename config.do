/*=============================================================================* 
* CONFIGURATIONS - SETTINGS 
*==============================================================================*
 	Project: Temporary Employment and Wage Inequality over the Life Course
	Author: Christoph Janietz
	Last update: 18-04-2023
* ---------------------------------------------------------------------------- */

*** General settings
	version 16
	set more off, perm 
	cap log close
	set seed 12345 // take the same random sample every time
	set scheme plotplain, perm // set scheme graphs
	set matsize 11000, perm 
	set maxvar 32767, perm
	matrix drop _all

*** Set paths to folders
	// to folders 
	global dir 			"H:/Christoph/art2"
	global data			"$dir/01_data" 		// (S)POLIS/BEID FILES (reduced)
	global posted		"$dir/02_posted"	// ANALYSIS FILES
	global logfiles		"$dir/03_logfiles"
	global tables		"$dir/04_tables"
	global figures		"$dir/05_figures"
	global dofiles 		"$dir/06_dofiles"
	
	// to microdata files (use converted files when possible)
	
	global polis2006 "G:\Polis\POLISBUS\2006\geconverteerde data\POLISBUS2006V2.DTA"
	global polis2007 "G:\Polis\POLISBUS\2007\geconverteerde data\POLISBUS2007V2.DTA"
	global polis2008 "G:\Polis\POLISBUS\2008\geconverteerde data\POLISBUS2008V2.DTA"
	global polis2009 "G:\Polis\POLISBUS\2009\geconverteerde data\POLISBUS2009V2.DTA"
	
	global spolis2010 "G:\Spolis\SPOLISBUS\2010\geconverteerde data\SPOLISBUS2010V2.DTA"
	global spolis2011 "G:\Spolis\SPOLISBUS\2011\geconverteerde data\SPOLISBUS2011V2.DTA"
	global spolis2012 "G:\Spolis\SPOLISBUS\2012\geconverteerde data\SPOLISBUS2012V2.dta"
	global spolis2013 "G:\Spolis\SPOLISBUS\2013\geconverteerde data\SPOLISBUS2013V3.DTA"
	global spolis2014 "G:\Spolis\SPOLISBUS\2014\geconverteerde data\SPOLISBUS 2014V1.DTA"
	global spolis2015 "G:\Spolis\SPOLISBUS\2015\geconverteerde data\SPOLISBUS 2015V3.DTA"
	global spolis2016 "G:\Spolis\SPOLISBUS\2016\geconverteerde data\SPOLISBUS2016V3.DTA"
	global spolis2017 "G:\Spolis\SPOLISBUS\2017\geconverteerde data\SPOLISBUS2017V2.DTA"
	global spolis2018 "G:\Spolis\SPOLISBUS\2018\geconverteerde data\SPOLISBUS2018V5.DTA"
	global spolis2019 "G:\Spolis\SPOLISBUS\2019\geconverteerde data\SPOLISBUS2019V6.DTA"
	global spolis2020 "G:\Spolis\SPOLISBUS\2020\geconverteerde data\SPOLISBUS2020V5.DTA"
	
	global betab2006 "G:\Arbeid\BETAB\2006\geconverteerde data\140707 BETAB 2006V1.DTA" 
	global betab2007 "G:\Arbeid\BETAB\2007\geconverteerde data\140707 BETAB 2007V1.DTA" 
	global betab2008 "G:\Arbeid\BETAB\2008\geconverteerde data\140707 BETAB 2008V1.DTA"
	global betab2009 "G:\Arbeid\BETAB\2009\geconverteerde data\140707 BETAB 2009V1.DTA" 
	global betab2010 "G:\Arbeid\BETAB\2010\geconverteerde data\140707 BETAB 2010V1.DTA" 
	global betab2011 "G:\Arbeid\BETAB\2011\geconverteerde data\140707 BETAB 2011V1.DTA" 
	global betab2012 "G:\Arbeid\BETAB\2012\geconverteerde data\140707 BETAB 2012V1.DTA" 
	global betab2013 "G:\Arbeid\BETAB\2013\geconverteerde data\141215 BETAB 2013V1.DTA" 
	global betab2014 "G:\Arbeid\BETAB\2014\geconverteerde data\BE2014TABV2.dta" 
	global betab2015 "G:\Arbeid\BETAB\2015\geconverteerde data\BE2015TABV125.DTA" 
	global betab2016 "G:\Arbeid\BETAB\2016\geconverteerde data\BE2016TABV124.DTA" 
	global betab2017 "G:\Arbeid\BETAB\2017\geconverteerde data\BE2017TABV124.DTA"
	global betab2018 "G:\Arbeid\BETAB\2018\geconverteerde data\BE2018TABV124.DTA"
	global betab2019 "G:\Arbeid\BETAB\2019\geconverteerde data\BE2019TABV124.DTA"
	global betab2020 "G:\Arbeid\BETAB\2020\geconverteerde data\BE2020TABV124.DTA"
	
	global hoogsteopl2006 "G:\Onderwijs\HOOGSTEOPLTAB\2006\geconverteerde data\120619 HOOGSTEOPLTAB 2006V1.dta"
	global hoogsteopl2007 "G:\Onderwijs\HOOGSTEOPLTAB\2007\geconverteerde data\120619 HOOGSTEOPLTAB 2007V1.dta"
	global hoogsteopl2008 "G:\Onderwijs\HOOGSTEOPLTAB\2008\geconverteerde data\120619 HOOGSTEOPLTAB 2008V1.dta"
	global hoogsteopl2009 "G:\Onderwijs\HOOGSTEOPLTAB\2009\geconverteerde data\120619 HOOGSTEOPLTAB 2009V1.dta"
	global hoogsteopl2010 "G:\Onderwijs\HOOGSTEOPLTAB\2010\geconverteerde data\120918 HOOGSTEOPLTAB 2010V1.dta"
	global hoogsteopl2011 "G:\Onderwijs\HOOGSTEOPLTAB\2011\geconverteerde data\130924 HOOGSTEOPLTAB 2011V1.dta"
	global hoogsteopl2012 "G:\Onderwijs\HOOGSTEOPLTAB\2012\geconverteerde data\141020 HOOGSTEOPLTAB 2012V1.dta"
	global hoogsteopl2013 "G:\Onderwijs\HOOGSTEOPLTAB\2013\geconverteerde data\HOOGSTEOPL2013TABV3.dta"
	global hoogsteopl2014 "G:\Onderwijs\HOOGSTEOPLTAB\2014\geconverteerde data\HOOGSTEOPL2014TABV3.dta"
	global hoogsteopl2015 "G:\Onderwijs\HOOGSTEOPLTAB\2015\geconverteerde data\HOOGSTEOPL2015TABV3.DTA" 
	global hoogsteopl2016 "G:\Onderwijs\HOOGSTEOPLTAB\2016\geconverteerde data\HOOGSTEOPL2016TABV2.DTA"
	global hoogsteopl2017 "G:\Onderwijs\HOOGSTEOPLTAB\2017\geconverteerde data\HOOGSTEOPL2017TABV3.dta" 
	global hoogsteopl2018 "G:\Onderwijs\HOOGSTEOPLTAB\2018\geconverteerde data\HOOGSTEOPL2018TABV3.dta"
	global hoogsteopl2019 "G:\Onderwijs\HOOGSTEOPLTAB\2019\geconverteerde data\HOOGSTEOPL2019TABV2.DTA"
	global hoogsteopl2020 "G:\Onderwijs\HOOGSTEOPLTAB\2020\geconverteerde data\HOOGSTEOPL2020TABV2.DTA"
	
	global GBAPERSOON2009 "G:\Bevolking\GBAPERSOONTAB\2009\geconverteerde data\GBAPERSOON2009TABV1.DTA"
	// CBS recommends to use GBAPERSOONTAB2009 for years prior 2009
	global GBAPERSOON2020 "G:\Bevolking\GBAPERSOONTAB\2020\geconverteerde data\GBAPERSOON2020TABV3.dta"
	
	global OPLNR "K:\Utilities\Code_Listings\SSBreferentiebestanden\geconverteerde data\OPLEIDINGSNRREFV29.dta"
	
	global SECMBUS "G:\InkomenBestedingen\SECMBUS\geconverteerde data\SECMBUS2020V1.dta"
	
	global income2007 "G:\InkomenBestedingen\INTEGRAAL PERSOONLIJK INKOMEN\2007\geconverteerde data\PERSOONINK2007TABV3.dta"
	global income2008 "G:\InkomenBestedingen\INTEGRAAL PERSOONLIJK INKOMEN\2008\geconverteerde data\PERSOONINK2008TABV3.dta"
	global income2009 "G:\InkomenBestedingen\INTEGRAAL PERSOONLIJK INKOMEN\2009\geconverteerde data\PERSOONINK2009TABV2.DTA"
	global income2010 "G:\InkomenBestedingen\INTEGRAAL PERSOONLIJK INKOMEN\2010\geconverteerde data\PERSOONINK2010TABV3.DTA"
	global income2011 "G:\InkomenBestedingen\INPATAB\geconverteerde data\INPA2011TABV2.DTA"
	global income2012 "G:\InkomenBestedingen\INPATAB\geconverteerde data\INPA2012TABV2.DTA"
	global income2013 "G:\InkomenBestedingen\INPATAB\geconverteerde data\INPA2013TABV2.DTA"
	global income2014 "G:\InkomenBestedingen\INPATAB\geconverteerde data\INPA2014TABV2.DTA"
	global income2015 "G:\InkomenBestedingen\INPATAB\geconverteerde data\INPA2015TABV2.DTA" 
	global income2016 "G:\InkomenBestedingen\INPATAB\geconverteerde data\INPA2016TABV3.DTA"
	global income2017 "G:\InkomenBestedingen\INPATAB\geconverteerde data\INPA2017TABV3.dta" 
	global income2018 "G:\InkomenBestedingen\INPATAB\geconverteerde data\INPA2018TABV2.DTA"
	global income2019 "G:\InkomenBestedingen\INPATAB\geconverteerde data\INPA2019TABV1.DTA"