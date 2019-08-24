#!/usr/bin/env bash
# This is the code that will be used to set up the server when it is first created

set -e

# TODO: Set to URL of git repo.
# Update the existing url with your git repository url because the script is going to
# clone the contents of our project to the server when we run it
PROJECT_GIT_URL='https://github.com/deepthoughtstech/profiles-rest-api.git'

# Durectory in which we store our project on the server
PROJECT_BASE_PATH='/usr/local/apps/profiles-rest-api'

echo "Installing dependencies..."
apt-get update
apt-get install -y python3-dev python3-venv sqlite python-pip supervisor nginx git

# Create project directory
mkdir -p $PROJECT_BASE_PATH
git clone $PROJECT_GIT_URL $PROJECT_BASE_PATH

# Create virtual environment
mkdir -p $PROJECT_BASE_PATH/env
python3 -m venv $PROJECT_BASE_PATH/env

# Install python packages
$PROJECT_BASE_PATH/env/bin/pip install -r $PROJECT_BASE_PATH/requirements.txt

# uwsgi is a pyhton Daemon for running python code as a web server
$PROJECT_BASE_PATH/env/bin/pip install uwsgi==2.0.18

# Run migrations and collectstatic
cd $PROJECT_BASE_PATH
$PROJECT_BASE_PATH/env/bin/python manage.py migrate

# Collect static will collect all the static files for all the apps in our
# project into one single directory
$PROJECT_BASE_PATH/env/bin/python manage.py collectstatic --noinput

# Configure supervisor
cp $PROJECT_BASE_PATH/deploy/supervisor_profiles_api.conf /etc/supervisor/conf.d/profiles_api.conf
supervisorctl reread
supervisorctl update
supervisorctl restart profiles_api

# Configure nginx
# Create a location for the configuration file and copy the configuration file that
# we have added here
cp $PROJECT_BASE_PATH/deploy/nginx_profiles_api.conf /etc/nginx/sites-available/profiles_api.conf

# Remove the default configuration
rm /etc/nginx/sites-enabled/default

# Add a symbolic link from our sites available to sites enabled to enable our site
ln -s /etc/nginx/sites-available/profiles_api.conf /etc/nginx/sites-enabled/profiles_api.conf

# Finally we restart the nginx server
systemctl restart nginx.service

echo "DONE! :)"
