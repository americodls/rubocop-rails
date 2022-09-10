# frozen_string_literal: true

module RuboCop
  module Cop
    module Rails
      class EnumerableFindBy < Base
        include RangeHelp
        extend AutoCorrector

        MSG = 'Use `find_by` instead of `find` when testing attributes equality.'
        RESTRICT_ON_SEND = %i[find].freeze

        def_node_search :method_called_on_attribute?, <<~PATTERN
          (send (send (lvar _) _) _)
        PATTERN

        def_node_search :comparison_method, <<~PATTERN
          (send (send (lvar _) _) $_ _)
        PATTERN



        def on_send(node)
          block_node = node.block_node
          return unless block_node

          return if method_called_on_attribute?(block_node)

          comparison_method(block_node) do |comparison|
            return if comparison != :==
          end

          range = offense_range(node)
          add_offense(range, message: MSG) do |corrector|
            autocorrect(corrector, node)
          end
        end

        private

        def offense_range(node)
          range_between(node.loc.selector.begin_pos, node.block_node.loc.last_column)
        end

        def autocorrect(corrector, node)
          receiver = node.receiver.source
          block_node = node.block_node
          block_context = block_node.children.last
          attrs = pairs(block_context) 
          params = attrs.map { |k, v| "#{k}: #{v}" }.join(", ")
          
          corrector.replace(block_node, "#{receiver}.find_by(#{params})")
        end
        
        def pairs(node)
          return pair(node) unless node.and_type?

          children = node.children
          left_node = children.first
          right_node = children.last
          left_pair = left_node.and_type? ? pairs(left_node) : pair(left_node)
          right_pair = pair(right_node)
          left_pair + right_pair
        end

        def pair(node)
          children = node.children
          attr_name = children.first.method_name
          attr_value = children.last.source
          attrs = [[attr_name, attr_value]]
        end
      end
    end
  end
end
