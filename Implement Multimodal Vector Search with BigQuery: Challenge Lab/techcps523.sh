

gcloud auth list

gcloud services enable aiplatform.googleapis.com

export REGION=$(gcloud compute project-info describe --format="value(commonInstanceMetadata.items[google-compute-default-region])")

export PROJECT_ID=$(gcloud config get-value project)

bq mk --connection --location=$REGION --project_id=$PROJECT_ID --connection_type=CLOUD_RESOURCE vector_conn

SERVICE_ACCOUNT=$(bq show --format=json --connection $PROJECT_ID.$REGION.vector_conn | jq -r '.cloudResource.serviceAccountId')
echo "Service Account: $SERVICE_ACCOUNT"

gcloud projects add-iam-policy-binding $PROJECT_ID \
  --member="serviceAccount:$SERVICE_ACCOUNT" \
  --role="roles/bigquery.dataOwner"

gcloud projects add-iam-policy-binding $PROJECT_ID \
  --member="serviceAccount:$SERVICE_ACCOUNT" \
  --role="roles/storage.objectViewer"

gcloud projects add-iam-policy-binding $PROJECT_ID \
  --member="serviceAccount:$SERVICE_ACCOUNT" \
  --role="roles/aiplatform.user"


sleep 20

# Task 2


bq query --use_legacy_sql=false "
CREATE OR REPLACE EXTERNAL TABLE \`${PROJECT_ID}.gcc_bqml_dataset.gcc_image_object_table\`
WITH CONNECTION \`${REGION}.vector_conn\`
OPTIONS (
  object_metadata = 'SIMPLE',
  uris = ['gs://${PROJECT_ID}/*']
)"


sleep 10

# TAsk 3


bq query --use_legacy_sql=false "
CREATE OR REPLACE MODEL \`${PROJECT_ID}.gcc_bqml_dataset.gcc_embedding\`
REMOTE WITH CONNECTION \`${REGION}.vector_conn\`
OPTIONS (
  endpoint = 'multimodalembedding@001'
);"


sleep 10

bq query --use_legacy_sql=false "
CREATE OR REPLACE TABLE \`${PROJECT_ID}.gcc_bqml_dataset.gcc_retail_store_embeddings\` AS
SELECT *, REGEXP_EXTRACT(uri, r'[^/]+$') AS product_name
FROM ML.GENERATE_EMBEDDING(
  MODEL \`${PROJECT_ID}.gcc_bqml_dataset.gcc_embedding\`,
  TABLE \`${PROJECT_ID}.gcc_bqml_dataset.gcc_image_object_table\`
);"


sleep 10

bq show --format=prettyjson ${PROJECT_ID}:gcc_bqml_dataset.gcc_retail_store_embeddings


sleep 10

# Task 4

bq query --use_legacy_sql=false "
CREATE OR REPLACE TABLE \`${PROJECT_ID}.gcc_bqml_dataset.gcc_vector_search_table\` AS
SELECT
  base.uri,
  base.product_name,
  base.content_type,
  distance
FROM
  VECTOR_SEARCH(
    TABLE \`${PROJECT_ID}.gcc_bqml_dataset.gcc_retail_store_embeddings\`,
    'ml_generate_embedding_result',
    (
      SELECT
        ml_generate_embedding_result AS embedding_col
      FROM
        ML.GENERATE_EMBEDDING(
          MODEL \`${PROJECT_ID}.gcc_bqml_dataset.gcc_embedding\`,
          (SELECT 'Men Sweaters' AS content),
          STRUCT(TRUE AS flatten_json_output)
        )
    ),
    top_k => 3,
    distance_type => 'COSINE'
  );
"

sleep 20


# TAsk 3


bq query --use_legacy_sql=false "
CREATE OR REPLACE MODEL \`${PROJECT_ID}.gcc_bqml_dataset.gcc_embedding\`
REMOTE WITH CONNECTION \`${REGION}.vector_conn\`
OPTIONS (
  endpoint = 'multimodalembedding@001'
);"


sleep 10

bq query --use_legacy_sql=false "
CREATE OR REPLACE TABLE \`${PROJECT_ID}.gcc_bqml_dataset.gcc_retail_store_embeddings\` AS
SELECT *, REGEXP_EXTRACT(uri, r'[^/]+$') AS product_name
FROM ML.GENERATE_EMBEDDING(
  MODEL \`${PROJECT_ID}.gcc_bqml_dataset.gcc_embedding\`,
  TABLE \`${PROJECT_ID}.gcc_bqml_dataset.gcc_image_object_table\`
);"


sleep 10

bq show --format=prettyjson ${PROJECT_ID}:gcc_bqml_dataset.gcc_retail_store_embeddings


sleep 10

# Task 4

bq query --use_legacy_sql=false "
CREATE OR REPLACE TABLE \`${PROJECT_ID}.gcc_bqml_dataset.gcc_vector_search_table\` AS
SELECT
  base.uri,
  base.product_name,
  base.content_type,
  distance
FROM
  VECTOR_SEARCH(
    TABLE \`${PROJECT_ID}.gcc_bqml_dataset.gcc_retail_store_embeddings\`,
    'ml_generate_embedding_result',
    (
      SELECT
        ml_generate_embedding_result AS embedding_col
      FROM
        ML.GENERATE_EMBEDDING(
          MODEL \`${PROJECT_ID}.gcc_bqml_dataset.gcc_embedding\`,
          (SELECT 'Men Sweaters' AS content),
          STRUCT(TRUE AS flatten_json_output)
        )
    ),
    top_k => 3,
    distance_type => 'COSINE'
  );
"

