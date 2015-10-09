#!/usr/bin/env ruby
require 'rubygems'
require 'net/http'
require 'uri'
require 'json'
require 'yaml'
require 'sinatra'

# Base URL of the PuppetDB database.  Do not include a trailing slash!
HOST_URL = 'http://localhost:8080'
# Number of seconds to cache the previous results for
CACHE_SECONDS = 60

class PuppetDB

  def initialize
    @resources = nil
    @facts = nil
    @resources_fetched_at = nil
    @facts_fetched_at = nil
  end

  def get_json(url, form_data = nil)
		uri = URI.parse( url )
		http = Net::HTTP.new(uri.host, uri.port) 

		request = Net::HTTP::Get.new(uri.path) 
		if form_data 
			request.set_form_data( form_data )
			request = Net::HTTP::Get.new( uri.path+ '?' + request.body ) 
		end
		request.add_field("Accept", "application/json")

		response = http.request(request)
		json = JSON.parse(response.body)
  end

  def resources
    if !@resources_fetched_at || Time.now > @resources_fetched_at + CACHE_SECONDS
#    	puts "Getting new PuppetDB resources: #{Time.now} > #{@resources_fetched_at} + #{CACHE_SECONDS}"
      @resources = get_resources
      @resources_fetched_at = Time.now
		end
		@resources
  end

  def get_resources
		puppetdb_resource_query = {'query'=>'["=", "type", "Class"],]'}
		url = "#{HOST_URL}/v3/resources"
		resources = get_json(url, puppetdb_resource_query)
  end

  def facts
    if !@facts_fetched_at || Time.now > @facts_fetched_at + CACHE_SECONDS
#    	puts "Getting new PuppetDB facts: #{Time.now} > #{@facts_fetched_at} + #{CACHE_SECONDS}"
      @facts = get_facts
      @facts_fetched_at = Time.now
		end
		@facts
  end

  def get_facts
		url = "#{HOST_URL}/v3/facts"
		facts = get_json(url)
  end
end

class Rundeck
  def initialize(puppetdb)
    @resources = Hash.new
    @resources_built_at = nil
    @puppetdb = puppetdb
  end

  def puppetdb
  	@puppetdb
  end

  def build_resources
  	resources = Hash.new
		@puppetdb.resources.each do |d| 
			host     = d['certname']
			title    = d['title']
			resources[host] = Hash.new if !resources.key?(host)
			resources[host]['tags'] = Array.new if !resources[host].key?('tags')
			resources[host]['tags'] << title
		end

		resources.keys.sort.each do |k|
			resources[k]['tags'].uniq!
			resources[k]['tags'] =  resources[k]['tags'].join(",")
			resources[k]['hostname'] = k
		end

		@puppetdb.facts.each do |d|
			host     = d['certname']
			if d['name'] != "hostname"
				name  = d['name']
		    value = d['value'] if d['name'] != "hostname"
		    if ( name == 'serialnumber' )
		      resources[host][name] = 'Serial Number ' + value
		    else
					resources[host][name] = value
				end
			end
		end
		resources
  end

  def resources
  	if !@resources_built_at || Time.now > @resources_built_at + CACHE_SECONDS
  		@resources = build_resources
	  	@resources_built_at = Time.now
  	end
		@resources
  end
end

puppetdb = PuppetDB.new
rundeck  = Rundeck.new(puppetdb)

before do
  response["Content-Type"] = "application/yaml"
end

get '/' do
	rundeck.resources.to_yaml
end
