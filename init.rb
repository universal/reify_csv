# Include hook code here
config.gem 'fastercsv'
#require 'rails_diff'
config.after_initialize do
  # Include our helper into every view
  ActiveRecord::Base.send :include, ReifyCSV
end
