/***************************************************************************/
/*                         ANTIDUMPING MARKET-ECONOMY                      */
/*                             MARGIN CALCUALTION                          */
/*                                                                         */
/*                   LAST PROGRAM UPDATE SEPTEMBER 15, 2016                */
/*                                                                         */
/* Part 1:  Database and General Program Information                       */
/* Part 2:  Bring In U.S. Sales, Convert Date Variable, If Necessary,      */
/*          Merge Exchange Rates Into Sales, If Required                   */
/* Part 3:  Cost Information                                               */
/* Part 4:  Calculate the Net U.S. Price                                   */
/* Part 5:  Convert Comparison Market Net Prices and Adjustments into CM   */
/*          Currency, If Required                                          */
/* Part 6:  Create Concordance of Price-To-Price Matching Instructions     */
/* Part 7:  Level of Trade Adjustment, If Required                         */
/* Part 8:  Combine U.S. Sales with CM Matches, Calculate Transaction-     */
/*          Specific Lot Adjustments, CEP and Commission Offsets           */
/* Part 9:  Calculate CEP and Commission Offsets For Constructed Value     */
/*          Comparisons                                                    */
/* Part 10: Combine Price-2-Price Comparisons with Sales Compared To CV    */
/* Part 11: Cohen's-d Test                                                 */
/* Part 12: Weight Average U.S. Sales                                      */
/* Part 13: Calculate FUPDOL, NV, PUDD, Etc. Using the Standard Method,    */
 /*         the A-to-T Alternative Method and, When Required, the Mixed    */
/*          Alternative Method                                             */
/* Part 14: Cash Deposit Rates                                             */
/* Part 15: Meaningful Difference Test                                     */
/* Part 16: Assessment Rates (Administrative Reviews Only)                 */
/* Part 17: Reprint the Final Cash Deposit Rate                            */
/* Part 18: Delete All Work Files in the SAS Memory Buffer, If Desired     */
/* Part 19: Calculate Run Time for This Program, If Desired                */
/***************************************************************************/

/*---------------------------------------------------------------------*/
/*    EDITING THE PROGRAM:                                             */
/*                                                                     */
/*          Places requiring edits are indicated by angle brackets     */
/*          (i.e., '< >'). Replace angle brackets with case-specific   */
/*          information.                                               */
/*                                                                     */
/*          Types of Inputs:(D) = SAS dataset name                     */
/*                          (V) = Variable name                        */
/*                          (T) = Text (no specific format),           */
/*                                do NOT use punctuation marks         */
/*---------------------------------------------------------------------*/

/*---------------------------------------------------------------------*/
/*     EXECUTING/RUNNING THE PROGRAM:                                  */
/*                                                                     */
/*          In addition to executing the entire program, you can do    */
/*          partial runs. Executable points from which you can         */
/*          partially run the program are indicated by '/*ep*' on      */
/*          the left margin. To do a partial run, just highlight the   */
/*          program from one of the executable points to the top,      */
/*          then submit it.                                            */
/*---------------------------------------------------------------------*/

/*------------------------------------------------------------*/
/* NAME OF PROGRAMMER: <Case Analyst Name>                    */ /*(T)*/
/*                                                            */
/* PROGRAM NAME:       <Program Name>                         */ /*(T)*/
/* PROGRAM LOCATION:   <C:\>                                  */ /*(T)*/
/*------------------------------------------------------------*/

/************************************************************************/
/* PART 1: DATABASE AND GENERAL PROGRAM INFORMATION                     */
/************************************************************************/

/*------------------------------------------------------------------*/
/* 1-A:     PROCEEDING TYPE                                         */
/*------------------------------------------------------------------*/

%LET CASE_TYPE = <AR/INV>;  /*(T) For an investigation, type 'INV' */
                            /*    (without quotes)                 */
                            /*    For an administrative review,    */
                            /*    type 'AR' (without quotes)       */

/*----------------------------------------------------------------------*/
/* 1-B: DATE INFORMATION                                                */
/*                                                                      */
/*          Dates should be in SAS DATE9 format (e.g., 01JAN2010).      */
/*                                                                      */
/*      FOR INVESTIGATIONS: BEGINDAY and ENDDAY usually correspond      */
/*          to the first and last dates of the POI.                     */
/*      FOR REVIEWS: Adjust BEGINDAY and ENDDAY to match the first      */
/*          day of the first month and the last day of the last month   */
/*          of the window period, respectively, covering all U.S. sale  */
/*          dates. Reported CEP sales usually include all sales during  */
/*          the POR. For EP sales, they usually include all entries     */
/*          during the POR. Accordingly, there may be U.S. sales        */
/*          transactions with sale dates prior to the POR. For example, */
/*          if the first EP entry in the POR was in June (first month   */
/*          of POR) but that entry had a sale date back in April, the   */
/*          window period would have to include the three months prior  */
/*          to April. February would then be the beginning of the       */
/*          window period.                                              */
/*                                                                      */
/*          TIME-SPECIFIC COMPARISONS: When making time-specific        */
/*          price-to-price comparisons of CM and US sales, comparisons  */
/*          are not made outside of designated time periods. In such    */
/*           cases, set BEGINWIN to the first day of the first time     */
/*          period. Likewise, set ENDDAY to the last day of the last    */
/*          time period.                                                */
/*----------------------------------------------------------------------*/

%LET BEGINDAY = <DDMONYYYY>;    /*(T) Day 1 of first month of U.S. sales   */
%LET ENDDAY   = <DDMONYYYY>;    /*(T) Last day of last month of U.S. sales */
%LET BEGINPERIOD = <DDMONYYYY>; /*(T) Day 1 of first month of official     */
                                /*    POI/POR.                             */

%LET BEGINWIN = <DDMONYYYY>;    /*(T) Day 1 of first month of window period*/
                                /*    in administrative reviews. Not       */
                                /*    required for investigations.         */

/*--------------------------------------------------------------*/
/* 1-B-ii:     ADDITIONAL FILTERING OF U.S. SALES, IF REQUIRED  */
/*                                                              */
/*  Should you additionally wish to filter U.S. sales using     */
/*  different dates and/or date variables for CEP v EP sales,   */
/*  complete the following section. This may be useful when     */
/*  you have both EP and CEP sales in an administrative review. */
/*  In reviews, reported CEP sales usually include all sales    */
/*  during the POR. For EP sales in reviews, reported sales     */
/*  usually include all entries during the POR. To filter EP    */
/*  sales by entry date, for example, you would put the first   */
/*  and last days of the POR for BEGINDAY_EP and ENDDAY_EP, and */
/*    the variable for date of entry under EP_DATE_VAR.         */
/*--------------------------------------------------------------*/

%LET FILTER_CEP = <YES/NO>;          /*(T) Additionally filter CEP sales?  */
                                     /*    Type "YES" (no quotes) to       */
                                     /*    filter, "NO" to skip this part. */
                                     /*    If you typed "YES," then also   */
                                     /*    complete the three subsequent   */
                                     /*    indented macro variables.       */
%LET    CEP_DATE_VAR = <  >;         /*(V) The date variable to be used to */
                                     /*    filter CEP sales                */
%LET    BEGINDAY_CEP = <DDMONYYYY>;  /*(T) Day 1 of 1st month of CEP U.S.  */
                                     /*    sales to be kept.               */
%LET    ENDDAY_CEP   = <DDMONYYYY>;  /*(T) Last day of last month of CEP   */
                                     /*    U.S. sales to be kept.          */

%LET FILTER_EP = <YES/NO>;           /*(T) Additionally filter EP sales?   */
                                     /*    Type "YES" (no quotes) to       */
                                     /*    filter, "NO" to skip this part. */
                                     /*    If you typed "YES," then also   */
                                     /*    complete the three subsequent   */
                                     /*    indented macro variables.       */
%LET    EP_DATE_VAR  = <  >;         /*(V) The date variable to be used to */
                                     /*    filter EP sales, such as,       */
                                     /*    entry date.                     */
%LET    BEGINDAY_EP  = <DDMONYYYY>;  /*(T) Day 1 of 1st month of EP U.S.   */
                                     /*    sales to be kept.               */
%LET    ENDDAY_EP    = <DDMONYYYY>;  /*(T) Last day of last month of EP    */
                                     /*    U.S. sales to be kept.          */

/*-------------------------------------------------------------------*/
/* 1-C: LOCATION OF DATA AND MACROS PROGRAM                          */
/*                                                                   */
/*     LIBNAME =      The name (i.e., COMPANY) and location of the   */
/*                 sub-directory containing the SAS datasets for     */
/*                    this program.                                  */
/*                                                                   */
/*     %INCLUDE =     Full path of the Macro Program for this case,  */
/*                    consisting of the sub-directory containing the */
/*                    Macro Program and its file name.               */
/*-------------------------------------------------------------------*/

LIBNAME COMPANY '<C:\....>';                 /* Location of company and  */
                                             /* exchange rate data sets. */
FILENAME MACR   '<C:\...\MacrosProgram.SAS'; /* Location & name of AD-ME */
                                             /* All Macros Program.      */
%INCLUDE MACR;                               /* Use the AD-ME All Macros */
                                             /* Program.                 */

/*-------------------------------------------------------------------------*/
/* 1-D: TITLES, FOOTNOTES AND AUTOMATIC NAMES FOR OUTPUT DATASETS          */
/*                                                                         */
/*        The information below will be used in creating titles, footnotes */
/*        and the names of output datasets for later use in the U.S. Sales */
/*        Margin Program.                                                  */
/*                                                                         */
/*          NAMES FOR OUTPUT DATASETS:                                     */
/*                                                                         */
/*      Names of all output datasets generated by this program will have a */
/*      standardized prefix using the format:  "RESPONDENT_SEGMENT_STAGE"  */
/*      in which:                                                          */
/*                                                                         */
/*         RESPONDENT  = Respondent identifier (e.g., company name)        */
/*         SEGMENT     = Segment of proceeding (e.g., INVEST, AR6, REMAND) */
/*         STAGE       = PRELIM or FINAL                                   */
/*                                                                         */
/*      The total number of places/digits used in the RESPONDENT, SEGMENT  */
/*      and STAGE identifiers, combined, should NOT exceed 21. Letters,    */
/*      numbers and underscores are acceptable. No punctuation marks,      */
/*      blank spaces or special characters should be used.                 */
/*                                                                         */
/*      The names of the output datasets this program creates, where       */
/*      applicable, are the following:                                     */
/*                                                                         */
/*          {RESPONDENT_SEGMENT_STAGE}_COST    = Wt-avg costs              */
/*          {RESPONDENT_SEGMENT_STAGE}_CMCEP   = CM revenue/expenses for   */
/*                                               CEP profit                */
/*          {RESPONDENT_SEGMENT_STAGE}_CVSELL  = Selling & profit ratios   */
/*                                               for CV                    */
/*          {RESPONDENT_SEGMENT_STAGE}_CMWTAV  = Wt-avg CM data            */
/*          {RESPONDENT_SEGMENT_STAGE}_LOTADJ  = LOT adjustment factors    */
/*                                                                         */
/*          All output datasets will be placed in the COMPANY directory.   */
/*-------------------------------------------------------------------------*/

%LET PRODUCT      = <  >;     /*(T) Product */
%LET COUNTRY      = <  >;     /*(T) Country */

/*------------------------------------------------------------------------*/
/* Between the RESPONDENT, SEGMENT and STAGE macro variables below, there */
/* should be a maximum of 21 digits.                                      */
/*------------------------------------------------------------------------*/

%LET RESPONDENT = <  >;  /*(T) Respondent identifier. Use only letters,   */
                         /*    numbers and underscores.                   */
%LET SEGMENT    = <  >;  /*(T) Segment of the proceeding, e.g., Invest,   */
                         /*    AR1, Remand. Use only letters, numbers     */
                         /*    and underscores.                           */
%LET STAGE      = <  >;  /*(T) Stage of proceeding, e.g., Prelim, Final,  */
                         /*    Remand. Use only letters, numbers and      */
                         /*    underscores.                               */

/*-------------------------------------------------------------------*/
/* 1-E: DATABASE INFORMATION FOR U.S. & CM SALES, COSTS AND          */
/*          EXCHANGE RATES                                           */
/*                                                                   */
/*     Where information may not be relevant (e.g., re: manufacturer */
/*     and prime/non-prime merchandise), 'NA' (not applicable) will  */
/*     appear as the default value.                                  */
/*-------------------------------------------------------------------*/

/*--------------------------------------------------------------*/
/*     1-E-i. EXCHANGE RATE INFORMATION:                        */
/*                                                              */
/*          If, for example, you are using Mexican pesos, type  */
/*          %LET EXDATA1 = MEXICO immediately following. Then,  */
/*          in your programming later on, you would use any of  */
/*          the following methods to refer that exchange rate:  */
/*                                                              */
/*               EXRATE_MEXICO or                               */
/*               &EXRATE1 or                                    */
/*               EXRATE_&EXDATA1                                */
/*                                                              */
/*          Use EXDATA1     for the CM currency, when required. */
/*          It is &EXRATE1 that is used to convert costs and    */
/*          the CM net price into U.S. dollars.                 */
/*                                                              */
/*          In the event either exchange rate is not required,  */
/*          dummy variables with neutral values are created.    */
/*          (See section 4-A below.)                            */
/*--------------------------------------------------------------*/

%LET USE_EXRATES1 = <YES/NO>;  /*(T) Use exchange rate #1? Type "YES" or */
                               /*    "NO" (without quotes).              */
%LET     EXDATA1   = <  >;     /*(D) Exchange rate dataset name.         */

%LET USE_EXRATES2 = <YES/NO>;  /*(T) Use exchange rate #2? Type "YES" or */
                               /*  "NO" (without quotes).                */
%LET     EXDATA2   = <  >;     /*(D) Exchange rate dataset name.         */

/*--------------------------------------------------------------*/
/* 1-E-ii. U.S. SALES INFORMATION                               */
/*--------------------------------------------------------------*/

%LET USDATA      = <  >;   /*(D) U.S. sales dataset filename.            */
%LET     USCONNUM = <  >;  /*(V) Control number                          */
%LET     USCVPROD = <  >;  /*(V) Variable (usually CONNUMU) linking      */
                           /*    sales to cost data.                     */
%LET     USCHAR   = <  >;  /*(V) Product matching characteristics. List  */
                           /*    them from left to right importance,     */
                           /*    with no punctuation separating them.    */
%LET     SALETYPE = <  >;  /*(V/T) Variable indicating type of U.S. sales*/
                           /*      (EP vs. CEP), if any. If there is no  */
                           /*      variable and U.S. sales are all       */
                           /*      of one type, then type either EP or   */
                           /*      CEP (without quotes) to indicates     */
                           /*      which type.                           */
%LET     USDATE   = <  >;  /*(V) Sale date                               */
%LET     USQTY    = <  >;  /*(V) Quantity                                */
%LET     USGUP    = <  >;  /*(V) Gross price. Need not be in consistent  */
                           /*    currency, used only to check for zero,  */
                           /*    negative and missing values.            */
%LET     USLOT    = <NA>;  /*(V) Level of trade. If not reported in the  */
                           /*    database and not required, type "NA"    */
                           /*    (without quotes). You may also type     */
                           /*    "NA" if CM & US both have only 1 LOT    */
                           /*    and those LOTs are the same.            */
%LET     USMANUF  = <NA>;  /*(V) Manufacturer code. If not applicable,   */
                           /*    type "NA" (without quotes).             */
%LET     ENTERVAL = <NA>;  /*(V) Variable for reported entered value. If */
                           /*    there is no variable, type "NA" (without*/
                           /*    quotes.)                                */
%LET     IMPORTER = <NA>;  /*(V) Variable for U.S. importer. If there    */
                           /*    is no variable and there is only one    */
                           /*    importer, type "NA" (without quotes.)   */
%LET     USPRIME  = <NA>;  /*(V) Prime/seconds code. If not applicable,  */
                           /*    type "NA" (without quotes).             */
%LET     EX1_VARS = <NA>;  /*(V) Variables in EXDATA1 currency to be     */
                           /*    converted into U.S. dollars, including  */
                           /*    packing. If not applicable, type "NA"   */
                           /*    (without quotes). The converted         */
                           /*    variables in U.S. dollars will have the */
                           /*    names of the old ones with the suffix   */
                           /*    '_USD' added.                           */
%LET     EX2_VARS = <NA>;  /*(V) Variables in EXDATA2 currency to be     */
                           /*    converted into U.S. dollars, including  */
                           /*    packing. If not applicable, type "NA"   */
                           /*    (without quotes). The converted         */
                           /*    variables in U.S. dollars will have the */
                           /*    names of the old ones with the suffix   */
                           /*    '_USD' added.                           */

/*-----------------------------------------------------------------*/
/* 1-E-ii-b. COHEN'S-D TEST                                        */
/*                                                                 */
/*     Normally, the regions will correspond to the 5 Census       */
/*     regions:  Northeast, Midwest, South, West, and Puerto Rico. */
/*     (Do not include U.S. Territories other than Puerto Rico     */
/*     because they are not in the Customs Territory of the U.S.)  */
/*                                                                 */
/*     If you have a region variable, type DP_REGION_DATA=REGION   */
/*     and then specify the region variable in DP_REGION=???.      */
/*     Please note that any unknown regions should be listed as    */
/*     blank spaces and not, for example, as "UNKNOWN" or "UNK."   */
/*                                                                 */
/*     If you instead have a variable that has either the 2-digit  */
/*     postal state code or the zip code (5 or 9 digits), then     */
/*     indicate the same below by typing DP_REGION_DATA=STATE or   */
/*     DP_REGION_DATA=ZIP. If you need to write your own language  */
/*     to create the Census regions, do so in Sect. 2-B below      */
/*     re: changes and edits to the U.S. database.                 */
/*                                                                 */
/*     If you have any unknown purchasers/customers, they should   */
/*     be reported as blank spaces and not, for example, as        */
/*     "UNKNOWN" or "UNK." If this is not the case, please edit    */
/*     the data accordingly.                                       */
/*                                                                 */
/*     Usually, time periods for purposes of the Cohen's-d Test    */
/*     will be defined by quarters, beginning with the first month */
/*     of POI/POR as found in the BEGINPERIOD macro variable       */
/*     defined above in Sect.1-B-i. If you wish to use quarters    */
/*     and do not have a variable for the same, type               */
/*     DP_TIME_CALC=YES and the program will use the sale date     */
/*     variable to assign quarters. If you already have a          */
/*     variable for quarters or are using something other than     */
/*     quarters, type DP_TIME_CALC=NO and also indicate the        */
/*     variable containing the time periods in DP_TIME=???.        */
/*-----------------------------------------------------------------*/

%LET DP_PURCHASER = <  >;                 /*(V) Variable indicating       */
                                          /*    customer for purposes of  */
                                          /*    the DP analysis.          */
%LET DP_REGION_DATA = <REGION/STATE/ZIP>; /*(T) Type either "REGION,"     */
                                          /*    "STATE" or "ZIP" (without */
                                          /*    quotes) to indicate the   */
                                          /*    type of data being used   */
                                          /*    to assign Census regions. */
                                          /*    Then complete the         */
                                          /*    DP_REGION macro           */
                                          /*    variable immediately      */
                                          /*    following.                */
%LET      DP_REGION = <  >;               /*(V) Variable indicating the   */
                                          /*    DP region if you typed    */
                                          /*    "REGION" for              */
                                          /*    DP_REGION_DATA, or the    */
                                          /*    variable indicating the   */
                                          /*    2-digit postal state      */
                                          /*    designation if you typed  */
                                          /*    "STATE," or the variable  */
                                          /*    indicating the 5-digit zip*/
                                          /*    code if you typed "ZIP."  */
%LET DP_TIME_CALC = <YES/NO>;             /*(T) Type "YES" (without       */
                                          /*    quotes)to assign quarters */
                                          /*    using the beginning of    */
                                          /*    the period.               */
%LET      DP_TIME = <  >;                 /*(V) If you typed "NO" for     */
                                          /*    DP_TIME_CALC because you  */
                                          /*    already have a variable   */
                                          /*    for the DP time period,   */
                                          /*    indicate that variable    */
                                          /*    here.                     */

/*---------------------------------------------------------------*/
/* 1-E-iii. CONSTRUCTED VALUE DATA                               */
/*                                                               */
/*     If the respondent has reported both a CM COP database and */
/*     a U.S. CV database, it is best to combine them in the CM  */
/*     program and calculate one weight-averaged cost database.  */
/*---------------------------------------------------------------*/

%LET      COST_TYPE = <CM/CV>;  /*(T) Type "CM" (without quotes) when    */
                                /*    pulling costs from the CM program. */
                                /*    Type "CV" (without quotes) when    */
                                /*    calculating CV in this Margin      */
                                /*    program.                           */

/*-------------------------------------------------------------*/
/*     1-E-iii-a. COST DATA PREVIOUSLY GENERATED IN CM PROGRAM */
/*                                                             */
/*     If you typed COST_TYPE=CM above because you have cost   */
/*     data coming from the CM program, complete this section. */
/*     You do not have to complete Sect. 1-E-iii-b re: CV data */
/*     only for U.S. sales.                                    */
/*-------------------------------------------------------------*/

%LET COP_MANUF = <YES/NO>;      /*(V) Is there is manufacturer variable  */
                                /*    in the cost database coming from   */
                                /*    the CM program?  Type "YES" or     */
                                /*    no (without quotes).               */

/*-------------------------------------------------------------*/
/*     1-E-iii-b. CV DATA ONLY FOR U.S. SALES                  */
/*                                                             */
/*     If you type COST_TYPE=CV above in Sect. 1-E-iii because */
/*     you do NOT have cost data coming from the CM program    */
/*     AND you have a cost database for use only with U.S.     */
/*     sales, complete this section. Also complete sections    */
/*     1-E-iii-b-1 (re: surrogate costs) and 1-E-vi-a          */
/*     (re: time-specific CV calculations), if applicable.     */
/*-------------------------------------------------------------*/

%LET COST_DATA  = <  >;  /*(D) Cost data set                               */
%LET COST_MATCH = <  >;  /*(V) The variable (usually CONNUM)               */
                         /*    linking cost data to sales data.            */
%LET COST_QTY = <  >;    /*(V) Production quantity                         */
%LET COST_MANUF = <NA>;  /*(V) Manufacturer code. If not applicable, type  */
                         /*    "NA" (without quotes).                      */

/*---------------------------------------------------------*/
/* 1-E-iii-b-1. SURROGATE COSTS FOR NON-PRODUCTION         */
/*                                                         */
/*     Complete the following section if you have products */
/*     that were sold but not produced during the period,  */
/*     and those products do not already have adequate     */
/*     surrogate cost information reported.                */
/*---------------------------------------------------------*/

%LET MATCH_NO_PRODUCTION= <YES/NO>; /*(T) Find surrogate costs for products*/
                                    /*    not produced during the POR?     */
                                    /*    Type "YES" or "NO" (without      */
                                    /*    quotes). If "YES," complete      */
                                    /*    the indented macro variables     */
                                    /*    that follow.                     */
%LET   COST_PROD_CHARS = <YES/NO>;  /*(T) Are the product physical         */
                                    /*    characteristic variables in the  */
                                    /*    cost database? Type "YES" or     */
                                    /*    "NO" without quotes).            */
%LET   COST_CHAR = <  >;            /*(V) Product matching characteristics */
                                    /*    in cost data. List them from     */
                                    /*    left-to-right in order of        */
                                    /*    importance, with no punctuation  */
                                    /*    separating them.                 */

/*-------------------------------------------*/
/* 1-E-iv. NORMAL VALUE PREFERENCE SELECTION */
/*-------------------------------------------*/

%LET NV_TYPE = <P2P/CV>;  /*(T) Type "P2P" (without quotes) if you have CM */
                          /*    data for price-to-price comparisons. Sales */
                          /*    not finding a price-to-price comparison    */
                          /*    will then be matched to CV. Type "CV"      */
                          /*    (without quotes) to compare U.S. sales     */
                          /*    directly to CV.                            */

/*----------------------------------------------------------------*/
/*     1-E-v. COMPARISON MARKET INFORMATION                       */
/*                                                                */
/*     Complete the next section if you typed NV_TYPE=P2P above   */
/*     because you have CM sales for price-2-price comparisons.   */
/*                                                                */
/*     If information in the CM sales data is in more than one    */
/*     currency, type CM_MULTI_CUR=YES directly below. You will   */
/*     then also have to edit Part 5 below to (re)calculate the   */
/*     CM net price, etc., using currency conversions on the date */
/*     of the U.S. sale.                                          */
/*----------------------------------------------------------------*/

%LET CMMANUF = <YES/NO>;      /*(T) Is there a CM manufacturer variable? */
                              /*    Type "YES" or "NO" (without quotes). */
%LET CMPRIME = <YES/NO>;      /*(T) Is there a CM prime variable? Type   */
                              /*    "YES" or "NO" (without quotes).      */
%LET CMCHAR = <  >;           /*(V) Product matching characteristics.    */
                              /*    List them from left to right         */
                              /*    in order of importance, with no      */
                              /*    punctuation separating them.         */
%LET CM_MULTI_CUR = <YES/NO>; /*(T) Is CM data in more than one          */
                              /*    currency? Type "YES" or "NO"         */
                              /*    (without quotes).                    */

/*-----------------------------------------------------------------*/
/* 1-E-vi. TIME-SPECIFIC COMPARISONS                               */
/*                                                                 */
/*     To restrict sales comparisons and the calculation of costs  */
/*     to within designated time periods, type COMPARE_BY_TIME=YES */
/*     and complete the rest of Section 1-E-vi. If, instead, you   */
/*     type COMPARE_BY_TIME=NO, you can ignore the rest of         */
/*     Section 1-E-vi.                                             */
/*                                                                 */
/*     If you have sales and cost data coming from the CM program, */
/*     those, too, should be calculated on a time-specific         */
/*     basis when making comparisons to U.S. sales based on time.  */
/*                                                                 */
/*     Note: You do not need a separate cost database to restrict  */
/*     sales comparison to within time periods. However, the VCOMs */
/*     and TCOMs in the sales databases should also be calculated  */
/*     on a time-specific basis.                                   */
/*-----------------------------------------------------------------*/

%LET COMPARE_BY_TIME = <YES/NO>;  /*(T) Do you have time-specific  */
                                  /*    costs? Type "YES" or "NO"  */
                                  /*    (without quotes). If       */
                                  /*    "YES,"then also complete   */
                                  /*    Sect. 1-E-iii-b-1 below.   */
%LET US_TIME_PERIOD  = <  >;      /*(V) Variable in U.S. data for  */
                                  /*    cost-related time periods, */
                                  /*    if applicable.             */

/*-------------------------------------------------------------*/
/* 1-E-vi-a. TIME-SPECIFIC CONSTRUCTED VALUE CALCULATIONS      */
/*                                                             */
/*     Complete this section if you type all of the following: */
/*          COST_TYPE           = CV  (Sect. 1-E-iii)          */
/*          COMPARE_BY_TIME     = YES (immediately above)      */
/*-------------------------------------------------------------*/

%LET COST_TIME_PERIOD = <  >;          /*(V) Variable in cost data for     */
                                       /*    time periods                  */
%LET INDEX_SOURCE = <CALC/INPUT/RESP>; /*(T) Type "CALC" (without quotes)  */
                                       /*    to calculate indices within   */
                                       /*    this program. Also complete   */
                                       /*    Sect. 3-D-ii-b. Type "INPUT"  */
                                       /*    (without quotes) to input     */
                                       /*    supplied indices. Also        */
                                       /*    complete Sect. 3-D-ii-a. Type */
                                       /*    "RESP" (without quotes) if    */
                                       /*    respondent has already done   */
                                       /*    the indexing.                 */
%LET TIME_INSIDE_POR = <  >;           /*(T) List of values of             */
                                       /*    &COST_TIME_PERIOD variable    */
                                       /*    for periods during the        */
                                       /*    accounting period, separated  */
                                       /*    by commas, quotes around      */
                                       /*    character data. E.g., "Q1",   */
                                       /*    "Q2", "Q3", "Q4".             */
%LET TIME_OUTSIDE_POR = <  >;          /*(T) List of values of             */
                                       /*    &COST_TIME_PERIOD variable    */
                                       /*    for periods outside of the    */
                                       /*    accounting period, separated  */
                                       /*    by commas, quotes around      */
                                       /*    character data. E.g., "Q5",   */
                                       /*    "Q6". If there are only       */
                                       /*    periods inside the accounting */
                                       /*    period, type "NA" (without    */
                                       /*    quotes)                       */
%LET TIME_ANNUALIZED = <NA>;           /*(T) List of values of             */
                                       /*    &COST_TIME_PERIOD variable    */
                                       /*    for products that have        */
                                       /*    annualized, i.e., NOT time-   */
                                       /*    specific) costs, separated by */
                                       /*    commas, quotes around         */
                                       /*    character data, e.g., "POR".  */
                                       /*    If not applicable, type "NA"  */
                                       /*    (without quotes).             */

/*------------------------------------------------------------------*/
/* 1-F: CONDITIONAL PROGRAMMING OPTIONS:                            */
/*------------------------------------------------------------------*/

%LET LOT_ADJUST = <NO/CM/INPUT>;  /*(T) Type "NO" (without quotes) when    */
                                  /*    not making an LOT adjustment. Type */
                                  /*    "CM" (without quotes) if using     */
                                  /*    info. from CM sales. Type "INPUT"  */
                                  /*    (without quotes) if using info.    */
                                  /*    from a source other than CM sales. */
                                  /*    If you typed "INPUT," then also    */
                                  /*    complete Sect. 7-A-i below.        */
%LET CEPROFIT = <CALC/INPUT>;     /*(T) Type "CALC" (without quotes) to    */
                                  /*    use CM and U.S. expense and        */
                                  /*    revenue data. You must have a cost */
                                  /*    database if you type "CALC." Type  */
                                  /*    "INPUT" (without quotes) to supply */
                                  /*    an alternative CEP profit rate     */
                                  /*    when not calculating the same.     */
%LET CEPRATE = <  >;              /*(T) If you typed "LET CEPROFIT=INPUT"  */
                                  /*    directly above, the alternative    */
                                  /*    CEP profit rate in decimal form.   */
%LET ALLOW_CEP_OFFSET = <YES/NO>; /*(T) Allow CEP offset? Type "YES" or    */
                                  /*    "NO" (without quotes).             */
%LET CVSELL_TYPE = <CM/OTHER>;    /*(T) Type "CM" (without quotes) when    */
                                  /*    using CM selling & profit info.    */
                                  /*    Type "OTHER" (without quotes)      */
                                  /*    if using info. from a source       */
                                  /*    other than CM sales.               */
                                  /*    If you typed "OTHER," then also    */
                                  /*    complete Sect. 8-B below. This     */
                                  /*    macro variable is required only    */
                                  /*    if you will have CV comparisons.   */
%LET PER_UNIT_RATE = <YES/NO>;    /*(T) Only print per-unit (and not ad    */
                                  /*    valorem) cash deposit and, if      */
                                  /*    applicable, assessment rates even  */
                                  /*    when entered values are reported?  */
                                  /*    Type "YES" or "NO" (without quotes)*/

/*------------------------------------------------------------------*/
/* 1-G: FORMAT, PROGRAM AND PRINT OPTIONS                           */
/*------------------------------------------------------------------*/

OPTIONS PAPERSIZE = LETTER;
OPTIONS ORIENTATION = LANDSCAPE;
OPTIONS TOPMARGIN = ".25IN"
        BOTTOMMARGIN = ".25IN"
        LEFTMARGIN = ".25IN"
        RIGHTMARGIN = ".25IN";

/*-------------------------------------------------------------*/
/* 1-G-i Options that usually do not require edits.            */
/*-------------------------------------------------------------*/

/*-------------------------------------------------------------*/
/*     1-G-i-a Printing Formats                                */
/*                                                             */
/*  In sections where a large number of observations may       */
/*  print, the program limits the number of observations       */
/*  to 25, by default. To change this, adjust the PRINTOBS     */
/*  number below.                                              */
/*                                                             */
/*     By editing the default formats used below, you can      */
/*     change the way values are displayed when the formats    */
/*     are used. When you increase the number of decimals      */
/*     (the number to the right of the decimal in the format), */
/*     you must also increase the maximum number of places     */
/*     displayed, which is the number to the left of the       */
/*     decimal. (Commas, decimal points, dollar signs, percent */
/*     symbols, etc. all occupy space.)  For example, the      */
/*     COMMA12.2 format looks like '1,000,000.00' To display   */
/*     four decimal places you would type "COMMA14.4"          */
/*-------------------------------------------------------------*/

%LET PRINTOBS = 25;               /*(T) Number of obs to print on     */
                                  /*    statements that are sampled.  */
%LET COMMA_FORMAT = COMMA12.2;    /* Comma format using 12 total      */
                                  /* spaces and two decimal places.   */
%LET DOLLAR_FORMAT = DOLLAR12.2;  /* Dollar format using 12 total     */
                                  /* spaces and two decimal places.   */
%LET PERCENT_FORMAT = PERCENT8.2; /* Percent format using seven total */
                                  /* spaces and two decimal places.   */

/*----------------------------------------------------------*/
/*     1-G-i-b Programming Options                          */
/*----------------------------------------------------------*/

%LET DEL_WORKFILES = NO; /*(T) Delete all work library files?  Default    */
                         /*    is NO. If you type "YES" (without          */
                         /*    quotes), you may increase program speed,   */
                         /*    but will not be able examine files in      */
                         /*    the work library for diagnostic purposes.  */
%LET CALC_RUNTIME = YES; /*(T) Calculate program run time? If you don't   */
                         /*    like to see this info., type "NO" (without */
                         /*    quotes)                                    */
OPTIONS NOSYMBOLGEN;     /* SYMBOLGYN prints macro variable resolutions.  */
                         /* Reset to "NOSYMBOLGEN" (without quotes) to    */
                         /* deactivate.                                   */
OPTIONS MPRINT;          /* MPRINT prints macro resolutions, type         */
                         /* "NOMPRINT" (without quotes) to deactivate.    */
OPTIONS NOMLOGIC;        /* MLOGIC prints additional info. on macros,     */
                         /* type "MLOGIC" (without quotes) to activate.   */
OPTIONS MINOPERATOR;     /* MINOPERATOR is required when using the IN(..) */
                         /* function in macros.                           */
OPTIONS OBS = MAX;       /* Indicates the number of OBS to process in each*/
                         /* data set. Default setting of MAX processes all*/
                         /* transactions. If you have large datasets and  */
                         /* initially wish to debug the program using a   */
                         /* limited number of transactions, you can reset */
                         /* this option by typing in a number.            */
OPTIONS NODATE PAGENO = 1 YEARCUTOFF = 1960;
OPTIONS FORMCHAR = '|----|+|---+=|-/\<>*';

/*------------------------------------------------------------------*/
/* 1-H:      GENERATE PROGRAM-SPECIFIC TITLES, FOOTNOTES            */
/*               AND MACROS NEEDED TO EXECUTE THE PROGRAM.          */
/*------------------------------------------------------------------*/

%LET SALESDB = USSALES; 
%G1_RUNTIME_SETUP
%G2_TITLE_SETUP     
%G3_COST_TIME_MVARS     

/*----------------------------------------------------------------------*/
/* 1-I: PRIME AND MANUFACTURER MACROS AND MACRO VARIABLES               */
/*                                                                      */
/*                                                                      */
/*     In the programming language, the macro variables &USPRIM,        */
/*     &SALES_COST_MANF (for merging sales with costs), &USMANF         */
/*     (for merging U.S. sales with CM sales for P2P comparisons),      */
/*     &CMPRIM, &CM_P2P_MANF and &CVMANF are used. Their values         */
/*     are determined by the answers in Sect. 1-E above.                */
/*                                                                      */
/*     If you type %LET USMANUF=NA, then the manufacturer-related       */
/*     macro variables for U.S. sales (&US_COST_MANF and &USMANF        */
/*     will be set to null/blank values. Since you need manufacturer    */
/*     designations in both U.S. & CM sales for them to merge by        */
/*     manufacturer, &CM_P2P_MANF will also be set to a null/blank      */
/*     value. Similarly, &COST_MANF will be set to null/blank values    */
/*     if %LET USMANUF=NA. Otherwise, &US_COST_MANF and &USMANF         */
/*     will be set to the variable indicated by %LET USMANUF=<???>      */
/*     when manufacturer is also relevant for cost and CM sales,        */
/*     respectively.                                                    */
/*                                                                      */
/*     If you type %LET CMMANUF=NO, then &CM_P2P_MANF will be set to    */
/*     a null/blank value as will &USMANF. Otherwise, &CMMANF           */
/*     will be equal to CMMANF, the standardized variable name          */
/*     assigned in the CM program, as long as U.S. manufacturer is      */
/*     also relevant.                                                   */
/*                                                                      */
/*     Similarly, &USPRIM and &CMPRIM will be set to null/blank values  */
/*     if you type either %LET USPRIME=NA or %LET CMPRIME=NA.           */
/*     Otherwise, they will be set to the variables indicated in        */
/*     %LET USPRIME=<???> and %LET CMPRIME=<???> when prime is          */
/*     relevant for both U.S. and CM sales.                             */
/*----------------------------------------------------------------------*/

%US1_MACROS 

/***************************************************************************/
/* PART 2: BRING IN U.S. SALES, CONVERT DATE VARIABLE, IF NECESSARY, MERGE */
/*         EXCHANGE RATES INTO SALES, IF REQUIRED.                         */
/***************************************************************************/

/*----------------------------------------------------------------------*/
/* 2-A: BRING IN U.S. SALES DATA                                        */
/*                                                                      */
/*          Alter the SET statement, if necessary, to bring in more     */
/*          than one SAS database. If you need to rename variables,     */
/*          change variables from character to numeric (or vice versa), */
/*          in order to do align the various databases, make such       */
/*          changes here.                                               */
/*                                                                      */
/*          Changes to U.S. data using exchange rates and costs should  */
/*          wait until Part 4, below, after the cost and exchange rate  */
/*          databases are attached.                                     */
/*                                                                      */
/*          Leave the data step open through the RUN statement          */
/*          following the execution of the US2_SALETYPE macro in        */
/*          Sect. 2-D.                                                  */
/*----------------------------------------------------------------------*/

DATA USSALES;
    SET COMPANY.&USDATA;

/*------------------------------------------------------------------*/
/* 2-B: Insert and annotate any changes below.                      */
/*------------------------------------------------------------------*/

    /* Insert changes here */

/*---------------------------------------------------------------------*/
/* 2-C: LEVEL OF TRADE                                                 */
/*                                                                     */
/*      The variable USLOT will be created containing the levels       */
/*          of trade. It is this variable that is used in the          */
/*          programming. If you typed '%LET USLOT = NA' in             */
/*          Sect. 1-E-ii above, the variable USLOT will be set to 0    */
/*          (zero). Otherwise, USLOT will be set equal to the variable */
/*          specified in %LET USLOT = <???>.                           */
/*                                                                     */
/*           If you have a level of trade variable and need to make    */
/*       changes to its values, or you do not have one but need to     */
/*           create one, make those edits before the G4_LOT.           */
/*---------------------------------------------------------------------*/

    %G4_LOT(&USLOT,USLOT)

/*---------------------------------------------------------------------*/
/* 2-D: CREATE U.S. SALE TYPE PROGRAMMING VARIABLE                     */
/*                                                                     */
/*     The variable SALE_TYPE will be created, indicating whether U.S. */
/*     sales are EP or CEP. It is this variable that will be used in   */
/*     the programming language. If there is a variable already in     */
/*     the data and you typed %LET SALETYPE={{variable name}} in       */
/*     in Sect. I-E-ii above, SALE_TYPE will be set equal to that      */
/*     variable. If no variable exists in the reported data,           */
/*     SALE_TYPE will be set equal to "EP" if you typed                */
/*     %LET SALETYPE=EP, or "CEP" if you typed %LET SALETYPE=CEP.      */
/*---------------------------------------------------------------------*/

    %US2_SALETYPE
RUN;

/*ep*/

/*------------------------------------------------------------------*/
/* 2-E: TEST FORMAT OF DATE VARIABLE(s) AND CONVERT, WHEN NECESSARY */
/*                                                                  */
/*     This section tests the sale date variable and additional     */
/*     variables used to filter CEP and EP sales to see if they are */
/*     in SAS date format. If not, an attempt will be made to       */
/*     convert them using language that will work for many cases,   */
/*     but not all. Should the language not convert your data       */
/*     correctly, contact a SAS Support Team member for assistance. */
/*------------------------------------------------------------------*/

%G5_DATE_CONVERT

/*ep*/

/*-------------------------------------------------------------------*/
/* 2-F: CHECK FOR NEGATIVE AND MISSING DATA, AND FOR DATES           */
/*          OUTSIDE THE POI OR WINDOW. CREATE THE MONTH VARIABLE     */
/*          FOR AN ADMINISTRATIVE REVIEW.                            */
/*                                                                   */
/*          Sales with gross price or quantity variables that have   */
/*          missing values or values less than or equal to zero will */
/*          be taken out of the database only to make the program    */
/*          run smoothly. This is not a policy decision. You may     */
/*          have to make adjustments to such sales.                  */
/*                                                                   */
/*          Sales outside the POI (for an investigation) or POR      */
/*          (for administrative reviews) will be set aside.          */
/*                                                                   */
/*          In an administrative review, a month variable will be    */
/*          created giving each month in the window period a unique  */
/*          number. In the first calendar year of the review (as     */
/*          designated by the BEGINWIN macro variable), the value    */
/*          of USMONTH will be equal to the normal numeric month     */
/*          designation (e.g., Jan=1, Feb=2). In the second          */
/*          calendar year of the review, USMONTH will be equal to    */
/*          the numeric month designation + 12 (e.g., Jan=1+12=13).  */
/*          Similarly, in a third calendar year, USMONTH = month+24. */
/*-------------------------------------------------------------------*/

%G6_CHECK_SALES

/*ep*/

/*------------------------------------------------------------------*/
/* 2-G: MERGE IN EXCHANGE RATES, AS REQUIRED                        */
/*                                                                  */
/*          For both potential exchange rates in Sect. 1-E-i above, */
/*          macro variables with neutral values are first created.  */
/*          These neutral values will be over-written with actual   */
/*          exchange rate data, as required.                        */
/*------------------------------------------------------------------*/

%G7_EXRATES 

/*ep*/

/*---------------------------------------------------------------------*/
/* 2-H: CONVERT FOREIGN-CURRENCY VARIABLES INTO U.S. DOLLARS           */
/*                                                                     */
/*     New variables will be created, having the names of the old ones */
/*     with the suffix "_USD" added (<oldname>_USD), and set equal to  */
/*     the values of old variables multiplied by the indicated         */
/*     exchange rate. For example, if you type %LET EX1_VARS=DMOVEU,   */
/*     then DMOVEU_USD = DMOVEU*&EXRATE1.                              */
/*---------------------------------------------------------------------*/
 
%US3_USD_CONVERSION

/*ep*/

/***************************************************************************/
/* PART 3: COST INFORMATION                                                */
/*                                                                         */
/*          Determine whether information from the CM program, U.S. sales  */
/*          database or from a CV-only database will be used.              */
/*                                                                         */
/*          If the respondent has supplied separate COP and CV databases,  */
/*          combine them together in CM program in Sect. 3-A and make      */
/*          required adjustments, including indexing of inputs. The        */
/*          combined weight-averaged cost database calculated in CM        */
/*          Program can then also be used in this Margin Program with U.S. */
/*          sales. This is preferable to calculating the two separately.   */
/*                                                                         */
/*          When a CV-only database has been supplied, make required       */
/*          changes to items in the indicated sections below:              */
/*                                                                         */
/*          Sect. 3-A-i          Pre-indexing changes                      */
/*          Sect. 3-D-i          Indexed inputs                            */
/*          Sect. 3-D-ii-a     Time-specific indices                       */
/*          Sect. 3-E          Cost of manufacturing, G&A, interest, and   */
/*                              cost of production                         */
/***************************************************************************/

/*----------------------------------------------------------------------*/
/* 3-A     CALL UP CV DATABASE, IF PROVIDED. MAKE PRE-INDEXING          */
/*          ADJUSTMENTS TO INPUTS, MANUFACTURER, ETC.                   */
/*                                                                      */
/*          Calculate major input adjustments, if required, on inputs   */
/*          to be indexed. Make changes to cost inputs, manufacturer,   */
/*          etc., and any other edits here that need to be done before  */
/*          indexing is executed in Sect. 3-E. In order to keep         */
/*          track of pre-indexing information on inputs to be indexed   */
/*          and the final, indexed values of the same, do not add       */
/*          major input adjustments, for example, to the reported       */
/*          values here. Instead, make those calculation below in       */
/*          Sect. 3-D-i.                                                */
/*                                                                      */
/*          Do NOT make changes to GNA, INTEX or the calculation        */
/*          of TOTCOM here. Instead, do these below in Sect. 3-F,       */
/*          after indexing of inputs is completed.                      */
/*                                                                      */
/*          Also, do NOT reset missing or zero production quantities    */
/*          to positive values at this point with the exception noted   */
/*          in the next paragraph. The resetting of zero/missing        */
/*          production quantities before weight averaging will be done  */
/*          later in Sect. 3-E below.                                   */
/*                                                                      */
/*          For annualized (not time-specific) costs, if the respondent */
/*          dent has already provided surrogate cost information for a  */
/*          particular product but has put either a zero or a missing   */
/*          value for production quantity, then the default language    */
/*          in Sect. 3-B will mistakenly mark the product as one still  */
/*          requiring surrogate information. For annualized costs       */
/*          only, you can remedy this by setting the production         */
/*          quantity to a non-zero or non-missing value in Sect 3-A-i.  */
/*                                                                      */
/*          Similarly, for time-specific costs, reported surrogate      */
/*          cost information will be ignored and products instead       */
/*          designated as those still requiring surrogates if total     */
/*          production during the annual cost period is zero or missing.*/
/*          The production quantities of the surrogate product are      */
/*          required for indexing. Setting the production quantities    */
/*          to arbitrary values will calculate indexed input values     */
/*          incorrectly, with the products requiring surrogate costs    */
/*          having different indexed input values than the products     */
/*          which supplied the surrogate information.                   */
/*----------------------------------------------------------------------*/

%MACRO SETUP1_CVDATA;
    %IF %UPCASE(&COST_TYPE) = CV %THEN
    %DO;
        DATA COST;
            SET COMPANY.&COST_DATA;

            /*------------------------------------------------------*/
            /* 3-A-i: Insert pre-indexing changes to inputs,        */
            /*            production quantities, manufacturer, etc. */
            /*------------------------------------------------------*/

            /* <Make changes to non-indexed fields here> */

        RUN;
    %END;
%MEND SETUP1_CVDATA;

%SETUP1_CVDATA

/*ep*/

/*---------------------------------------------------------------------*/
/* 3-B SURROGATE COSTS FOR PRODUCTS NOT PRODUCED DURING POI/POR        */
/*                                                                     */
/*     The macro variable &FIND_SURROGATES will be created whose value */
/*     will be "YES" when it does find products requiring surrogates   */
/*     using the criteria specified. Otherwise, &FIND_SURROGATES will  */
/*     be set to "NO," turning off sections 3-B and 3-G.               */
/*---------------------------------------------------------------------*/

/*-----------------------------------------------------------------*/
/*     3-B-i IDENTIFY PRODUCTS NOT PRODUCED DURING POI/POR         */
/*           FOR WHICH SURROGATE COSTS ARE NEEDED.                 */
/*                                                                 */
/*     The %G8_FIND_NOPRODUCTION macro below identifies products   */
/*     needing surrogate cost information when total production    */
/*     during the cost period is zero or missing. If this          */
/*     assumption does not fit the circumstances, you will need    */
/*     to make edits accordingly.                                  */
/*                                                                 */
/*     For annualized (not time-specific) costs, if the respondent */
/*     has already provided surrogate cost information for a       */
/*     particular product but has put either a zero or a missing   */
/*     value for production quantity, then the default language    */
/*     will mistakenly think no surrogate information has been     */
/*     provided. For annualized costs only, you can remedy this    */
/*     problem by setting the production quantity to a non-zero    */
/*     or non-missing value above in Sect. 3-A-i.                  */
/*                                                                 */
/*     For time-specific costs, if the respondent has reported     */
/*     either zero or missing values for production quantities     */
/*     for all quarters during the period on products with         */
/*     surrogate cost information reported, the production         */
/*     quantities for the surrogate product must be used instead.  */
/*     Replace the zero/missing values with the surrogate's        */
/*     production quantities above in Sect. 3-A-i.                 */
/*-----------------------------------------------------------------*/

%MACRO NOPRODUCTION;
    %GLOBAL FIND_SURROGATES;
    %LET FIND_SURROGATES = NO;  /*Default value, do not edit. */

    %IF %UPCASE(&COST_TYPE) = CV %THEN
    %DO; 
        %IF %UPCASE(&MATCH_NO_PRODUCTION)=YES %THEN
        %DO;
            %G8_FIND_NOPRODUCTION  /* Finds products needing surrogate */
                                   /* costs by looking for total       */
                                   /* production quantities per product*/
                                   /* (across all POR time periods,    */
                                   /* where applicable) that are less  */
                                   /* than or equal to zero, or have   */
                                   /* missing values. If this is incor-*/
                                   /* rect, please make adjustments    */
                                   /* in Sect 3-A-i before running     */
                                   /* the G8_FIND_NOPRODUCTION macro.  */

/*-------------------------------------------------------------*/
/*     3-B-ii      ATTACH PRODUCT CHARACTERISTICS, IF REQUIRED */
/*                                                             */
/*     When product characteristic variables are not           */
/*     in the cost data, they will be taken from the           */
/*     U.S. sales data.                                        */
/*-------------------------------------------------------------*/

            %G9_COST_PRODCHARS
        %END;
    %END;
%MEND NOPRODUCTION;

%NOPRODUCTION

/*ep*/

/*--------------------------------------------------------------------*/
/*     3-C SEPARATE PRODUCTS WITH TIME-SPECIFIC COSTS FROM THOSE      */
/*          WITH ANNUALIZED COSTS. FOR PRODUCTS WITH TIME-SPECIFIC    */
/*          COSTS, DEFINE TIME PERIODS, SEPARATING PERIODS INSIDE THE */
/*          ACCOUNTING PERIOD FROM THOSE OUTSIDE, FILL IN ANY MISSING */
/*          TIME PERIODS IN COST DATA.                                */
/*--------------------------------------------------------------------*/

%MACRO SETUP_COST_PERIODS;
    %IF %UPCASE(&COST_TYPE) = CV %THEN
    %DO;
        /*-------------------------------------------------------------*/
        /* 3-C-i SEPARATE PRODUCTS WITH TIME-SPECIFIC COSTS FROM       */
        /*       THOSE WITH ANNUALIZED COSTS.                          */
        /*                                                             */
        /*   If there are both products with time-specific costs and   */
        /*   those with annualized costs, then separate them here      */
        /*   before time periods are attached in Sect. 3-C-ii. Put     */
        /*   products with annualized costs in a dataset called        */
        /*   'ANNUALCOST' and those with time-specific costs into a    */
        /*   dataset called 'COST.'                                    */
        /*-------------------------------------------------------------*/

        %IF %UPCASE(&COMPARE_BY_TIME) = YES %THEN
        %DO;
            %IF %UPCASE(&TIME_ANNUALIZED) NE NA %THEN
            %DO;
                DATA COST ANNUALCOST;
                    SET COST;
                    IF &COST_TIME_PERIOD IN(&TIME_ANNUALIZED) THEN
                        OUTPUT ANNUALCOST;
                    ELSE
                        OUTPUT COST;
                    RUN;

                    /*-------------------------------------------------*/
                    /* 3-C-ii. COMPARE COST DATA TO A LIST OF ALL      */
                    /*         TIME PERIODS, FILL IN MISSING LINES IN  */
                    /*         THE COST DATA, IF ANY. The              */
                    /*         G10_TIME_PROD_LIST macro immediately    */
                    /*         below uses the macro variables in Sect. */
                    /*         1-E-iii-b-1 above for TIME_INSIDE_POR   */
                    /*         and TIME_OUTSIDE_POR to make a list of  */
                    /*         all possible time periods. If all time  */
                    /*         periods are not represented in the cost */
                    /*         data, the missing lines are added to the*/
                    /*         database, using annualized costs from a */
                    /*         non-missing line to supply information  */
                    /*         on non-indexed variables.               */
                    /*-------------------------------------------------*/

                    %G10_TIME_PROD_LIST(&USCHAR) 
             %END;
        %END;
    %END;
%MEND SETUP_COST_PERIODS;

%SETUP_COST_PERIODS

/*ep*/

/***************************************************************************/
/* 3-D     DEFINE TIME PERIODS AND INDICES, MAKE PRE-INDEXING CHANGES      */
/*          TO INPUTS, CALCULATE TIME-SPECIFIC INDEXED INPUT VALUES        */
/***************************************************************************/

/*-------------------------------------------------------------------------*/
/* 3-D-i: DEFINE EACH INPUT TO BE INDEXED, MAKE ADJUSTMENTS TO INPUTS,     */
/*        WHEN REQUIRED.                                                   */
/*                                                                         */
/*  For each input to be indexed, create both an &INPUTi and an            */
/*  &INPUTi_ADJUSTED macro variable, where 'i' is a unique indicator for   */
/*  each input. The &INPUTi macro variable should be set to the variable   */
/*  in the cost data to be indexed, as reported by the respondent, before  */
/*  any adjustment has been made. The &INPUTi_ADJUSTED macro variable      */
/*  should be set to the adjusted value (a.k.a "actual value") of the      */
/*  &INPUTi variable. It is the adjusted amount that gets indexed. For     */
/*  example, if you are indexing NICKEL and there is also a major-input    */
/*  adjustment to NICKEL, called MAJADJ, you could write the following:    */
/*                                                                         */
/*         %LET INPUT1 = NICKEL;                                           */
/*          %LET    INPUT1_ADJUSTED = NICKEL + MAJADJ;                     */
/*                                                                         */
/*  If you previously created a new variable revising the input in Sect.3-A*/
/*  above (e.g., RNICKEL = NICKEL + MAJADJ), you can instead type:         */
/*                                                                         */
/*         %LET INPUT1 = NICKEL;                                           */
/*          %LET    INPUT1_ADJUSTED = RNICKEL;                             */
/*                                                                         */
/*  Both methods are fine.                                                 */
/*                                                                         */
/*  If you have two inputs to index, activate the language for INPUT2      */
/*  below and complete. For more than two inputs, copy the language below  */
/*  and call them INPUT3, INPUT4, etc.                                     */
/*-------------------------------------------------------------------------*/

%MACRO CALC_INDICES;
    %IF %UPCASE(&COST_TYPE) = CV %THEN
    %DO; 
        %IF %UPCASE(&COMPARE_BY_TIME) = YES %THEN
        %DO;
            %IF %UPCASE(&INDEX_SOURCE) NE RESP %THEN
            %DO;
                /* Variable to be indexed, unadjusted, as */
                /* it appears in the cost database.       */

                %LET INPUT1 = <  >;

                /* Value of variable to be indexed after adjustments, */
                /* including any major-input adjustment. If there is  */
                /* adjustment, use the default "&INPUT1" (no quotes). */

                %LET    INPUT1_ADJUSTED = <&INPUT1>;

                /*
                     %LET INPUT2 = <  >;
                     %LET    INPUT2_ADJUSTED = <&INPUT2>;
                */

/*----------------------------------------------------------------------*/
/* 3-D-ii INSERTING INDICES INTO THE COST DATA                          */
/*                                                                      */
/*     The indices can either be calculated outside of this program and */
/*     then input in, or they can be calculated within this program. If */
/*     your indices have already been supplied to you from an outside   */
/*     source, complete Sect. 3-D-ii-a immediately below. If, on the    */
/*     other hand, you are calculating the indices within this program, */
/*     complete Sect. 3-D-ii-b.                                         */
/*----------------------------------------------------------------------*/

/*-------------------------------------------------------------------------*/
/* 3-D-ii-a INPUTTING SUPPLIED TIME-SPECIFIC INDICES                       */
/*                                                                         */
/*     The G11_INSERT_INDICES_IN macro and the G12_INSERT_INDICES_OUT      */
/*     macro will generate language linking indices to periods as          */
/*     follows:                                                            */
/*                                                                         */
/*          IF {COST_TIME_PERIOD}={first period in list} THEN              */
/*          INPUTi_INDEX = {first index in list for INPUTi}                */
/*                                                                         */
/*     If there are multiple sets of indices that depend on various        */
/*     conditions, list each of the conditions under a separate            */
/*     CONDITION_i macro variable. State the conditions without any        */
/*     "IF" or "THEN" verbage. For example, if indices vary according      */
/*     to GRADE, you would type something like:                            */
/*                                                                         */
/*          CONDITION_A = GRADE IN("101")                                  */
/*          CONDITION_B = GRADE IN("102")                                  */
/*                                                                         */
/*     If there is no condition in your case (i.e., one set of indices)    */
/*     set the condition to "NA" (no quotes) for one CONDITION_i macro     */
/*     variable, and use it in the G11_INSERT_INDICES_IN macro and,        */
/*     if required, THE G12_INSERT_INDICES_OUT macro.                      */
/*                                                                         */
/*     For each relevant combination of condition and input, execute a     */
/*     G11_INSERT_INDICES_IN and, if there are cost periods outside of     */
/*     the POR, a G12_INSERT_INDICES_OUT macro.                            */
/*-------------------------------------------------------------------------*/

                %IF %UPCASE(&INDEX_SOURCE) = INPUT %THEN
                %DO;
                    %LET CONDITION_A = <NA>;
                    %LET    INDEX1A_IN_POR = <  >;

                    /* List of values of indices for periods in POR, */
                    /* in the same order as time periods in          */
                    /* TIME_INSIDE_POR macro, separated by blank     */
                    /* space, no quotes around values. E.g.,         */
                    /* 1.0  1.1  1.2  1.3                            */

                    %LET    INDEX1A_OUT_POR = <  >; 

                    /* List of values of indices for periods outside */
                    /* of POR, in same order as time periods in      */
                    /* TIME_OUTSIDE_POR macro, separated by blank    */
                    /* space, no quotes around values. E.g.,         */
                    /* 0.7  0.8  0.9                                 */

                    /*
                    %LET CONDITION_B = <NA>;
                    %LET    INDEX1B_IN_POR = <  >;
                    %LET    INDEX1B_OUT_POR = <  >;
                    */

                    DATA COSTPOR;
                        SET COSTPOR;

                        /* Ex. for condition A with input 1 */

                    %G11_INSERT_INDICES_IN(&INPUT1,&CONDITION_A,&INDEX1A_IN_POR)

                        /* Ex. for condition B with input 1 */
                        /*
                    %G11_INSERT_INDICES_IN(&INPUT1,&CONDITION_B,&INDEX1B_IN_POR)
                        */

                        /* Ex. for condition A with input 2 */
                        /*
                    %G11_INSERT_INDICES_IN(&INPUT2,&CONDITION_A,&INDEX2A_IN_POR)
                        */

                        /* Ex. for condition B with input 2 */
                        /*
                    %G11_INSERT_INDICES_IN(&INPUT2,&CONDITION_B,&INDEX2B_IN_POR)
                        */

                    RUN;

                    %IF %UPCASE(&TIME_OUTSIDE_POR) NE NA %THEN
                    %DO;
                        DATA COSTOUTPOR;
                            SET COSTOUTPOR;

                            /* Ex. for condition A with input 1 */

               %G12_INSERT_INDICES_OUT(&INPUT1,&CONDITION_A,&INDEX1A_OUT_POR)

                            /* Ex. for condition B with input 1 */
                            /*
               %G12_INSERT_INDICES_OUT(&INPUT1,&CONDITION_B,&INDEX1B_OUT_POR)
                            */

                           /* Ex. for condition A with input 2 */
                           /*
               %G12_INSERT_INDICES_OUT(&INPUT2,&CONDITION_A,&INDEX2A_OUT_POR)
                           */

                           /* Ex. for condition B with input 2 */
                           /*
               %G12_INSERT_INDICES_OUT(&INPUT2,&CONDITION_B,&INDEX2B_OUT_POR)
                           */
                        RUN;
                    %END;
                %END;

/*---------------------------------------------------------------------*/
/* 3-D-ii-b CALCULATING INDICES WITHIN THIS PROGRAM                    */
/*                                                                     */
/*     The G13_CALC_INDICES macro calculates the indices based on the  */
/*     grouping indicated in the INDEX_GROUPi macro variable. Within   */
/*     each group, there must be at least one line of cost data with   */
/*     production for each cost time period.                           */
/*                                                                     */
/*     Under the INDEX_GROUPi macro variable, list the variables to be */
/*     used in defining the groupings (i.e., the "BY" variables) for   */
/*     calculating the indices (e.g., MANUF GRADE). If there is no     */
/*     grouping variable since you are calculating indices across the  */
/*     whole database for a particular input, type "INDEX_GROUP=NA."   */
/*     You may have different groupings for different inputs. Execute  */
/*     the INDICES macro for each input/grouping pair. You can use a   */
/*     particular grouping for more than one input.                    */
/*---------------------------------------------------------------------*/

                %IF %UPCASE(&INDEX_SOURCE) = CALC %THEN
                %DO;
                    /* List the variables to be used to group/sort the */
                    /* data for calculating indices on input1.         */

                    %LET INDEX_GROUP1 = <??>;

                    /* List the variables to be used to group/sort the */
                    /* data for calculating indices on input2.         */
                    /*
                    %LET INDEX_GROUP2 = <??>;
                    */ 

                    %MACRO RUN_INDICES;
                        /* Ex. for input1 and grouping1 */

                        %INDICES(&INPUT1,&INPUT1_ADJUSTED,&INDEX_GROUP1)

                        /* Ex. for input2 and grouping2 */
                        /*
                        %INDICES(&INPUT2,&INPUT2_ADJUSTED,&INDEX_GROUP2)
                        */
                    %MEND RUN_INDICES;

                    %G13_CALC_INDICES
                %END;

/*-------------------------------------------------------------------------*/
/* 3-D-iii CALCULATE TIME-SPECIFIC INDEXED INPUT VALUES                    */
/*                                                                         */
/*     Whether you inputted supplied indices in Sect. 3-D-ii-a or          */
/*     calculated indices in Sect. 3-D-ii-b, you must execute a            */
/*     G14_INDEX_CALC macro for each input. This macro will use the        */
/*     indices to calculate period-specific indexed input amounts. If      */
/*     there is more than one input to be indexed, execute a               */
/*     G14_INDEX_CALC macro for each.                                      */
/*-------------------------------------------------------------------------*/

                /* Ex. for input 1 */

                %G14_INDEX_CALC(&INPUT1,&INPUT1_ADJUSTED,&INPUT1._INDEX)

                /* Ex. for input 2 */
                /*
                %G14_INDEX_CALC(&INPUT2,&INPUT2_ADJUSTED,&INPUT2._INDEX)
                */ 
            %END;
        %END;
    %END;
%MEND CALC_INDICES;

%CALC_INDICES

/*ep*/

/***************************************************************************/
/* 3-E  AFTER INDEXING INPUTS, IF REQUIRED, CALCULATE TOTAL COST OF        */
/*      MANUFACTURING, GNA, INTEREST AND TOTAL COST OF PRODUCTION.         */
/*                                                                         */
/*  When there are both time-specific and annualized costs, both are       */
/*  combined into one database called, COST.                               */
/*                                                                         */
/*  For each input whose cost is varying in time (i.e., is time-specific), */
/*  a new variable has been created called, FINAL_{input variable name}.   */
/*  For example, if one such input is NICKEL, then the new variable will   */
/*  be called, FINAL_NICKEL. In time periods in which there is production  */
/*  of a product, FINAL_{input variable name} is equal to the actual       */
/*  value. For time periods with no production and, accordingly,           */
/*  production quantity is either zero or missing, the value for           */
/*  FINAL_{input variable name} is equal to the indexed value of the       */
/*  input. Use the variable FINAL_{input variable name} to recalculate     */
/*  total cost of manufacturing for time-specific products.                */
/***************************************************************************/

%MACRO SETUP2_COSTDATA;
    %IF %UPCASE(&COST_TYPE) = CV %THEN
    %DO;
        DATA COST;
            SET COST &ANNUAL_COST; /* Macro variable ANNUAL_COST will  */
                                   /* be a null value when there is no */
                                   /* annualized data.                 */

            IF &COST_QTY IN (.,0) THEN
                &COST_QTY = 1;

            TCOMCOP  = <  >; /* Total cost of manufacturing. For       */
                             /* inputs with time-specific values,      */
                             /* build up total cost of manufacturing   */
                             /* using FINAL_{old input variable name}. */

/*-------------------------------------------------------------------*/
/*     If you have both time-specific and annualized costs, you      */
/*     will need separate equations for total cost of manufacturing. */
/*     Deactivate the single line above for TCOMCOP and              */
/*     instead use the language below.                               */
/*-------------------------------------------------------------------*/

            /* For annualized costs. */
            /* 
                IF &COST_TIME_PERIOD IN(&TIME_ANNUALIZED) THEN
                    TCOMCOP = <  >;
            */

            /* For time-specific costs */
            /* 
                ELSE
                    TCOMCOP = <  >;
            */

/*-----------------------------------------------------------------*/
/*     If you have time-specific costs and at least one control    */
/*     number has time periods with no production, you will need   */
/*     to recalculate GNA and interest expenses using the TCOMCOP  */
/*     based on the FINAL_{input variable name} variables, even if */
/*     the GNA and interest ratios have not changed.               */
/*-----------------------------------------------------------------*/

            VCOMCOP = <TCOMCOP - FOH>; /* Variable cost of             */
                                       /* manufacturing equal to       */
                                       /* TCOMCOP less fixed costs.    */
            GNACOP = <  >;             /* General and administrative   */
                                       /* expense.                     */
            INTEXCOP = <  >;           /* Interest expense.            */

            TOTALCOP = TCOMCOP + GNACOP + INTEXCOP; /* Total cost of   */
                                                    /* production.     */
        RUN;
    %END;
%MEND SETUP2_COSTDATA;

%SETUP2_COSTDATA

/*ep*/

/*-----------------------------------------------*/
/* 3-F: WEIGHT-AVERAGE COST DATA, WHEN REQUIRED. */
/*-----------------------------------------------*/

%G15_CHOOSE_COSTS

/*ep*/

/*--------------------------------------------------------------------*/
/* 3-G: FIND SURROGATE COSTS FOR PRODUCTS NOT PRODUCED DURING POR     */
/*--------------------------------------------------------------------*/

%G16_MATCH_NOPRODUCTION

/*ep*/

/*--------------------------------------------------------------------*/
/* 3-H: MERGE COSTS WITH U.S. SALES DATA                              */
/*                                                                    */
/*--------------------------------------------------------------------*/

%G17_FINALIZE_COSTDATA 

/*ep*/

/***************************************************************************/
/* PART 4: CALCULATE THE NET U.S. PRICE                                    */
/***************************************************************************/

/*-------------------------------------------------------------------------*/
/* 4-A: CALCULATION OF AGGREGATE PRICE ADJUSTMENT VARIABLES                */
/*                                                                         */
/*     All aggregate variables should be in U.S. dollars after any         */
/*     adjustments. If you have any variables originally in non-USD        */
/*     currency that you listed in Sect. I-E-ii under EX1_VARS=??? Or      */
/*     EX2_VARS= ???, these variables are now converted into U.S. dollars  */
/*     and have new names. Use the new names below. The new names consist  */
/*     of the old names with the suffix "_USD" added. For example, if you  */
/*     typed "%LET EX1_VARS=TRUCKING" in Sect. I-E-ii, the new variable    */
/*     TRUCKING_USD has been created and set equal to TRUCKING*&EXRATE1.   */
/*-------------------------------------------------------------------------*/

DATA USSALES;
    SET USSALES;

    USGUP = <&USGUP>;      /* Gross unit price. Default is to use the      */
                           /* variable selected for the &USGUP macro in    */
                           /* Section 1-E-ii above                         */
    USGUPADJ = <0>;        /* Price adjustments to be added to CMGUP,      */
                           /* including duty drawback, CVD export subsidies*/
    USDISREB = <0>;        /* Discounts, rebates and other price adjust-   */
                           /* ments to be subtracted from USGUP            */
    USDOMMOVE = <0>;       /* Domestic CM movement expenses up to delivery */
                           /* alongside the vessel at port of export       */
    USINTLMOVE = <0>;      /* International and U.S. movement expenses,    */
                           /* including U.S. duties, from loading onto the */
                           /* vessel to delivery in U.S.                   */
    USCREDIT = <0>;        /* Imputed credit                               */
    USDIRSELL = <0>;       /* Direct selling expenses for circumstance of  */
                           /* sale (COS) adjustments. Excludes imputed     */
                           /* credit (USCREDIT) and any direct selling     */
                           /* expenses incurred in the U.S. on CEP sales.  */
                           /* Includes all direct selling on EP sales and  */
                           /* any direct selling on CEP sales NOT incurred */
                           /* in the U.S.                                  */
    USCOMM = <0>;          /* All commissions on EP sales and those on CEP */
                           /* sales incurred outside of the U.S. Do NOT    */
                           /* include commissions on CEP sales incurred in */
                           /* the U.S. here, instead include these in      */
                           /* CEPOTHER.                                    */
    USICC = <0>;           /* Imputed inventory carrying costs, excluding  */
                           /* CEP inventory carrying costs.                */
    USISELL = <0>;         /* Indirect selling expenses, excluding USICC   */
                           /* and any CEP indirects.                       */
    CEPICC = <0>;          /* CEP (incurred in the U.S.) inventory carrying*/
                           /* cost expenses. Will be set to zero for EP    */
                           /* sales.                                       */
    CEPISELL = <0>;        /* CEP (incurred in the U.S.) indirect selling  */
                           /* expenses. Will be set to zero for EP sales.  */
    CEPOTHER = <0>;        /* Any other CEP (incurred in the U.S.)         */
                           /* commissions, direct selling, further         */
                           /* manufacturing, etc. expenses not included in */
                           /* CEPICC or CEPISELL. Will be set to zero for  */
                           /* EP sales.                                    */
    USPACK = <0>;          /* Export packing to the U.S.                   */

/*----------------------------------------------------------------------*/
/* 4-A-i: INDIRECTS FOR COMMISSION OFFSETS                              */
/*                                                                      */
/*  Calculation of indirect selling expenses for purposes of commission */
/*     offsets, USINDCOMM.                                              */
/*----------------------------------------------------------------------*/

    %US4_INDCOMM
RUN;

/*ep*/

/*-------------------------------------------------------------------------*/
/* 4-B: CEP PROFIT RATE                                                    */
/*                                                                         */
/* If you typed %LET CEPPROFIT=CALC in Sect. 1-E-vi above, the US5_CEPRATE */
/* macro will use revenue and expense information from U.S. and CM sales   */
/* to calculate the overall CEP profit ratio. Total amounts for cost of    */
/* goods sold, revenue, selling expenses and movement will be calculated   */
/* for each U.S. transaction, and then converted from U.S. dollars into CM */
/* currency using EXRATE1. The overall amounts for COGS, revenue and       */
/* expenses on U.S. sales will then be calculated and combined with CM     */
/* data to calculate CEP profit rate.                                      */
/*                                                                         */
/* If you typed %LET CALC_CEPPROFIT=INPUT above, the profit rate supplied  */
/* by %LET CEPRATE=<???> will be used for the CEP profit ratio. CEP        */
/* selling expense amounts will be set to zero for EP sales.               */
/*-------------------------------------------------------------------------*/

%US5_CEPRATE

/*ep*/

/*-------------------------------------------------------------------------*/
/* 4-C: CALCULATE NET U.S. PRICE                                           */
/*-------------------------------------------------------------------------*/

PROC SORT DATA = USSALES;
    BY SALE_TYPE;
RUN;

/*ep*/

DATA USSALES SALES;
    SET USSALES;
    BY SALE_TYPE;

    IF FIRST.SALE_TYPE THEN
        COUNT = 0;

    COUNT + 1;

    IF UPCASE(SALE_TYPE) = 'EP' THEN 
    DO;
        CEPRATIO = 0;
        CEPROFIT = 0;
        USNETPRI = USGUP + USGUPADJ - USDISREB - USDOMMOVE - USINTLMOVE;
    END;
    ELSE
    IF UPCASE(SALE_TYPE) = 'CEP' THEN
    DO;
        CEPROFIT = (USCREDIT + CEPICC + CEPISELL + CEPOTHER) * CEPRATIO;

        USNETPRI = USGUP + USGUPADJ - USDISREB - USDOMMOVE - USINTLMOVE
                 - USCREDIT - CEPICC - CEPISELL - CEPOTHER - CEPROFIT;
    END;

    OUTPUT USSALES;

    IF COUNT LE &PRINTOBS THEN
        OUTPUT SALES;
RUN;

/*ep*/

PROC PRINT DATA = SALES;
    ID SALE_TYPE;
    TITLE3 'SAMPLE OF U.S. NET PRICE CALCULATIONS';
RUN;

/*ep*/

/*-------------------------------------------------------------------------*/
/* 4-D: DEFINE CUSTOMS ENTERED VALUE FOR ADMINISTRATIVE REVIEWS            */
/*-------------------------------------------------------------------------*/

%US6_ENTVALUE 

/*ep*/

/***************************************************************************/
/* PART 5: CONVERT COMPARISON MARKET NET PRICES AND ADJUSTMENTS INTO CM    */
/*         CURRENCY, IF REQUIRED                                           */
/*                                                                         */
/*     If CM sales data has more than one currency, the CMDATA macro       */
/*     immediately following will create another macro called,             */
/*     MULTIPLE_CURR, which will get executed in the US10_P2PCALC below    */
/*     in Part 8. Accordingly, you will not see anything in your log       */
/*     about the calculation of CM net price, etc., at this point.         */
/***************************************************************************/

%MACRO CMDATA;
    %IF %UPCASE(&NV_TYPE) = P2P %THEN
    %DO;
        %MACRO MULTIPLE_CURR;
            %IF %UPCASE(&CM_MULTI_CUR) = YES %THEN
            %DO;

/*------------------------------------------------------------------------*/
/* 5-A: If the CM database has more than one currency, edit the formula   */
/*   for CM net price and, if required, inventory carrying costs (CMICC), */
/*   indirect selling expenses (CMISELL), commissions (CMCOMM) and        */
/*   surrogate commissions (CMINDCOM). Calculate all in CM currency.      */
/*------------------------------------------------------------------------*/
 
                CMNETPRI = <CMGUP + CMGUPADJ - CMDISREB - CMMOVE
                         -  CMCRED - CMDSELL - CMCOMM - CMPACK>;

                <CMICC = ???;>     /* deactivate or delete if */
                                   /* editing not required.   */
                <CMISELL = ???;>   /* deactivate or delete if */
                                   /* editing not required.   */
                <CMCOMM = ???;>    /* deactivate or delete if */
                                   /* editing not required.   */
                <CMINDCOM = ???;>  /* deactivate or delete if */
                                   /* editing not required.   */
            %END;
        %MEND MULTIPLE_CURR;
    %END;
%MEND CMDATA;

%CMDATA

/*ep*/

/***************************************************************************/
/* PART 6: CREATE CONCORDANCE OF PRICE-TO-PRICE MATCHING INSTRUCTIONS      */
/*                                                                         */
/*     U.S. models not finding a suitable match will be compared to        */
/*     constructed value.                                                  */
/***************************************************************************/
%US7_CONCORDANCE

/*ep*/

/***************************************************************************/
/*  PART 7: LEVEL OF TRADE ADJUSTMENT, IF REQUIRED                         */
/*                                                                         */
/*     If you typed %LET LOT_ADJUST=CM above in Sect. 1-E-vi, information  */
/*     calculated in the CM program will be merged with the U.S. sales by  */
/*     the US8_LOTADJ macro.                                               */
/*                                                                         */
/*     If you typed %LET LOT_ADJUST=NO, then the US8_LOTADJ macro will set */
/*     LOTADJ=0, resulting in no adjustment for LOT.                       */
/*                                                                         */
/*     If you typed %LET LOT_ADJUST=INPUT because you will be making an    */
/*     LOT adjustment using information other than that from the CM sales, */
/*     edit the sample language below in Sect. 7-A-i. There should be an   */
/*     adjustment ratio (LOTADJ) for each combination of U.S. and CM LOT.  */
/*     The amount of the LOT adjustment (LOTADJMT) later calculated will   */
/*     be equal to CMNETPRI*LOTADJ, and then added to CMNETPRI in          */
/*     calculating FUPDOL.                                                 */
/***************************************************************************/

%MACRO LOT_ADJUSTMENT;
    %IF &CALC_P2P = YES %THEN
    %DO;
        %US8_LOTADJ 

        %IF %UPCASE(&LOT_ADJUST) = INPUT %THEN
        %DO;
            DATA ISMODELS; 
                SET ISMODELS;
                LOTHDATA = 'YES'; 

/*------------------------------------------------------------------*/
/*     7-A-i Create a line for each combination of U.S. and CM LOT. */
/*------------------------------------------------------------------*/

                /*
                IF USLOT = <??> AND CMLOT = <??> THEN LOTADJ = <??>;
                */
            RUN;
        %END;

/*---------------------------------------------------------------------*/
/*     7-A-ii EDIT LOT ADJUSTMENT AND CEP OFFSET, IF REQUIRED.         */
/*                                                                     */
/*     The default programming below sets any CEP Offset to zero when  */
/*     there is a valid LOT adjustment calculated (i.e., when there    */
/*     there is a difference in LOT and there is LOT adjustment info.) */
/*                                                                     */
/*     The macro P2P_ADJUSTMT_LOTADJ is created below but not used     */
/*     until the US10_P2PCALC macro gets executed in Part 8.           */
/*     Accordingly, you will not see anything in your log about the    */
/*     calculation of LOTADJMT at this point.                          */
/*---------------------------------------------------------------------*/

          %MACRO P2P_ADJUSTMT_LOTADJ;
               %IF %UPCASE(&LOT_ADJUST) NE NO %THEN
               %DO;
                    IF LOTHDATA = 'YES' AND LOTDIFF GT 0 THEN
                    DO;
                    LOTADJMT = CMNETPRI * LOTADJ;
                         USECEPOFST = 'NO';
                    END;
               %END;
          %MEND P2P_ADJUSTMT_LOTADJ;
     %END;
%MEND LOT_ADJUSTMENT;

%LOT_ADJUSTMENT

/*ep*/

/***************************************************************************/
/* PART 8: COMBINE U.S. SALES WITH CM MATCHES, CALCULATE TRANSACTION LOT   */
/*         -SPECIFIC LOT ADJUSTMENTS, CEP AND COMMISSION OFFSETS           */
/*                                                                         */
/*     Convert CM commissions and information required for offsets into    */
/*     U.S. dollars. Calculate the LOT adjustment, commission and CEP      */
/*     offsets.                                                            */
/***************************************************************************/

%US10_LOT_ADJUST_OFFSETS 

/*ep*/

/***************************************************************************/
/* PART 9: CALCULATE CEP AND COMMISSION OFFSETS FOR CONSTRUCTED VALUE      */
/* COMPARISONS                                                             */
/***************************************************************************/

%MACRO CV_CALCS;
    %IF &CALC_CV = YES %THEN
    %DO;

/*-------------------------------------------------------------------------*/
/*     9-A CV SELLING EXPENSE RATES WHEN MAKING STRAIGHT COMPARISONS OF    */
/*          U.S. SALES TO CV, OR WHEN THERE IS NO SUITABLE CM DATA ON      */
/*          SELLING EXPENSES AND PROFIT.                                   */
/*                                                                         */
/*     Supply rates for CV selling expenses and profit in decimal format.  */
/*     The rates will be multiplied by total cost to calculate per-unit    */
/*     expense amounts.                                                    */
/*-------------------------------------------------------------------------*/

        %IF %UPCASE(&NV_TYPE) = CV OR %UPCASE(&CVSELL_TYPE) = OTHER %THEN
        %DO;
            DATA NVCV;
                SET USSALES;

                DSELCVR  = <???>; /* direct selling expenses, as a      */
                                  /* ratio of cost                      */
                CREDCVR = <???>;  /* credit expenses, as a ratio of     */
                                  /* price                              */
                ISELCVR = <???>;  /* indirect selling, excluding        */
                                  /* inventory carrying costs, as a     */
                                  /* ratio of cost                      */
                COMMCVR = <???>;  /* commissions, as a ratio of cost    */
                ICOMCVR = <???>;  /* surrogate commission equal either  */
                                  /* to zero (when COMMCV greater than  */
                                  /* zero) or to the sum of indirect    */
                                  /* selling and inventory carry costs, */
                                  /* as a ratio of cost                 */
                INVCVR = <???>;   /* inventory carrying costs, as a     */
                                  /* ratio of cost                      */
                PRATECV = <???>;  /* profit, as a ratio of cost         */
                CVSELLPR = 'YES'; /* do not edit.                       */

                %NVMATCH          /* do not edit.                       */
            RUN;
        %END;

/*-------------------------------------------------------------------------*/
/*     9-B CV SELLING EXPENSE RATES CALCULATED IN THE CM PROGRAM           */
/*                                                                         */
/*     When there is suitable information on CV selling expense and profit */
/*     rates calculated in the CM program, the US11_CVSELL_OFFSETS macro   */
/*     will merge the information with U.S. sales to be compared to CV.    */
/*-------------------------------------------------------------------------*/

        %US11_CVSELL_OFFSETS
    %END;
%MEND CV_CALCS;

%CV_CALCS

/*ep*/

/***************************************************************************/
/* PART 10: COMBINE PRICE-2-PRICE COMPARISONS WITH SALES COMPARED TO CV    */
/***************************************************************************/

%US12_COMBINE_P2P_CV  

/*ep*/

/***************************************************************************/
/* PART 11: COHEN'S-D TEST                                                 */
/*                                                                         */
/*    The Cohen's-d Test is run three ways:  1) by purchaser, 2) by region */
/*    and 3) by time period. U.S. sales are compared to sales to other     */
/*    purchasers/regions/periods to see if they pass the test. At the end  */
/*    of the test, the percentage of U.S. sales found to pass the test is  */
/*    recorded.                                                            */
/*                                                                         */
/*    In the remaining sections of this program, the Cash Deposit Rate     */
/*    will be calculated three ways:  1) Standard Method (average-to       */
/*    -average comparisons on all sales, offsetting positive comparison    */
/*    results with negatives), 2) A-to-T Alternative Method (average-to-   */
/*    transaction comparisons on all sales, no offsetting of positive      */
/*    comparison results with negative ones), and 3) Mixed Alternative     */
/*    Method (A-to-A with offsets for sales that do not pass the           */
/*    Cohen's-d Test and A-to-T with no offsets on sales that do pass.     */
/*                                                                         */
/*    If no sale passes the Cohen's-d Test, the Mixed Alternative Method   */
/*    would be the same as the Standard Method. In this case, the Mixed    */
/*    Alternative Method will not be calculated. Similarly, the Mixed      */
/*    Alternative Method will also not be calculated when all sales        */
/*    pass the Cohen's-d Test since the it would be the same as the        */
/*    A-to-T Alternative Method.                                           */
/***************************************************************************/

%US13_COHENS_D_TEST

/*ep*/

/***************************************************************************/
/* PART 12: WEIGHT AVERAGE U.S. SALES                                      */
/*                                                                         */
/*     Weight-average U.S. prices and adjustments and merge averaged data  */
/*     back onto the single-transaction database. The averaged variables   */
/*     will have the same names as the un-averaged ones, but with a        */
/*     suffix added. For the Standard Method, the suffix will be "_MEAN."  */
/*     For the Mixed Alternative Method, the suffix will be "_MIXED."  For */
/*     example, the averaged versions of USNETPRI will be USNETPRI_MEAN    */
/*     for the Standard Method and USNETPRI_MIXED for the Mixed            */
/*     Alternative Method. Both the single-transaction and weight-averaged */
/*     values will be in the data. In the US15_RESULTS macro below, the    */
/*     appropriate selection of the weight-averaged v single-transaction   */
/*     values will occur.                                                  */
/***************************************************************************/

%US14_WT_AVG_DATA

/*ep*/

/***************************************************************************/
/* PART 13: CALCULATE FUPDOL, NV, PUDD, ETC. USING THE STANDARD METHOD,    */
/*          THE A-to-T ALTERNATIVE METHOD AND, WHEN REQUIRED, THE MIXED    */
/*          ALTERNATIVE METHOD                                             */
/*                                                                         */
/*     STANDARD METHOD:                                                    */
/*          - Use weight-averaged U.S. prices, offsetting positive         */
/*            comparison results with negative ones, for all sales.        */
/*     MIXED ALTERNATIVE METHOD:                                           */
/*          - A rate calculated by using single-transaction prices without */
/*            offsetting on sales that pass the Cohen's-d Test, and weight-*/
/*            averaged U.S. prices with offsetting on sales not passing.   */
/*     A-to-T ALTERNATIVE METHOD                                           */
/*          - Use single-transaction U.S. prices without offsetting        */
/*            positive comparison results with negative ones on all sales. */
/*                                                                         */
/*   Calculate FUPDOL by converting CM net price (including the DIFMER     */
/*   and LOT adjustments) into U.S. dollars and adding U.S. packing.       */
/*   Calculate normal value (NV) from FUPDOL by doing COS adjustments      */
/*   and offsets. Compare U.S. price to NV to calculate the transaction-   */
/*   specific comparison results. (Note, no offsetting of positive        */
/*   comparison results with negatives is done at this point.)  The        */
/*   resulting databases are put in the COMPANY library as the following:  */
/*                                                                         */
/*          - &RESPONDENT._&SEGMENT._&STAGE_AVGMARG for the Standard       */
/*                    Method on the full U.S. sales database               */
/*          - &RESPONDENT._&SEGMENT._&STAGE._AVGMIXED for the portion of   */
/*                    sales being calculated with the Standard Method as   */
/*                    part of the Mixed Alternative Method.                */
/*          - &RESPONDENT._&SEGMENT._&STAGE._TRNMIXED for the portion of   */
/*                    sales being calculated with the A-to-T Alternative   */
/*                    Method as part of the Mixed Alternative Method.      */
/*          - &RESPONDENT._&SEGMENT._&STAGE._TRANMARG for the A-to-T       */
/*                    Alternative Method on the full U.S. sales database.  */
/*                                                                         */
/*   Variables with "&SUFFIX" added to their names in the programming will */
/*   have two or three values in the database: 1) the non-averaged/single- */
/*   transaction value when &SUFFIX is a blank space (e.g., USPACK&SUFFIX  */
/*   becomes USPACK), 2) the weight-averaged value when &SUFFIX=_MEAN      */
/*   (e.g., USPACK&SUFFIX becomes USPACK_MEAN) for the Standard Method,    */
/*   and sometimes 3) the weight-averaged value when &SUFFIX=_MIXED (e.g., */
/*   USPACK&SUFFIX becomes USPACK_MIXED) for the Mixed Alternative         */
/*   Method. The selection of averaged v non-averaged values is done       */
/*   automatically.                                                        */
/*                                                                         */
/*   The calculation of the foreign unit price in dollars (i.e., FUPDOL)   */
/*   is below. Typically, FUPDOL does not require editing except in        */
/*   unusual circumstances such as the reporting of CM sales information   */
/*   in a currency other than that used to report costs. If you need to    */
/*   edit the calculation of FUPDOL below, be sure to keep the "&SUFFIX"   */
/*   endings for USPACK&SUFFIX.                                            */
/***************************************************************************/

/*----------------------------------------------------------------------*/
/* 13-A Calculate FUPDOL for Price-to-Price Comparisons                 */
/*----------------------------------------------------------------------*/

%MACRO FUPDOL_P2P;  
    FUPDOL = ((CMNETPRI - DIFMER + LOTADJMT) * &XRATE1) + USPACK&SUFFIX;
%MEND FUPDOL_P2P;

/*----------------------------------------------------------------------*/
/* 13-B Calculate FUPDOL for Comparisons to Constructed Value           */
/*----------------------------------------------------------------------*/

%MACRO FUPDOL_CV; 
    FUPDOL = ((TOTCV - DSELCV - CREDCV - COMMCV) * &XRATE1) + USPACK&SUFFIX;
%MEND FUPDOL_CV;

/*----------------------------------------------------------------------*/
/* 13-C Execute comparison Result Calculations                          */
/*----------------------------------------------------------------------*/

%US15_RESULTS

/*ep*/

/***************************************************************************/
/* PART 14: CASH DEPOSIT RATES                                             */
/*                                                                         */
/*   Calculate Cash Deposit Rates based upon the Standard, Mixed           */
/*   Alternative (when  required) and A-to-T Alternative Methods.          */
/*                                                                         */
/*   For the Standard Method, calculated amounts from the database         */
/*   &RESPONDENT._&SEGMENT._&STAGE_AVGMARG will be used. Positive          */
/*   comparison results will be offset by negatives on all sales.          */
/*                                                                         */
/*   The Mixed Alternative Method will be a combination calculation.       */
/*   Sales that passed the Cohen's-d Test will be calculated using the     */
/*   &RESPONDENT._&SEGMENT._&STAGE._TRNMIXED database. No offsetting of    */
/*   positive comparison results with negatives will be done on these      */
/*   sales. Sales that did not pass the Test will be calculated using      */
/*   the &RESPONDENT._&SEGMENT._&STAGE_AVGMIXED database in which these    */
/*   sales were weight averaged separately from those that did pass the    */
/*   test. Positive comparison results will be offset by negatives on      */
/*   these sales.                                                          */
/*                                                                         */
/*   Cash Deposit Rate using the A-to-T Alternative Method for all sales   */
/*   will be calculated using the &RESPONDENT._&SEGMENT._&STAGE._TRANMARG  */
/*   database. No database. No offsetting of positive comparison results   */
/*   with negatives.                                                       */
/***************************************************************************/

%US16_CALC_CASH_DEPOSIT

/*ep*/

/***************************************************************************/
/* PART 15: MEANINGFUL DIFFERENCE TEST                                     */
/*                                                                         */
/*     Compare the cash deposit rate based on the Standard Method to rates */
/*     based on the Mixed Alternative (when required) and the A-to-T       */
/*     Alternative Methods to see if there is a Meaningful Difference.     */
/*     A Meaningful Difference occurs if:                                  */
/*                                                                         */
/*     - the Standard rate is de minimis/zero and the other is not, or     */
/*     - the Standard rate is above de minimis and the other is 25%        */
/*       greater than the Standard rate.                                   */
/***************************************************************************/

%US17_MEANINGFUL_DIFF_TEST

/*ep*/

/***************************************************************************/
/* PART 16: ASSESSMENT RATES (ADMINISTRATIVE REVIEWS ONLY)                 */
/*                                                                         */
/*     Assessment calculations will be done for each Method with a Cash    */
/*     Deposit Rate above de minimis. U.S. sales data will be weight-      */
/*     averaged again by importer before calculating the assessment rates. */
/*     The databases containing the importer transaction-specific          */
/*     comparison results (before offsetting, when required) for the       */
/*     various methods are as follows:                                     */
/*                                                                         */
/*      IMPSTND:  Assessment, Standard Method                              */
/*      IMPCSTN:  Assessment, sales not passing Cohens-d for Mixed         */
/*                Alternative Method                                       */
/*      IMPCTRN:  Assessment, sales passing Cohens-d for Mixed Alternative */
/*                Method                                                   */
/*      IMPTRAN:  Assessment, A-to-T Alternative Method                    */
/***************************************************************************/

%US18_ASSESSMENT 

/*ep*/

/***************************************************************************/
/* PART 17: REPRINT THE FINAL CASH DEPOSIT RATE                            */
/***************************************************************************/

%US19_FINAL_CASH_DEPOSIT

/*ep*/

/***************************************************************************/
/* PART 18: DELETE ALL WORK FILES IN THE SAS MEMORY BUFFER WHEN REQUESTED  */
/***************************************************************************/

%G18_DEL_ALL_WORK_FILES

/*ep*/

/***************************************************************************/
/* PART 19: CALCULATE RUN TIME FOR THIS PROGRAM WHEN REQUESTED             */
/***************************************************************************/

%G19_PROGRAM_RUNTIME

/*ep*/