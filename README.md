# Gender Balance

[![Build Status](https://travis-ci.org/everypolitician/gender-balance.svg?branch=master)](https://travis-ci.org/everypolitician/gender-balance)

Crowdsourcing platform for gathering gender information about politicians to improve the data in [EveryPolitician](http://everypolitician.org).

## Installation

Get the code from GitHub

    git clone https://github.com/everypolitician/gender-balance
    cd gender-balance

Configure the environment by copying `.env.example` and following the instructions inside to configure the app.

    cp .env.example .env
    vi .env

Then use vagrant to build a VM with all the dependencies installed:

    vagrant up

## Usage

Log in to the vagrant VM and start the app server and worker with foreman:

    vagrant ssh
    foreman start

Then visit <http://localhost:5000> to view the app.

To run the tests use the following:

    vagrant ssh
    bundle exec rake test
