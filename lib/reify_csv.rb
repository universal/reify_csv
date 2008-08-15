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
    # make it accepting find options
    # make it possible to include has_one/belongs_to associations
    def to_csv
      csv_string = FasterCSV.generate do |csv|
        objects = self.find(:all)
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
  end
  
  # implement
  # make it play nicely, similarly to to_csv
  # simulate option, where it just checks the data
  # possibly add create_from_csv
  def update_from_csv
    puts "fiibbb"
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
