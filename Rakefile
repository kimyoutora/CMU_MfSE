require File.expand_path('../config/application', __FILE__)
require 'rake'

# TODO: see if this code is still required to make rake work in 1.9.2
class Rails::Application
  include Rake::DSL if defined?(Rake::DSL)
end

CMUEducation::Application.load_tasks

# Metric_fu
require 'metric_fu'
MetricFu::Configuration.run do |config|
  config.rcov[:test_files] = ['spec/**/*_spec.rb']
  config.rcov[:rcov_opts] << "-Ispec" # Needed to find spec_helper

  #define which metrics you want to use
  # config.metrics  = [:churn, :saikuro, :stats, :flog, :flay]
  config.metrics  = [:stats, :rcov, :flay]
  config.graphs   = [:flog, :flay, :stats]
end
