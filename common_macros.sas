/***************************************************************************/
/*                         COMMON UTILITY MACROS PROGRAM                   */
/*                         FOR USE FOR BOTH ME AND NME                     */
/*                                                                         */
/*                    LAST PROGRAM UPDATE DECEMBER 8, 2016                 */
/*                                                                         */
/* PART 1:  MACRO TO GET COUNTS OF THE DATASETS                            */ 
/* PART 2:  REVIEW AND REPORT GENERAL SAS LOG ALERTS SUCH AS ERRORS,       */
/*          WARNINGS, UNINITIALIZED VARIABLES ETC.) AND PROGRAM SPECIFIC   */
/*          ALERTS WE NEED TO WATCH FOR.                                   */
/***************************************************************************/

/*--------------------------------------------------------------------*/
/* PART 1: MACRO TO GET COUNTS OF THE DATASETS                        */
/*     THAT NEED BE TO REVIEWED                                       */
/*--------------------------------------------------------------------*/

%MACRO CMAC1_COUNTER (DATASET =, MVAR=);

	%GLOBAL COUNT_&MVAR.;
	PROC SQL;
      	SELECT COUNT(*)
       	INTO :COUNT_&MVAR.
       	FROM &DATASET.;
   	QUIT;

%MEND CMAC1_COUNTER ;
 
/*----------------------------------------------------------------------*/ 
/* PART 2: REVIEW LOG AND REPORT SUMMARY AT THE END OF THE LOG FOR:     */
/* 	(A) GENERAL SAS ALERTS SUCH AS ERRORS, WARNINGS, UNINITIALIZED ETC. */
/* 	(B) PROGRAM SPECIFIC ALERTS THAT WE NEED TO LOOK OUT FOR.           */
/*----------------------------------------------------------------------*/

%MACRO C_MAC2_READLOG (LOG= , ME_OR_NME =);

/*----------------------------------------------------------------------*/ 
/*  PRINT FULL LOG TO THE SAS ENTERPRISE WINDOW                         */
/*----------------------------------------------------------------------*/

	DATA _NULL_;
  		INFILE LOGFILE;
  		INPUT;
  		PUTLOG _INFILE_;
	RUN;

/*----------------------------------------------------------------------*/ 
/*  CHECK THE JOB LOG FOR ERRORS, WARNINGS, UNINTIALIZED VARIABLES,     */
/* 	CONVERTED, MISSING, REPEATS AND LICENSE.                            */
/* 	PRINT THE SUMMARY TO THE JOB LOG                                    */
/*----------------------------------------------------------------------*/

	DATA _NULL_;
		INFILE "&LOG." END=END MISSOVER PAD;
		INPUT LINE $250.;

		IF UPCASE(COMPRESS(SUBSTR(LINE,1,6)))="ERROR:" THEN
			ERROR+1;

		ELSE IF UPCASE(COMPRESS(SUBSTR(LINE,1,8)))="WARNING:" THEN DO;
			WARNING+1;

			LICENSE_I=INDEX((LINE),'THE BASE PRODUCT');
			LICENSE_W=INDEX((LINE),'WILL BE EXPIRING SOON');
			LICENSE_X=INDEX((LINE),'THIS UPCOMING EXPIRATION');
			LICENSE_Y=INDEX((LINE),'INFORMATION ON YOUR WARNING PERIOD');
			LICENSE_Z=INDEX((LINE),'YOUR SYSTEM IS SCHEDULED TO EXPIRE');

		IF LICENSE_I OR LICENSE_W OR LICENSE_X OR LICENSE_Y OR LICENSE_Z THEN
			LICENSE+1;
		END;

		ELSE IF UPCASE(COMPRESS(SUBSTR(LINE,1,5)))="NOTE:" THEN DO;

			UNINIT_I=INDEX(UPCASE(LINE),'UNINITIALIZED');
				IF UNINIT_I THEN
				UNINIT+1;

			REPEAT_I=INDEX(UPCASE(LINE),'REPEATS OF BY VALUES');
				IF REPEAT_I THEN
				REPEAT+1;

        	CONVERTED_I=INDEX(UPCASE(LINE), 'CONVERTED');
				IF CONVERTED_I THEN
				CONVERTED+1;

	    	MISSING_I = INDEX(UPCASE(LINE), 'MISSING');
				IF MISSING_I THEN
				MISSING+1;

		END;

/*----------------------------------------------------------------------*/ 
/*  CREATE MACRO VARAIBLES FOR REPORTING LATER                          */
/*----------------------------------------------------------------------*/
		CALL SYMPUTX('ERROR',ERROR);
		CALL SYMPUTX('WARNING',(WARNING-LICENSE));
		CALL SYMPUTX('LICENSE',LICENSE);
		CALL SYMPUTX('UNINIT',UNINIT);
		CALL SYMPUTX('REPEAT',REPEAT);
		CALL SYMPUTX('CONVERTED',CONVERTED);
		CALL SYMPUTX('MISSING',MISSING);

	RUN;

/*----------------------------------------------------------------------*/ 
/*  REVIEW THE JOB LOG FOR PROGRAM SPECIFIC ALERTS. GET COUNTS OF THE   */
/* 	DATASETS THAT WERE CREATED FOR VALIDATION PURPOSES. THE LIST OF     */
/* 	DATASETS CAN VARY BASED ON THE PROGRAM EXECUTED.                    */
/*----------------------------------------------------------------------*/

	%IF %UPCASE("&ME_OR_NME.") = "MECOMP" %THEN %DO;

   		%CMAC1_COUNTER (DATASET = NEGDATA_CM, MVAR=NEGDATA_CM);
   		%CMAC1_COUNTER (DATASET = OUTDATES_CM, MVAR=OUTDATES_CM);
   		%CMAC1_COUNTER (DATASET = NOCOST, MVAR=NOCOST);
   		%CMAC1_COUNTER (DATASET = FAIL, MVAR=FAIL);
   		%CMAC1_COUNTER (DATASET = NOCOMP, MVAR=NOCOMP);
   		%CMAC1_COUNTER (DATASET = NEGDATA_DS, MVAR=NEGDATA_DS);
   		%CMAC1_COUNTER (DATASET = OUTDATES_DS, MVAR=OUTDATES_DS);

	%END;

	%ELSE %IF %UPCASE("&ME_OR_NME.") = "MEMARG" %THEN %DO;

   		%CMAC1_COUNTER (DATASET = NEGDATA_US, MVAR=NEGDATA_US);
   		%CMAC1_COUNTER (DATASET = OUTDATES_US, MVAR=OUTDATES_US);
   		%CMAC1_COUNTER (DATASET = NOCOST, MVAR=NOCOST);
   		%CMAC1_COUNTER (DATASET = NOFMGDATA, MVAR=NOFMGDATA);
   		%CMAC1_COUNTER (DATASET = NORATES, MVAR=NORATES);
   		%CMAC1_COUNTER (DATASET = NO_DP_REGION_TEST, MVAR=NO_DP_REGION_TEST);
   		%CMAC1_COUNTER (DATASET = NO_BASE_GROUP, MVAR=NO_BASE_GROUP);
		%CMAC1_COUNTER (DATASET = NO_DP_PURCHASER_TEST, MVAR=NO_DP_PURCHASER_TEST);
   		%CMAC1_COUNTER (DATASET = NO_DP_PERIOD_TEST, MVAR=NO_DP_PERIOD_TEST);
	
	%END;

	%ELSE %IF %UPCASE("&ME_OR_NME.") = "NME" %THEN %DO;

   		%CMAC1_COUNTER (DATASET = NEGDATA, MVAR=NEGDATA);
   		%CMAC1_COUNTER (DATASET = OUTDATES, MVAR=OUTDATES);
   		%CMAC1_COUNTER (DATASET = NOFOP, MVAR=NOFOP);
   		%CMAC1_COUNTER (DATASET = FAIL, MVAR=FAIL);
   		%CMAC1_COUNTER (DATASET = NOEXRATE, MVAR=NOEXRATE);
   		%CMAC1_COUNTER (DATASET = NEGATIVE_NVALUES, MVAR=NEGATIVE_NVALUES);
   		%CMAC1_COUNTER (DATASET = NEGATIVE_USPRICES, MVAR=NEGATIVE_USPRICES);
		%CMAC1_COUNTER (DATASET = NO_DP_REGION_TEST, MVAR=NO_DP_REGION_TEST);
   		%CMAC1_COUNTER (DATASET = NO_DP_PERIOD_TEST, MVAR=NO_DP_PERIOD_TEST);
   		%CMAC1_COUNTER (DATASET = NO_DP_PURCHASER_TEST, MVAR=NO_DP_PURCHASER_TEST);

	%END;

/*----------------------------------------------------------------------*/ 
/*  PRINTING SUMMARY OF GENERAL SAS ALERTS AS WELL AS PROGRAM SPECIFIC  */
/* 	ALERTS SUMMARY TO THE JOB LOG                                       */
/*----------------------------------------------------------------------*/

		%PUT ****************************************************;
		%PUT ****************************************************;
		%PUT GENERAL SAS ALERTS:                                 ;
		%PUT ****************************************************;
		%PUT # OF ERRORS                       = &ERROR;
		%PUT # OF WARNINGS                     = &WARNING;
		%PUT # OF UNINITIALIZED VARIABLES      = &UNINIT;
		%PUT # OF REPEATS OF BY VALUES         = &REPEAT;
		%PUT # OF CONVERTED VARIABLES          = &CONVERTED;
		%PUT # OF MISSING VALUES               = &MISSING;
		%PUT # OF LICENSE WARNINGS             = &LICENSE;
		%PUT ****************************************************;
		%PUT PROGRAM SPECIFIC (&ME_OR_NME.) ALERTS TO VERIFY:    ;
		%PUT ****************************************************;
		%PUT NORMALLY, COUNTS FOR THE BELOW LISTED DATATSETS HAVE;
		%PUT ZERO OBSERVATIONS. IF THEY DO NOT HAVE ZERO RECORDS ;
	    %PUT DETERMINE IF THERE IS AN ISSUE.                     ;
		%PUT ****************************************************;

	%IF %UPCASE("&ME_OR_NME.") = "MECOMP" %THEN %DO;

		%PUT # OF NEGDATA_CM RECORDS           = %CMPRES(&COUNT_NEGDATA_CM);
		%PUT # OF OUTDATES_CM RECORDS          = %CMPRES(&COUNT_OUTDATES_CM);
		%PUT # OF FAIL DATA RECORDS            = %CMPRES(&COUNT_FAIL);
		%PUT # OF NOCOST RECORDS               = %CMPRES(&COUNT_NOCOST);
		%PUT # OF NOCOMP RECORDS               = %CMPRES(&COUNT_NOCOMP);
		%PUT # OF NEGDATA_DS RECORDS           = %CMPRES(&COUNT_NEGDATA_DS);
		%PUT # OF OUTDATES_DS RECORDS          = %CMPRES(&COUNT_OUTDATES_DS);
		%PUT ******************************************************;
		%PUT ******************************************************;

	%END;

	%ELSE %IF %UPCASE("&ME_OR_NME.") = "MEMARG" %THEN %DO;

		%PUT # OF NEGDATA_US RECORDS           = %CMPRES(&COUNT_NEGDATA_US);
		%PUT # OF OUTDATES_US RECORDS          = %CMPRES(&COUNT_OUTDATES_US);
		%PUT # OF NOCOST RECORDS               = %CMPRES(&COUNT_NOCOST);
		%PUT # OF NOFMGDATA RECORDS            = %CMPRES(&COUNT_NOFMGDATA);
		%PUT # OF NORATES RECORDS              = %CMPRES(&COUNT_NORATES);
		%PUT # OF NO_DP_REGION_TEST RECORDS    = %CMPRES(&COUNT_NO_DP_REGION_TEST);
		%PUT # OF NO_BASE_GROUP RECORDS        = %CMPRES(&COUNT_NO_BASE_GROUP);
		%PUT # OF NO_DP_PURCHASER_TEST RECORDS = %CMPRES(&COUNT_NO_DP_PURCHASER_TEST);
		%PUT # OF NO_DP_PERIOD_TEST RECORDS    = %CMPRES(&COUNT_NO_DP_PERIOD_TEST);
		%PUT ******************************************************;
		%PUT ******************************************************;

	%END;

	%ELSE %IF %UPCASE("&ME_OR_NME.") = "NME" %THEN %DO;

		%PUT # OF NEGDATA RECORDS             = %CMPRES(&COUNT_NEGDATA);
		%PUT # OF OUTDATES RECORDS            = %CMPRES(&COUNT_OUTDATES);
		%PUT # OF FAIL DATA RECORDS           = %CMPRES(&COUNT_FAIL);
		%PUT # OF NOFOP RECORDS               = %CMPRES(&COUNT_NOFOP);
		%PUT # OF NOEXRATE RECORDS            = %CMPRES(&COUNT_NOEXRATE);
		%PUT # OF NEGATIVE_NVALUES RECORDS    = %CMPRES(&COUNT_NEGATIVE_NVALUES);
		%PUT # OF NEGATIVE_USPRICES RECORDS   = %CMPRES(&COUNT_NEGATIVE_USPRICES);
		%PUT # OF NO_DP_REGION_TEST RECORDS   = %CMPRES(&COUNT_NO_DP_REGION_TEST);
		%PUT # OF NO_DP_PERIOD_TEST RECORDS   = %CMPRES(&COUNT_NO_DP_PERIOD_TEST);
		%PUT # OF NO_DP_PURCHASER RECORDS     = %CMPRES(&COUNT_NO_DP_PURCHASER_TEST);
		%PUT ******************************************************;
		%PUT ******************************************************;

	%END;
	

%MEND C_MAC2_READLOG;
