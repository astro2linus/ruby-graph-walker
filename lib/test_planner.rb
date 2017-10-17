require 'colorize'

module RubyGraphWalker
  module TestPlanner
    def search_vertex(query_method = 'query')
      vertices = @graph.vertices.values
      candidates = vertices.select do |v|
        trait = v.trait
        if trait.is_a?(Proc)
          trait.call
        elsif trait.is_a?(Array)
          trait.any? { |t| (send query_method, t).any? }
        else
          send(query_method, trait).any?
        end
      end

      if candidates.size > 1
        log_warning "Warning: multiple vertices found: #{candidates.map {|c| c[:name]}.join(' ') }"   
      elsif candidates.size == 0
        if send(query_method, "*").any?
          raise "No vertex found"
        else
          raise "Connection refused"
        end
      end
      candidates.max_by {|v| v.zindex}
    end

    def path_to(to, args = {})
      v = search_vertex
      @graph.find_path(v.name, to, args)
    end

    def run(plan, args = {})
      raise "on the spot" if plan == :on_the_spot

      plan.each do |p|
        edge = p[:e]
        raise "edge is nil" if edge.nil?
        edge.run
        @graph.vertices[edge.from].visited = true
      end
    end

    def text_logger(args = {})
      log_file_name = "#{Time.now.strftime('%Y_%m_%d_%H_%M_%S')}.txt"
      @log_file ||= File.open(log_file_name, 'w') 
    end

    def log(msg)
      text_logger.puts(msg)
    end

    def start(graph, args = {})
      @graph = graph
      unvisited_edges = @graph.edges_by_name.select { |k, v| v.visited == false and v.weight > 1 }
      starting_point = args[:start] || @graph.vertices.keys.first
      while unvisited_edges.any?
        edge_name = largest_weight(unvisited_edges).first
        edge = @graph.edges_by_name[edge_name]
        plan = path_to(starting_point, via_edge: edge_name)
        begin
          run(plan)
        rescue => e
          edge.error_count += 1
          log edge.name + " failed! #{edge.error_count}"
          e.backtrace.each do |text|
            log text
          end 

          retries = 3
          begin
            sleep 10
            new_plan = path_to(edge.from)
            run(new_plan, args)
          rescue
            edge.error_count += 1
            retry unless (retries -= 1).zero?
          end
        end
        unvisited_edges = @graph.edges_by_name.select { |k, v| v.visited == false and v.weight > 1 and v.error_count < 3}
      end

      @graph.edges_by_name.each do |k, v|
        log "#{k} error count: #{v.error_count}"
      end

      text_logger.close
    end

    private
    def largest_weight(hash)
      hash.max_by{|k,v| v.weight}
    end

  end
end