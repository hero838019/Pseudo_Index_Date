/*************************************************************************/
/*Data input*/
proc import datafile="yourpath\exposed.csv"
    out=exposed       
    dbms=csv        
    replace;         
    getnames=yes;    
run;


proc import datafile="yourpath\unexposed.csv"
    out=unexposed       
    dbms=csv        
    replace;         
    getnames=yes; 
run;
/*************************************************************************/

data exposed1;
	set exposed;
	gap=dis_date-index_date;
run;


data exposed2(drop=gap);
	set exposed1;
run;


proc sgplot data=exposed1;
    title "Distribution of time between index date and dispensing date 
		for the exposed group";
    histogram gap;
    density gap/type=normal;
    xaxis label="Interval (days)";
    yaxis label="Frequency";
run;


proc sort data=exposed; by index_date dis_date; run; 
/*400*/

proc sort data=unexposed; by index_date; run; 
/*1,000*/


/*Simulate gaps for control group*/
data gap;
	set exposed; 
	gap=dis_date-index_date;
	keep gap;	
run;
data gap1; 
	choose=int(ranuni(58)*n)+1; /*Use seed for reproducibility*/
	set gap 
	point=choose nobs=n;
	i+1; 
	if i>1000 then stop;	
run;

/*Assign pseudo-dispensing date for controls: nontrt_date*/
proc sort data=gap1; 
	by decending gap; 
run; 

/*Here we assume that patients with longer follow-up (dtend-index_date) will have a later nontrt_date*/
data notrt; 
	set unexposed; 
	fu=dtend-index_date;
run;
proc sort data=notrt;  
	by decending fu; 
run;
data notrt1;
	merge notrt gap1;
	drop i;
run;

	
proc freq data=notrt1; 
	table daa; 
run;
data notrt2 (drop=fu gap); 
	set notrt1; 
	dis_date=index_date+gap; 
	if dtstart<=dis_date<=dtend;
	format dis_date mmddyy10.;
run; 
/*We need to make sure that nontrt_date falls within dtstart and dtend.
In your case, it should be between the conception date and the outcome date.*/

proc sgplot data=notrt2;
    title "Distribution of time between index date and pseudo-dispensing date";
    histogram gap;
    density gap/type=normal;
    xaxis label="Interval (days)";
    yaxis label="Frequency";
run;


proc means data=exposed1 mean std p25 p75 min max;
    var gap;
run;
proc means data=notrt2 mean std p25 p75 min max;
    var gap;
run;
