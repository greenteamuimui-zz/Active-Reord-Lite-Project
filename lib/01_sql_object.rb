require_relative 'db_connection'
require 'active_support/inflector'
# NB: the attr_accessor we wrote in phase 0 is NOT used in the rest
# of this project. It was only a warm up.

class SQLObject
  def self.columns
    return @columns if @columns
    entire = DBConnection.execute2(<<-SQL).first
      SELECT
        *
      FROM
        #{self.table_name}
    SQL
    @columns = entire.map(&:to_sym)
  end

  def self.finalize!
    self.columns.each do |column|
      define_method(column) {self.attributes[column]}
      define_method("#{column}=") do |value|
        self.attributes[column] = value
      end
    end
  end

  def self.table_name=(table_name)
    @table_name = "#{table_name}"
  end

  def self.table_name
    if @table_name.nil?
      "#{self}".tableize
    else
      @table_name
    end
  end

  def self.all
    hash = DBConnection.execute(<<-SQL)
    SELECT
      *
    FROM
      #{self.table_name}
    SQL
    self.parse_all(hash)
  end

  def self.parse_all(results)
    ans = []
    results.each do |hash|
      ans << self.new(hash)
    end
    ans
  end

  def self.find(id)
    ans = DBConnection.execute(<<-SQL, id)
    SELECT
      *
    FROM
      #{self.table_name}
    WHERE
      #{self.table_name}.id = ?
    SQL
    self.parse_all(ans).first
    # self.all.find_by{|obj| obj.id == id }
  end

  def initialize(params = {})
    params.each do |pair|
      raise "unknown attribute '#{pair[0]}'" unless self.class.columns.include?(pair[0].to_sym)
      self.send("#{pair[0]}=", pair[-1])
    end
  end

  def attributes
    @attributes ||= {}
  end

  def attribute_values
    self.class.columns.map {|col_name| self.send(col_name)}
  end

  def insert
    p col_names = self.class.columns.join(" ,")
    p question_marks = (["?"]*(self.class.columns.length)).join(" ,")

    DBConnection.execute(<<-SQL, *attribute_values)
    INSERT INTO
      #{self.class.table_name} (#{col_names})
    VALUES
      (#{question_marks})
    SQL
    self.id = DBConnection.last_insert_row_id
  end

  def update
    p col_set = self.class.columns.drop(1).map{|name| "#{name} = ?" }.join(", ")
    var = attribute_values.drop(1)
    DBConnection.execute(<<-SQL, *var, id)
    UPDATE
      #{self.class.table_name}
    SET
      #{col_set}
    WHERE
      id = ?
    SQL
  end

  def save
    if self.class.find(id).nil?
      self.insert
    else
      self.update
    end

  end
end
