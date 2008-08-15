namespace :reify_csv do
    desc "Dump data to csv file"
    task :export => :environment do
      if model = get_model
        pre
        create_file_for_model(model)
      else
        puts "model not found"
      end
    end
    
    desc "Import csv data"
   	task :import => :environment do
  		if model = get_model
    		if valid_source?
    		  Agribusiness.update_from_csv(ENV["SOURCE"])
    		else
    		  puts "File not found!"
		    end
      end
  	end
  	
  
  
#  helper functions
  private
  def pre
    unless File.directory?("dump")
      puts "dump dir not found, creating directory for csv files now"
      FileUtils.makedirs("dump")
    end
  end
  
  def create_file_for_model(model)
    puts "Creating csv-dump for #{model.to_s}"
    f = File.new('dump/' + model.to_s.pluralize.underscore + '.csv','w')
    puts model.to_csv
    f.puts model.to_csv 
  end
  
  def get_model
    if ENV["MODEL"] 
      begin
        model = ENV["MODEL"].constantize
        return model if (model.respond_to?(:to_csv) && model.respond_to?(:update_from_csv))
      rescue NameError
        puts "#{ENV['MODEL']} is not a valid one."
      end
    else 
      puts "specify model env"
    end
    return nil
  end
  
  def valid_source?
    ENV["SOURCE"] && File.file?(ENV["SOURCE"])
  end
end
