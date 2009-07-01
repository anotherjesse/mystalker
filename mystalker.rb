require 'rubygems'
require 'ncurses'

# a wrapper around ncurses
class MyCurses
  def initialize scroll_enabled=true
    @window = Ncurses.initscr
    @stack = []
    Ncurses.cbreak
    scroll scroll_enabled
  end

  def location
    row = []
    col = []
    @window.getyx(col, row)
    return [col.first, row.first]
  end

  def window
    @window
  end

  def scroll enabled=true
    @window.scrollok(enabled)
  end

  def refresh
    @window.refresh
  end

  def sleep duration=25
    Ncurses.napms duration
  end

  def destroy
    Ncurses.endwin
  end

  def << str
    @window.addstr(str)
    self
  end

  def push
    @stack.push location
  end

  def pop
    window.move *@stack.pop
  end

  def at x, y, &block
    push
    move x, y
    yield
    pop
  end

  def move x, y
    x += size.first if x < 0
    y += size.last if y < 0
    @window.move(y, x)
  end

  def show duration
    refresh
    sleep duration
  end

  def size
    rows = []
    cols = []
    @window.getmaxyx cols, rows
    [rows.first, cols.first]
  end

end

# take STDIN and give it to me 1 line at a time without blocking
class STDINFeed
  def initialize
    @buffer = ''
    @lines = []
  end

  def shift
    prime if @lines.empty?
    @lines.shift
  end

  def prime
    data = STDIN.read_nonblock(10000) rescue ''
    @buffer += data
    split_on_newlines
  end

  def split_on_newlines
    newline = @buffer.index("\n")
    if newline
      @lines << @buffer[0...newline]
      @buffer.slice!(0..newline)
    end
  end
end

# combine multi-line queries into single lines
class MysqlParser
  def initialize(options={})
    @buffer = nil
    @queries = []
    @feed = options[:feed]
    @simplify = options[:simplify]
  end

  def << line
    if line.match(/^SELECT/)
      push(@buffer) if @buffer
      @buffer = ''
    end
    @buffer += line.chomp.strip + ' '
  end

  def pump
    while l = @feed.shift do
      self << l
    end
  end

  def shift
    @queries.shift
  end

  def push query
    if @simplify
      query = query.
        gsub(/= ?'[-a-z0-9\.]+'/i, ' ').
        gsub(/= ?-?\d+\.\d+/, '').
        gsub(/= ?\d+($| )/, ' ').
        gsub(/LIMIT \d+/, ' ').
        gsub(/ORDER BY \w+ DESC/, ' ').
        gsub(/AS [a-z][a-z0-9_]+/i, ' ').
        gsub(/UNIX_TIMESTAMP\(([a-z0-9\.]+)\)/, '\1').
        gsub(/round\((\w+), 2\)/, '\1').
        gsub(/WHERE .*/, '').
        strip
    end
    query = query.gsub(/ +,/, ',').gsub(/  +/, ' ').strip
    @queries.push query
  end
end

# track the stats for queries
class QuerySummary
  def initialize
    @queries = {}
  end

  def << query
    @queries[query] ||= []
    @queries[query].push Time.now.to_i
  end

  def clear
    @queries = {}
  end

  def pairs
    queries = @queries.keys.sort
    now = (Time.now).to_i
    min = now - 60
    fivesecs = now - 5
    queries.collect { |k| [k, @queries[k].size, @queries[k].select { |t| t > min }.size, @queries[k].select { |t| t > fivesecs }.size] }
  end
end



# The actual application
begin
  mc = MyCurses.new
  parser = MysqlParser.new(:feed => STDINFeed.new, :simplify => true)
  summary = QuerySummary.new
  mc.move(0,0)
  mc << "%8s | %8s | %8s | query\n" % ['total', 'minute', '5 sec']

  loop do
    parser.pump
    while query = parser.shift do summary << query end

    mc.at(0, 1) do
      summary.pairs.each do |k, total, min, five|
        mc << "%8d | %8d | %8d | #{k}\n" % [total, min, five]
      end
    end
    mc.move(-1,-1)
    mc.show 1000
  end
ensure
  mc.destroy
end
