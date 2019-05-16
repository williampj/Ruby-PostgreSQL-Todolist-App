require "pry"
require "pg"

class DatabasePersistence
  def initialize(logger)
    @db = if Sinatra::Base.production?
        PG.connect(ENV['DATABASE_URL'])
      else
        PG.connect(dbname: "todos")
      end
    @logger = logger
  end

  def disconnect 
    @db.close #alias finish
  end 

  # Outputs our SQL statement in the terminal and executes it
  def query(statement, *params)
    @logger.info "#{statement}: #{params}"
    @db.exec_params(statement, params)
  end 

  def find_list(id) 
    sql = "SELECT * FROM lists WHERE id = $1;"
    result = query(sql, id)  
    proper_list_format(result).first # returns the hash within the one-element array
  end

  def all_lists
    sql = <<~SQL 
      SELECT * FROM lists; 
    SQL
    result = query(sql)
    proper_list_format(result)
  end

  def create_new_list(list_name)
    sql = "INSERT INTO lists(name) 
           VALUES($1);"
    query(sql, list_name)
  end

  def delete_list(id)
    sql = " DELETE FROM lists
             WHERE id = $1;"
    query(sql, id)
  end

  def update_list_name(id, new_name)
    sql = "UPDATE lists
              SET name = $1
            WHERE id = $2;"
    query(sql, new_name, id)
  end

  def create_new_todo(list_id, todo_name)
    sql = "INSERT INTO todo(name, list_id)
           VALUES($1, $2)"
    query(sql, todo_name, list_id)
  end

  def delete_todo_from_list(list_id, todo_id)
    sql = "DELETE FROM todo 
            WHERE id = $1
              AND list_id = $2;" # More specific is better
    query(sql, todo_id, list_id)
  end

  def update_todo_status(list_id, todo_id, new_status)
    sql = 
    "UPDATE todo 
        SET completed = $1
      WHERE id = $2
        AND list_id = $3;" 
    query(sql, new_status, todo_id, list_id)
  end

  def mark_all_todos_as_completed(list_id) 
    sql = "UPDATE todo 
              SET completed = true
            WHERE list_id = $1;"
    query(sql, list_id)
  end

  private 

  def proper_list_format(result)
    result.map do |tuple| 
      todos = todos_from_list(tuple['id'])  # setting correct data structure (array of
      { id: tuple['id'].to_i,               # hashes), keys (symbols) and values so that   
        name: tuple['name'],                # rest of program can remain unaltered. 
        todos: todos }  
    end
  end 

  def todos_from_list(list_id)
    sql = "SELECT * FROM todo WHERE list_id = $1" # never interpolate directly into SQL 
    result = query(sql, list_id)
    result.map do |tuple|         # setting correct data structure (array of
      { id: tuple['id'].to_i,     # hashes) and correct classes of keys/values so
        name: tuple['name'],      # it works seamlessly with rest of program.
        list_id: tuple['list_id'].to_i,
        completed: tuple['completed'] == 't' } # ensures it will be a boolean value
    end 
  end 
end
