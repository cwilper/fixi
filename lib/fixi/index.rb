require 'sqlite3'

class Fixi::Index
  attr_reader :dotpath, :rootpath, :dbversion, :algorithms, :includes, :excludes

  def initialize(startpath, create=false, algorithms=nil)
    startpath = File.expand_path(startpath || ".")
    unless File.directory?(startpath)
      raise "No such file or directory: #{startpath}" unless File.exist?(startpath)
      startpath = File.dirname(startpath)
    end
    if create
      Fixi::digests(algorithms)
      @dotpath = File.join(startpath, ".fixi")
      raise "Index already exists at #{@dotpath}" if Dir.exist? @dotpath
      Dir.mkdir @dotpath
      @db = SQLite3::Database.new(File.join(@dotpath, "fixi.db"))
      @dbversion = 1
      @algorithms = algorithms
      ddl = <<-EOS
        create table fixi (
          dbversion text,
          algorithms text
        );
        create table file (
          relpath text primary key,
          size integer not null,
          mtime integer not null,
          md5 text,
          sha1 text,
          sha256 text,
          sha384 text,
          sha512 text
        );
        insert into fixi (dbversion, algorithms)
          values (#{@dbversion}, "#{@algorithms}");
      EOS
      @db.execute_batch ddl
      open(File.join(@dotpath, "includes"), "w") { |f| f.puts ".*" }
      open(File.join(@dotpath, "excludes"), "w") { |f| f.puts "^\\.fixi\\/" }
    else
      @dotpath = find_dotpath(startpath)
      @db = SQLite3::Database.new(File.join(@dotpath, "fixi.db"))
      @db.execute("select dbversion, algorithms from fixi") do |row|
        @dbversion = row[0]
        @algorithms = row[1]
      end
    end
    @includes = load_patterns("includes")
    @excludes = load_patterns("excludes")
    @rootpath = File.expand_path(File.join(@dotpath, ".."))
    @db.results_as_hash = true
  end

  # Traverse the given path within @rootdir and return all files
  # of interest (those matching @includes and not matching @excludes)
  def find(path)
    Find.find(path) do |abspath|
      relpath = relpath(abspath)
      if relpath.length > 0
        if matches_any?(relpath, @includes)
          if matches_any?(relpath, @excludes)
            Find.prune
          else
            yield abspath unless File.directory?(abspath)
          end
        else
          Find.prune unless File.directory?(abspath)
        end  
      end
    end
  end

  def file_in_scope(relpath)
    return matches_any?(relpath, @includes) &&
      not(matches_any?(relpath, @excludes))
  end

  def each(path=nil, attribs={}) 
    sql = "select * from file"
    conditions = []
    if path && File.expand_path(path) != @rootpath
      relpath = relpath(File.expand_path(path))
      if File.directory?(path)
        conditions << " relpath like '#{relpath}/%'"
      else
        conditions << " relpath = '#{relpath}'"
      end
    end
    attribs.each do |name,value|
      if value && (name == :size || name == :mtime ||
          name == :md5 || name == :sha1 || name == :sha256 ||
          name == :sha384 || name == :sha512)
        c = "#{name} = "
        c += value.is_a?(Numeric) ? "#{value}" : "'#{value}'"
        conditions << c
      end
    end
    unless conditions.size == 0
      sql += " where"
      conditions.each do |c|
        sql += " and" unless c == conditions.first
        sql += " #{c}"
      end
    end
    @db.execute(sql) do |hash|
      yield hash
    end
  end

  def size
    @db.get_first_value("select count(*) from file")
  end

  def contains?(relpath)
    @db.get_first_value("select count(*) from file where relpath = ?", relpath) > 0
  end

  def relpath(abspath)
    return "" if abspath == @rootpath
    abspath.slice(@rootpath.length + 1..-1)
  end

  def update(relpath, hash=nil)
    abspath = File.join(@rootpath, relpath) 
    unless hash
      hash = Hash.new
      hash['size'] = File.size(abspath)
      hash['mtime'] = File.mtime(abspath).to_i
      hexdigests = Fixi::hexdigests(Fixi::digests(@algorithms), abspath)
      i = 0
      @algorithms.split(',').each do |algorithm|
        hash[algorithm] = hexdigests[i]
      end
    end
    sql = "update file set size = #{hash['size']}, mtime = #{hash['mtime']}"
    @algorithms.split(',').each do |algorithm|
      sql += ", #{algorithm} = '#{hash[algorithm]}'"
    end 
    sql += " where relpath = ?" 
    @db.execute(sql, relpath)
  end

  def set_digest(relpath, alg, val)
    sql = "update file set #{alg} = '#{val}' where relpath = ?"
    @db.execute(sql, relpath)
  end

  def add(relpath, compute_checksums=true)
    abspath = File.join(@rootpath, relpath)
    sql = "insert into file (relpath, size, mtime"
    sql += ", " + @algorithms if compute_checksums
    sql += ") values (:relpath, :size, :mtime"
    values = Hash.new
    values[:relpath] = relpath
    values[:size] = File.size abspath
    values[:mtime] = File.mtime(abspath).to_i
    if compute_checksums
      hexdigests = Fixi::hexdigests(Fixi::digests(@algorithms), abspath)
      i = 0
      @algorithms.split(",").each do |alg|
        sql += ", '" + hexdigests[i] + "'"
        i += 1
      end
    end
    sql += ")"
    @db.execute(sql, values)
  end

  def delete(relpath)
    @db.execute("delete from file where relpath = ?", relpath)
  end

  def describe
    puts "#{size} files indexed at #{@dotpath}"
    puts "Using checksum algorithm(s) [#{@algorithms}]"
    puts "Fixi database version #{dbversion}"
  end

  def matches_any?(path, patterns)
    patterns.each do |pattern|
      return true if pattern.match(path)
    end
    return false
  end

  private

  def load_patterns(name)
    result = []
    f = File.join(@dotpath, name)
    if File.exists? f
      File.foreach(f) do |line|
        line = line.chomp
        result << Regexp.new(line) if line.length > 0
      end
    end
    result
  end

  # Return the first .fixi directory we find while traversing up the tree
  def find_dotpath(path, startpath=path)
    dotpath = File.join(path, ".fixi")
    return dotpath if Dir.exist?(dotpath)
    parent = File.dirname(path)
    return find_dotpath(parent, startpath) unless parent == path
    raise "No index at #{startpath} or any parent"
  end
end
