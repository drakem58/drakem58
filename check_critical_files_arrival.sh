#!/bin/bash

date=$(date +'%Y%m')

yesterday=$(date -d '-1 day' +'%Y-%m-%dT')

if [[ -z "$1" ]]; then

    echo "Please provide a job name or 'all'"

    echo "Futures_Statements_Daily_Load_PDF_Files (0)"

    echo "ETCBO_ETC_CHECK_FILE_B212 (1)"

    echo "GTC_EQ_MKT_NSDQ_Transfer (2)"

    echo "ETRFERPT_TRANSFER (3)"

    echo "account_ets_futures_positions_update_validate (4)"

    echo "account_ets_futures_balances_update_validate (5)"

    echo "account_ets_futures_process_st4 (6)"

    echo "ACTM_LOAD_OH_ACCT_DATA (7)"

    echo "ETCBO_ETS_MF_OMNI_MFEXECN_TRANSFER (8)"

    echo "ETCBO_ETC_DRIP_TO_ETSEC (9)"

    echo "ETCBO_ADP_DRIP_EXCL.237 (10)"

    echo "change_sweep_option_set (11)"

    echo "account_ets_update_drip_status (12)"

    echo "account_ets_futures_positions_update_validate (13)"

    echo "Futures_Statements_Load_PDF_Files (14)"

    echo "ACTM_LOAD_REP_LOGIN (15)"

    echo "ADP_File_Watcher_NAMASTER (20)"

    echo "wedbush (21)"

    exit

fi



for i in "$@"; do



    case $i in



        "Futures_Statements_Daily_Load_PDF_Files"|"0")

            qs -n -d  jws1w26m3 -C "echo Futures_Statements_Daily_Load_PDF_Files  10:30pm ;ls -lrth  /etrade/prd/etdocs/batch/doc/archive/futures/statements/FirmODailyStatements*" 2> /dev/null

            ;;
