cd "C:\Users\Abi\Desktop\tesis2final\"

* Base de tratamientos

bys state: gen x = _n == 1

drop if statecode == . 

keep if x == 1
drop x
keep state statecode

export excel using "C:\Users\Abi\Desktop\tesis2final\tratamiento.xls"

import excel "C:\Users\Abi\Desktop\tesis2final\tratamientomodificado.xlsx", sheet("Sheet1") firstrow clear

gen treatment = ym(year_eff, month_eff)
format treatment %tm

egen treat3 = concat(year_eff month_eff), p("-") 

rename codestate statecode

drop if statecode == . 

encode treat3, generate(treat_CS)

replace treat_CS = 0 if treatment == .-.

save tratamientofinal, replace

* Cargamos la base con la cantidad de suicidios 

import delimited "C:\Users\Abi\Desktop\tesis2final\Underlying Cause of Death, 1999-2020.txt", clear

/*
gen time = monthly(monthcode, "YM")
format time %tm
gen month2=substr(monthcode,6,.)
gen year2=substr(monthcode,1,4)

destring month2 year2, replace

local w 0
gen id_time=.
forv y=1999/2020 {
	forv z=1/12 {
		local w=`w'+1
		replace id_time=`w' if month2==`z' & year2==`y'
	}
}

*/
drop if statecode == . 

drop notes 

* Hacemos el merge 

merge m:1 statecode using tratamientofinal

save basecontratamientofinal

drop year yearcode month monthcode population cruderate month_enac year_enac month_eff year_eff _merge treat3

save basecontratamiento, replace 

use basecontratamiento, clear

xtset statecode time 

tsfill, full

gen treat= (treatment <= time) 

* para CS

gen treat2 = (treatment == time)


*** Importo la base con los controles *** 

use "C:\Users\Abi\Desktop\base_controles.dta", clear

** Genero un id por tiempo 

drop id_time

local w 0
gen id_time=.
forv y=1999/2020 {
	forv z=1/12 {
		local w=`w'+1
		replace id_time=`w' if time==ym(`y',`z')
	}
}

 








* Me quedo con el mínimo del id_time para el tratamiento 

bys statecode: egen treateff_CS = min(id_time) if treat2==1

replace treateff_CS=0 if treateff_CS==. 

* Event Study 

set scheme white_tableau 

* variables: state statecode time treatment treat



* Ahora reemplazamos los missings generados con ceros 

replace death = 0 if death== .

gen l_deaths = log(deaths)

* BASE BALANCEADA

save base_balanceada_fin, replace

use base_balanceada_fin, clear

gen estado = ""
levelsof state, local(est)
foreach s of local est{
	qui sum statecode if state == "`s'"
	replace estado = "`s'" if statecode == `r(mean)'
}
drop state 
rename estado state
order state

save save_base_balanceado, replace

 
 ***** ARREGLO DE LA BASE DE DATOS ******* 
 
 * Vuelvo a generar el id_time 

local w 0
gen id_time1=.
forv y=1999/2020 {
	forv z=1/12 {
		local w=`w'+1
		replace id_time1=`w' if time==ym(`y',`z')
	}
}

 


forval k=1(1)220{
	qui xtreg deaths treat i.time deaths_inj if id_time>`k', fe i(statecode) cluster(statecode) 
	est table, keep(treat) b se p
}

gen prueba=1 if deaths==0

bys time: egen cantidad_ceros = sum(prueba)




