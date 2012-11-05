#!/usr/bin/env rake


require 'rubygems'
require 'bundler'

Bundler.require

require 'rails'
require 'rspec'
require 'rspec/core/rake_task'

require "bundler/gem_tasks"


RSpec::Core::RakeTask.new(:spec)

task :default => :spec
