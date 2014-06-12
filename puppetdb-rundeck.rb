#!/usr/bin/env ruby
require 'rubygems'
require 'net/http'
require 'uri'
require 'json'
require 'yaml'
require 'sinatra'

# Base URL of the PuppetDB database.  Do not include a trailing slash!
host_uri = 'http://localhost'
# Port number for the PuppetDB REST interface -- default is 8080 for clear, 8081 for SSL.
port = '8080'

puppetdb_resource_query = {'query'=>'["=", "type", "Class"],]'}

before do
  response["Content-Type"] = "application/yaml"
end

get '/' do
	uri = URI.parse( "#{host_uri}:#{port}/v3/resources" )
	http = Net::HTTP.new(uri.host, uri.port) 
	request = Net::HTTP::Get.new(uri.path) 
	request.set_form_data( puppetdb_resource_query )
	request = Net::HTTP::Get.new( uri.path+ '?' + request.body ) 
	request.add_field("Accept", "application/json")
	response = http.request(request)
	puppetdb_data = JSON.parse(response.body)

	rundeck_resources = Hash.new
	puppetdb_data.each{|d|
	host     = d['certname']
	title    = d['title']
	rundeck_resources[host] = Hash.new if not rundeck_resources.key?(host)
	rundeck_resources[host]['tags'] = Array.new if not rundeck_resources[host].key?('tags')
	rundeck_resources[host]['tags'] << title
	}
	
	rundeck_resources.keys.sort.each { |k|
	rundeck_resources[k]['tags'].uniq!
	rundeck_resources[k]['tags'] =  rundeck_resources[k]['tags'].join(",")
	rundeck_resources[k]['hostname'] = k
	}
	
	uri = URI.parse( "#{host_uri}:#{port}/v3/facts" )
	http = Net::HTTP.new(uri.host, uri.port) 
	request = Net::HTTP::Get.new(uri.path) 
	request = Net::HTTP::Get.new(uri.path)
	request.add_field("Accept", "application/json")
	response = http.request(request)
	puppetdb_data = JSON.parse(response.body)
		
	puppetdb_data.each{|d|
	host     = d['certname']
	name     = d['name']
	value	 = d['value']
	rundeck_resources[host][name] = value
	}

	rundeck_resources.to_yaml
end
