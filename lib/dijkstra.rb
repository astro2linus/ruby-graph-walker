require_relative 'pq'

class Dijkstra
  def initialize(graph, source_vertex)
    @graph = graph
    @vertices = @graph.vertices
    @source_vertex = source_vertex
    @path_to = {}
    @distance_to = {}
    @pq = PriorityQueue.new
    compute_shortest_path
  end

  def shortest_path_to(vertex)
    return [] unless reachable?(vertex)
    return [] if @distance_to[vertex] == 0
    path = []
    while vertex != @source_vertex
      path.unshift(vertex)
      vertex = @path_to[vertex]
    end
    path.unshift(@source_vertex)
  end

  private

  def reachable?(vertex)
    not @distance_to[vertex] == Float::INFINITY
  end

  def compute_shortest_path
    update_distance_of_all_edges_to(Float::INFINITY)
    @distance_to[@source_vertex] = 0

    @pq.insert(@source_vertex, 0)
    while @pq.any?
      vertex = @pq.remove_min
      @vertices[vertex].edges.each do |edge|
        update(edge)
      end
    end
  end

  def update_distance_of_all_edges_to(distance)
    @vertices.each do |key, value|
      @distance_to[key] = distance
    end
  end

  def update(edge)
    raise "#{edge.to} doesn't exist, check edge[:to] in #{edge.inspect}" if @distance_to[edge.to].nil?
    return if @distance_to[edge.to] <= @distance_to[edge.from] + edge.weight
    @distance_to[edge.to] = @distance_to[edge.from] + edge.weight
    @path_to[edge.to] = edge.from
    @pq.insert(edge.to, @distance_to[edge.to])
  end
end