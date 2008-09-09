class Array
  # Equivalent to <tt>FasterCSV::generate_line(self, options)</tt>.
  def to_csv(options = Hash.new)
    raise ArgumentError, 'parameter hash expected' unless options.respond_to? :symbolize_keys
    options = options.symbolize_keys
    if self.all?{|element| element.kind_of? ActiveRecord::Base}
      has_cols = options.has_key? :columns
      cols = options[:columns]
      FasterCSV.generate(options.except(:columns)) do |csv|
        self.each{|element| csv << (has_cols ? element.generate_line({:columns => cols}) : element.generate_line)}
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
