require_relative 'db_connection'
require_relative '01_sql_object'

module Searchable
  def where(params)
    # p things_to_return = params.keys.map(&:to_s).join(", ")
    p where_line = params.map{|pair| "#{pair[0]} = ?"}.join(" AND ")
    p arg = params.values
    ans = DBConnection.execute(<<-SQL, *arg)
      SELECT
        *
      FROM
        #{self.table_name}
      WHERE
        #{where_line}
    SQL
    self.parse_all(ans)
  end
end

class SQLObject
  extend Searchable
  # Mixin Searchable here...
end
