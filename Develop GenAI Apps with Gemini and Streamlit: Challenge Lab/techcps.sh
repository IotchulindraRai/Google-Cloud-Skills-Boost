
gcloud auth list

export REGION=$(gcloud compute project-info describe \
--format="value(commonInstanceMetadata.items[google-compute-default-region])")

gcloud services enable run.googleapis.com --project $DEVSHELL_PROJECT_ID

git clone https://github.com/GoogleCloudPlatform/generative-ai.git

cd generative-ai/gemini/sample-apps/gemini-streamlit-cloudrun

gsutil cp gs://spls/gsp517/chef.py .

rm -rf Dockerfile chef.py requirements.txt

wget https://raw.githubusercontent.com/Techcps/GSP/master/Develop%20GenAI%20Apps%20with%20Gemini%20and%20Streamlit%3A%20Challenge%20Lab/Dockerfile.txt

wget https://raw.githubusercontent.com/Techcps/GSP/master/Develop%20GenAI%20Apps%20with%20Gemini%20and%20Streamlit%3A%20Challenge%20Lab/chef.py

wget https://raw.githubusercontent.com/Techcps/GSP/master/Develop%20GenAI%20Apps%20with%20Gemini%20and%20Streamlit%3A%20Challenge%20Lab/requirements.txt

mv Dockerfile.txt Dockerfile

gcloud storage cp chef.py gs://$DEVSHELL_PROJECT_ID-generative-ai/

GCP_PROJECT=$(gcloud config get-value project)
GCP_REGION=$(gcloud compute project-info describe --format="value(commonInstanceMetadata.items[google-compute-default-region])")

# Set the python virtual environment and install the dependencies
python3 -m venv gemini-streamlit
source gemini-streamlit/bin/activate
python3 -m  pip install -r requirements.txt


# Run the chef.py application
streamlit run chef.py \
  --browser.serverAddress=localhost \
  --server.enableCORS=false \
  --server.enableXsrfProtection=false \
  --server.port 8080
