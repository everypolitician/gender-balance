#!/bin/bash

set -e

# Add Brightbox Ruby PPA
sudo apt-get update
sudo DEBIAN_FRONTEND=noninteractive apt-get install -y software-properties-common
sudo apt-add-repository ppa:brightbox/ruby-ng
sudo apt-get update

# Install required packages
sudo DEBIAN_FRONTEND=noninteractive apt-get install -y \
  ruby2.2 ruby2.2-dev git build-essential libxslt1-dev libssl-dev \
  postgresql libpq-dev memcached redis-server

sudo -u postgres createuser --createdb vagrant
createdb gender_crowdsourcing_development
createdb gender_crowdsourcing_test

# Add cd /vagrant to ~/.bashrc
grep -qG "cd /vagrant" "$HOME/.bashrc" || echo "cd /vagrant" >> "$HOME/.bashrc"
cd /vagrant

[[ -f .env ]] || cp .env.example .env

# Install application gems
sudo gem install bundler foreman pry --no-rdoc --no-ri
bin/bootstrap

# Set shell login message
echo "-------------------------------------------------------
Welcome to your vagrant machine

Run the web server with:
  foreman start

Then visit http://localhost:5000/

Note that changes to app.rb will only be picked up
after restarting the server. Template changes will be
picked up on every page load without needing to
restart.

Run the tests with:
  bundle exec rake test

-------------------------------------------------------
" | sudo tee /etc/motd > /dev/null

if grep -q replace_with_ .env; then
  echo "Incomplete .env file detected. Please follow README.md instructions to fill it in."
fi
