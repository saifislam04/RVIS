/*----------------------------------------------------------------------\
|                             SAVE DATA STP                             |
|-----------------------------------------------------------------------|

  This program receives some data
  stores it in a dataset
  and then redirects to another url

|-----------------------------------------------------------------------|
|                                                                       |
\----------------------------------------------------------------------*/


*** CONSTANTS -----------------------------------------;
%let dataset = work.tests;



*** globalize all incoming paramaters -----------------------------------------;
%global var1 var2 var3;



*** delete previous same record -----------------------------------------;
data &dataset ;
	*length var1$50. var2$100. var3 3. ;
	set &dataset ;
	where id ^= "&id" ;
	run;


*** add new record, even if dataset is empty -----------------------------------------;
data &dataset ;
	*length var1$50. var2$100. var3 3. ;
	if _N_=1 then do;
		var1="&var1";
		var2="&var2";
		var3=&var3;
		output;
		end;
	set &dataset end=eof;
	output;
	run;


* remove duplicates & sort -----------------------------------------;
proc sort data=&dataset nodup;
	*by var2 ;
	run;quit;



%let redirectURL = 'https://www.google.com/';

*** REDIRECT -----------------------------------------;
data _null_;
	file _webout;
	put '<HTML>';
	put '	<HEAD>';
	put '		<TITLE></TITLE>';
	put '		<META http-equiv="refresh" content="0;URL='&redirectURL'">';
	put '	</HEAD>';
	put '	<BODY>';
	put '	</BODY>';
	put '</HTML>';
	run;

%stpbegin;
%stpend;




*** MACRO -----------------------------------;

%macro json4datatables(ds,path,file,charvars,numvars)
	/ store source
	DES="json4datatables(ds,path,file,charvars,numvars)";

	/* creates a json with no headers
	 * a bit like a csv without the first line
	 * it takes thus less space
	 * but you have to know which column is what
	 */

	data _null_ (encoding='UTF-8');
		length line $300;
		set &ds nobs=nobs end=end;
		file "&path.&file." encoding='utf-8' bom/**/ ;

		line = '[';

		%if &charvars ne %then %do;
			%do i=1 %to %sysfunc(countw(&charvars));
				%let charvar = %scan(&charvars, &i);
				%if &i ne 1 %then %do;
					line = cats(line,',');
				%end;
				line = cats(line,'"',&charvar,'"');
			%end;
		%end;
		%if &numvars ne %then %do;
			%do i=1 %to %sysfunc(countw(&numvars));
				%let numvar = %scan(&numvars, &i);
				%if &i ne 1 OR &charvars ne %then %do;
					line = cats(line,',');
				%end;
				line = cats(line,'',&numvar,'');
			%end;
		%end;

		line = cats(line,']');

		if _n_=1 then put '{"data": [';
		if not end then put line +(-1) ',';
		else do;
			put line;
			put ']}';
		end;
		run;

%mend json4datatables;