# puppetdb-rundeck

Based on the project https://github.com/martin2110/puppetdb-rundeck, modified to expose facts and add documentation.

sinatra app that glues puppetdb and rundeck together.

Requires sinatra

set host_url and cache_timeout (seconds) in the script

## Quick Start


### Docker

A docker container has been made which lets you very quickly start and test
out the puppetdb to rundeck intergration by simply running the following command.

```
  docker run \
    -e PUPPET_URL='http://your.puppet.db:8080/' \
    -e 'CACHE_SECONDS=300' \
    -p 3000:3000 \
    warmfusion/puppetdb2rundeck
```

|param|type|default|description|
|----|----|----|---|
|:PUPPET_URL|:string| http://puppet:8080/ | URL to your PuppetDB server |
|:CACHE_SECONDS|:integer|1800| How long to cache the facts about your servers |


## Installation

### Application Configuration

Create the directory structure for the application as follows:

/path/to/application

/path/to/application/public

The "public" directory should be empty.  The apache configuration (below) should use the public directory as the DocumentRoot.

Place both config.ru and puppetdb-rundeck.rb into the "application" directory. Edit puppetdb-rundeck.rb to set puppetdb_host and puppetdb_port to match your environment, as applicable.  Note that most installs of puppetdb will only listen to http:// requests from localhost.  SSL connections have not been tested.

### Apache Module and Configuration

Install Apache Module `phusion passenger` as [descirbed here](http://recipes.sinatrarb.com/p/deployment/apache_with_passenger)

Copy the puppetdb-rundeck.conf file into your apache's configuration directory (on RHEL, this is /etc/httpd/conf.d).

Mofify the file to ensure the path to the application's "public" directory is correct.  You may also change the listening port (default is 8888).

Restart apache (on RHEL/derivatives: service httpd restart)

## Usage

Within your rundeck project configuration, add a Resource Model Source of type "URL Source", pointing at the machine that this web application is running on, port 8888 (or whatever you've configured it to use per the Apache configuration)

Example:

URL Field: http://localhost:8888

Timeout: 90

Cache Results: Not checked

Any Jobs created under this Project should now have access to all nodes known by PuppetDB.

### Filtering

This plugin exposes both classes and facts of all nodes known by PuppetDB to Rundeck.  See the Rundeck documents on how to filter.  Puppet facts are exposed as Rundeck "Attributes", so to filter by all RedHat-derived machines, you could enter "osfamily: RedHat" into the filter field and it will show only nodes that PuppetDB knows to have that fact with that value.

All known facts exposed to Rundeck can be viewed by looking at the "nodes" tab and expanding any of the nodes listed below.  They are listed in the format of "Fact (attribute): Value".  Note that this list can be quite long depending on your environment.  This DOES include custom facts.
