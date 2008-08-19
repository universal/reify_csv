module ReifyCSV
  def self.included(base)
    base.extend ClassMethods
    class << base
      define_method(:csv_columns) {["id"] + content_columns.map{|cc| cc.name} - ["created_at", "updated_at"]} unless respond_to?(:csv_columns)
    end
  end
  
  def generate_line(options = Hash.new)
    columns = options[:columns] || self.class.csv_columns
    columns.map{|col| self[col]}
  end
  
  module ClassMethods
    # convert Header cols to symbols!
    # add it to associations where suitable, has_many
  
    # make it accepting find options
    # make it possible to include has_one/belongs_to associations
    def to_csv(*args)
      options = args.pop || {}
      columns, finder = rcsv_parse_export_options(options)
      # remove select option for now, might bork 
      find_options = options.except :columns, :select
#     probably escape the fields properly...
      args << find_options.merge({:select => columns.join(", ")})
      csv_string = FasterCSV.generate do |csv|
        csv << columns
        objects = self.find(:all, *args)
        objects.each{|object| csv << object.generate_line({:columns => columns})}
      end
      csv_string
    end
  
    # implement
    # make it play nicely, similarly to to_csv
    # simulate option, where it just checks the data
    # possibly add create_from_csv
    def update_from_csv(csv_src, *args)
      options = args.pop ||  {}
      headers, find_by, simulate, file = rcsv_parse_import_options(options)
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
      finder = options[:finder]
  #    per_page = options[:per_page] || self.per_page
  #    total = options[:total_entries]
      [columns, finder]
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
end
