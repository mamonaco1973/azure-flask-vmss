import json
import os
from flask import Flask, Response, request
from azure.cosmos import CosmosClient, exceptions
from azure.identity import DefaultAzureCredential

# Azure Cosmos DB Configuration
COSMOS_ENDPOINT = os.environ.get("COSMOS_ENDPOINT", "https://candidates-e4dee2.documents.azure.com:443/")
DATABASE_NAME = os.environ.get("COSMOS_DATABASE_NAME", "CandidateDatabase")
CONTAINER_NAME = os.environ.get("COSMOS_CONTAINER_NAME", "Candidates")

# Initialize Cosmos DB Client using DefaultAzureCredential
credential = DefaultAzureCredential()  # Automatically handles Managed Identity authentication
cosmos_client = CosmosClient(COSMOS_ENDPOINT, credential=credential)
database = cosmos_client.get_database_client(DATABASE_NAME)
container = database.get_container_client(CONTAINER_NAME)

# Flask app
candidates_app = Flask(__name__)
instance_id = os.popen("hostname -i").read().strip()

@candidates_app.route("/", methods=["GET"])
def default():
    return {"status": "invalid request"}, 400

@candidates_app.route("/gtg", methods=["GET"])
def gtg():
    details = request.args.get("details")

    if "details" in request.args:
        return {"connected": "true", "instance-id": instance_id}, 200
    else:
        return Response(status=200)

@candidates_app.route("/candidate/<name>", methods=["GET"])
def get_candidate(name):
    try:
        # Query the Cosmos DB container for the candidate
        query = "SELECT c.CandidateName FROM c WHERE c.CandidateName = @name"
        parameters = [{"name": "@name", "value": name}]
        response = list(container.query_items(query=query, parameters=parameters, enable_cross_partition_query=True))

        if not response:
            raise Exception

        return json.dumps(response), 200
    except:
        return "Not Found", 404

@candidates_app.route("/candidate/<name>", methods=["POST"])
def post_candidate(name):
    try:
        item={"id": name,"CandidateName": name}
        container.upsert_item(item)
    except exceptions.CosmosHttpResponseError as ex:
        return f"Unable to update: {str(ex)}", 500

    return {"CandidateName": name}, 200

@candidates_app.route("/candidates", methods=["GET"])
def get_candidates():
    try:
        # Retrieve all candidates from the Cosmos DB container
        query = "SELECT c.CandidateName FROM c"
        response = list(container.query_items(query=query, enable_cross_partition_query=True)) 
        return json.dumps(response), 200
    except:
        return "Not Found", 404
