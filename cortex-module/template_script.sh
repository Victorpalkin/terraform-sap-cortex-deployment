echo "=====--Starting The Deployment script--==========="
git clone --depth 1 --branch v4.1 https://github.com/GoogleCloudPlatform/cortex-data-foundation.git --recurse-submodules
cd cortex-data-foundation
# echo "=====--Deleting custom cloud build instance types (not compatible with QL--==========="
# sed -i '/E2_HIGHCPU_32/d' src/SFDC/src/reporting/templates/cloudbuild_create_bq_objects.yaml.jinja
# sed -i '/E2_HIGHCPU_32/d' src/SAP/SAP_REPORTING/cloudbuild.views.end.yaml
# sed -i 's/\"turboMode\" : true/\"turboMode\" : false/g' config/config.json
# rm src/SAP/SAP_REPORTING/PO*
# rm src/SAP/SAP_REPORTING/Purchase*
# rm src/SAP/SAP_REPORTING/Vendor*
# rm src/SAP/SAP_REPORTING/Account*
# rm src/SAP/SAP_REPORTING/Cost*
# rm src/SAP/SAP_REPORTING/Invoice*
# rm src/SAP/SAP_REPORTING/Billing*
# rm src/SAP/SAP_REPORTING/ProfitCenter*
# echo "=====--Deleting custom cloud build instance types (not compatible with QL--==========="
# sed -i '/^PO/d' src/SAP/SAP_REPORTING/dependencies_ecc.txt
# sed -i '/^Purchase/d' src/SAP/SAP_REPORTING/dependencies_ecc.txt
# sed -i '/^Vendor/d' src/SAP/SAP_REPORTING/dependencies_ecc.txt
# sed -i '/^Account/d' src/SAP/SAP_REPORTING/dependencies_ecc.txt
# sed -i '/^Cost/d' src/SAP/SAP_REPORTING/dependencies_ecc.txt
# sed -i '/^Invoice/d' src/SAP/SAP_REPORTING/dependencies_ecc.txt
# # sed -i '/^Billing/d' src/SAP/SAP_REPORTING/dependencies_ecc.txt
# sed -i '/^ProfitCenter/d' src/SAP/SAP_REPORTING/dependencies_ecc.txt
# sed -i '/^GL/d' src/SAP/SAP_REPORTING/dependencies_ecc.txt
# sed -i '/^Ledger/d' src/SAP/SAP_REPORTING/dependencies_ecc.txt
# sed -i '/^ValuationCenter/d' src/SAP/SAP_REPORTING/dependencies_ecc.txt
# sed -i '/^DueDateFor/d' src/SAP/SAP_REPORTING/dependencies_ecc.txt
gcloud builds submit --project ${cortex_source_project} --substitutions _DEPLOY_SAP=${if_sap},_DEPLOY_SFDC=${if_sfdc},_GEN_EXT=${if_ext},_LOCATION=${location},_PJID_SRC=${cortex_source_project},_PJID_TGT=${cortex_target_project},_DS_CDC=${bq_processed_dataset},_DS_RAW=${bq_raw_dataset},_DS_REPORTING=${bq_reporting_dataset},_DS_MODELS=${bq_ml_dataset},_GCS_BUCKET=${logs_bucket},_TGT_BUCKET=${dags_bucket},_TEST_DATA=${if_test_data},_DEPLOY_CDC=${if_cdc_data},_MANDT=${sap_client} --timeout=10800 --async

