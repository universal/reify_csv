module ReifyCSV
  def self.included(base)
    base.extend ClassMethods
    class << base
      define_method(:csv_columns) {["id"] + content_columns.map{|cc| cc.name} - ["created_at", "updated_at"]} unless respond_to?(:csv_columns)
    end
  end
 
#  def csv_data
#    csv_string = FasterCSV.generate do |csv|
#      data = []
#      self.class.content_columns.each do |a|
#        data << self[a.name]  unless a.name == "deleted_at"
#      end
#      
#      associated = self.class.reflect_on_all_associations(:has_one).sort_by{|b| b.name.to_s.gsub(/([a-z])([0-9]{1})(?!\d)/, '\10\2')}
#      associated.each do |assoc|
#        a,b = assoc.options[:class_name].split("::")
#        klass = Kernel.const_get(a).const_get(b)
#        heinz = self.send(assoc.name)
#        klass.content_columns.each do |cc|
#          data <<  heinz[cc.name] if heinz && cc.name != "deleted_at"
#          data << nil unless heinz
#        end
#      end
#      csv << data
#    end
#  end
  
  module ClassMethods
    # add it to associations where suitable, has_many
  
    # make it accepting find options
    # make it possible to include has_one/belongs_to associations
    def to_csv(*args)
      options = args.pop
      options ||= {}
      columns = rcsv_parse_export_options(options)
      # remove select option for now, might bork 
      find_options = options.except :columns, :select
      args << find_options
#     properly escape the fields probably
#      args << find_options.merge({:select => columns.join(", ")})
      csv_string = FasterCSV.generate do |csv|
        csv << self.csv_columns
        objects = self.find(:all, *args)
        objects.each do |object|
          data = []
          self.csv_columns.each do |col|
            data << object[col]
          end
          csv << data
        end
      end
      csv_string
    end
  
    # implement
    # make it play nicely, similarly to to_csv
    # simulate option, where it just checks the data
    # possibly add create_from_csv
    def update_from_csv(csv_src, *args)
      options = args.pop
      options ||= {}
      headers, find_by, simulate, file = rcsv_parse_import_options(options)
      puts "file? #{file}"
      errors = Hash.new([])
      if file
        data = FasterCSV.read(csv_src, :headers => headers)
      else
        data = FasterCSV.parse(csv_src, :headers => headers)
      end
      if headers
        # check if to_s is necessary
        raise(ArgumentError, "'Find by' columns specified are not included in the actual data.") if find_by.any?{|col| !data.headers.include?(col.to_s)}
        raise(ArgumentError, "'Find by' columns are not model attributes") if find_by.any?{|col| !column_names.include?(col.to_s) }
        i = 0
        
        finder = "find_by_" + find_by.map{|col| col.to_s}.join("_and_")
        data_columns = (data.headers - find_by.map{|col| col.to_s}).reject{|col| !column_names.include?(col.to_s)}        
        data.each do |row|
          if updateable = send(finder, *find_by.map{|col| row[col.to_s]})
            data_columns.each {|col| updateable[col] = row[col]}
            if updateable.valid?
              updateable.save unless simulate
            else
              errors[:invalid] << row
            end
          else
            errors[:not_found] << row
            # record not found ;)
            # TODO add handling for that here, probably creation of a new record?
          end
        end
      else
        # without headers, TODO...
      end
      [data.size, errors]
    end

    def rcsv_parse_export_options(options) #:nodoc:
      raise ArgumentError, 'parameter hash expected' unless options.respond_to? :symbolize_keys
      options = options.symbolize_keys
     # raise ArgumentError, ':page parameter required' unless options.key? :page
      
  #    if options[:count] and options[:total_entries]
  #      raise ArgumentError, ':count and :total_entries are mutually exclusive'
  #    end

      columns = options[:columns] || self.csv_columns
  #    per_page = options[:per_page] || self.per_page
  #    total = options[:total_entries]
      columns
    end
    
    def rcsv_parse_import_options(options) #:nodoc:
      raise ArgumentError, 'parameter hash expected' unless options.respond_to? :symbolize_keys
      options = options.symbolize_keys
      headers = options.include?(:headers) ? options[:headers] : true
      find_by = options.include?(:find_by) ? options[:find_by] : [:id]
      simulate = options.include?(:simulate) ? options[:simulate] : false
      file = options.include?(:file) ? options[:file] : true
      [headers, find_by, simulate, file]
    end
  
  end
  
#def self.check_csv_update_data(csv_src) 
#    associated = get_associated.collect{|a| [a.class_name.constantize, a.name]}
#    data = FasterCSV.read(csv_src, :headers => true)
#    headers = data.headers
#    cc = content_columns.collect{|c| c.name}.select{|c| c != "deleted_at" && c != "created_at"}
#    assoc_cc = {}
#    associated.each do |klass, name| 
#      assoc_cc[name] = klass.content_columns.collect{|c| c.name}.select{|c| c != "deleted_at" && c != "created_at"}      
#    end
#    
#    i = 0
#    data.each do |row|
#      updateable = nil
#      upd1 = find(row["id"])
#      if (upd1.nil? && upd2.nil?) 
#        print "N"
#      elsif (upd1.eql? upd2)
#        i = i + 1
#        print "."
#      else
#        print "F"
#      end
#    end
#    puts "#{i} of #{data.size} seem to be valid entries"
#  end
#  
#  def self.update_from_csv(csv_src)
#    associated = get_associated.collect{|a| [a.class_name.constantize, a.name]}
#    data = FasterCSV.read(csv_src, :headers => true)
#    headers = data.headers
#    cc = columns.collect{|c| c.name}.select{|c| c != "deleted_at" && c != "created_at" && c != "questionnaire_user_id"}
#    assoc_cc = {}
#    associated.each do |klass, name| 
#      assoc_cc[name] = klass.content_columns.collect{|c| c.name}.select{|c| c != "deleted_at" && c != "created_at"}      
#    end
#    
#    id = headers.include?("id")
#    i = 0
#    data.each do |row|
#      updateable = nil
#      if id
#        updateable = find(row["id"])
#      else
#        ## TODO find_by_Interviewer_and_InterviewPartner
#        updateable = find_by_Interviewer_and_InterviewPartner(row["Interviewer"], row["InterviewPartner"])
#      end
#      cc.each { |col| updateable[col] = row[col] if headers.include?(col) }
#      assoc_cc.each do |as, as_cc|
#        as_upd = (updateable.send(as) ? updateable.send(as) : updateable.send("build_#{as}"))
#        as_cc.each { |col| as_upd[col] = row[col] if headers.include?(col) }
#        as_upd.save
#      end  
#      unless updateable.save
#        puts "Error on: " << updateable.id.to_s
#        puts updateable.errors
#      end
#      puts "#{i = i + 1} / #{data.size} updated"
#    end
#    42
#  end


#    def to_csv
#      objects = self.find(:all, :include => self.reflect_on_all_associations(:has_one).sort_by{|b| b.name.to_s.gsub(/([a-z])([0-9]{1})(?!\d)/, '\10\2')}.collect{|p| p.name}) 
#      csv_string = FasterCSV.generate do |csv|
#        csv << self.csv_headings
#        objects.each do |o|
#          csv << o.csv_data
#        end
#      end
#      csv_string
#    end
#  end
end
