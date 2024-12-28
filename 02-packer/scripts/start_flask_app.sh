#!/usr/bin/bash
cd /flask
export COSMOS_ENDPOINT="$COSMOS_ENDPOINT"
/usr/local/bin/gunicorn -b 0.0.0.0 app:candidates_app

