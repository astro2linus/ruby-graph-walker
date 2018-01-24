require 'dijkstra'
require 'colorize'

module RubyGraphWalker
  class Vertex
    attr_accessor :name, :weight, :edges, :trait, :visited, :zindex
    def initialize(args = {})
      [:name, :edges, :trait].each { |key| raise "#{key} is not defined for Vertex #{args}" unless args[key] }
      @name = args[:name]
      @weight = args[:weight] || 1
      @trait = args[:trait]
      @visited = args[:visited] || false
      @zindex = args[:zindex] || 0
      @edges = []

      args[:edges].each do |edge|
        e = Edge.new(edge)
        e.from = @name
        e.to = edge[:to]
        add_edge(e)
      end
    end

    private 
    def add_edge(e)
      @edges << e
    end
  end

  class Edge
    attr_accessor :name, :from, :to, :weight, :visited, :proc, :error_count
    def initialize(args = {})
      [:name, :to, :proc].each { |key| raise "#{key} is not defined for Edge #{args}" unless args[key] }
      @name = args[:name]
      @from = args[:from]
      @to = args[:to]
      @weight = args[:weight] || 1
      @visited = args[:visited] || false
      @proc = args[:proc]
      @error_count = 0
    end

    def run
      # begin
      #   @proc.call
      # rescue Exception => e
      #   STDOUT.puts @proc
      #   # binding.pry
      #   @visited = true
      #   raise e
      # end
      @proc.call
      @visited = true
    end
  end

  class Graph
    attr_accessor :vertices, :edges, :edges_by_name
    def initialize(vertices)
      @vertices = {}
      @edges_by_name = {}
      @edges = []
      vertices.each do |v_params|
        v = Vertex.new(v_params)
        @vertices[v_params[:name]] = v
        v.edges.each do |edge|
          puts "Warning: multiple edges named '#{edge.name}'" if @edges_by_name[edge.name]
          @edges_by_name[edge.name] = edge
          @edges << edge
        end
      end
    end

    def find_path_via_edge(from, to, edge_name)
      log_info "#{from} -> #{to} via: (#{edge_name}): "
      matched_edges = @edges.select { |edge| edge.name == edge_name }
      log_error "no edge found for '#{edge_name}'" if matched_edges.size == 0
      log_error "multiple edges matched for '#{edge_name}'" if matched_edges.size > 1
      via_edge = matched_edges.first
      plan = []

      first_path = Dijkstra.new(self, from).shortest_path_to(via_edge.from)

      first_path.each_cons(2) do |path|
        start, dest = path
        vertex = @vertices[start]
        edge = vertex.edges.select { |e| e.to == dest}.first
        plan << {v: vertex, e: edge}
      end

      via_v = @vertices[via_edge.from]
      plan << {v: via_v, e: via_edge}

      second_path = Dijkstra.new(self, via_edge.to).shortest_path_to(to)

      second_path.each_cons(2) do |path|
        start, dest = path
        vertex = @vertices[start]
        edge = vertex.edges.select { |e| e.to == dest }.first
        plan << {v: vertex, e: edge}
      end
      plan 
    end

    def find_path(from, to, args = {})  
      vertex_path = []
      plan = []
      via_type = args.keys.join

      case via_type
      when "via"
        via = args[:via]
        vertex_path = Dijkstra.new(self, from).shortest_path_to(via) + Dijkstra.new(self, via).shortest_path_to(to).drop(1)
        vertex_path.each_cons(2) do |path|
          f, d = path
          vertex = @vertices[d]
          edge = vertex.edges.select { |e| e.to == d}.first
          plan << {v: vertex, e: edge}
        end
      when "via_edge"
        via_edge = args[:via_edge]
        plan = find_path_via_edge(from, to, via_edge)

      # when "via_edges"
      #   edges = args[:via_edges]
      #   if edges.size < 2
      #     raise "please specify multiple edges"
      #   end
      #   v = nil
      #   edges[0..-2].each do |edge|
      #     start = (plan.last[:v].name if plan.last) || from
      #     v = @edges_by_name[edge].to
      #     plan += find_path_via_edge(start, v, edge)
      #   end
      #   plan += find_path_via_edge(v, to, edges.last)
      when ""
        vertex_path = Dijkstra.new(self, from).shortest_path_to(to)
        
        vertex_path.each_cons(2) do |path|
          from, d = path
          vertex = @vertices[from]
          edge = vertex.edges.select { |e| e.to == d}.first
          plan << {v: vertex, e: edge}
        end
        if plan.empty? and from == to
          return  :on_the_spot
        end
      end

      if plan.any?
        puts plan.map {|p| "#{p[:v].name if p[:v]} (#{p[:e].name if p[:e]})" }.join(" -> ") + " >> #{@vertices[to].name}" 
      else
        raise "No path from #{from} to #{to}" 
      end
      plan
    end
  end

end


