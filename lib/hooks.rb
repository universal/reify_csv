class Array
  # TODO compare to rails Hash.to_xml function, make it more similar
  # Equivalent to <tt>FasterCSV::generate_line(self, options)</tt>.
  def to_csv(options = Hash.new)
    raise ArgumentError, 'parameter hash expected' unless options.respond_to? :symbolize_keys
    options = options.symbolize_keys
    if self.all?{|element| element.kind_of? ActiveRecord::Base}
      cols = options[:columns] || self.first.class.csv_columns
      FasterCSV.generate(options.except(:columns)) do |csv|
        csv << cols
        self.each{|element| csv << element.generate_line({:columns => cols})}
      end
    elsif self.all?{|element| element.kind_of? Array}
      FasterCSV.generate(options) do |csv|
        self.each{|element| csv << element}
      end
    else
      FasterCSV.generate_line(self, options)    
    end
  end
end

class ActiveRecord::Associations::HasManyAssociation
  def to_csv
    puts "i got called! i'm here!'"
    puts @reflection.inspect
    inspect
  end
end
