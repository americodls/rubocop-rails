# frozen_string_literal: true

module RuboCop
  module Cop
    module Rails
      class EnumerableFindBy < Base
        include RangeHelp
        extend AutoCorrector

        MSG = 'Use `find_by` instead of `find` when testing attributes equality.'
        RESTRICT_ON_SEND = %i[find detect].freeze

        def_node_search :method_called_on_attribute?, <<~PATTERN
          (send (send (lvar _) _) _)
        PATTERN

        def_node_search :comparison_method, <<~PATTERN
          (send (send (lvar _) _) $_ _)
        PATTERN

        def_node_search :local_variable, <<~PATTERN
          $(lvar _)
        PATTERN

        def_node_matcher :find_block_with_attribute_equality?, <<~PATTERN
          (block
            (send _ {:find :detect})
            (args (arg _))
            {
              (send (send (lvar _) _) :== _)
              (send _ :== (send (lvar _) _))
            })
        PATTERN

        def on_send(node)
          block_node = node.block_node
          return unless find_block_with_attribute_equality?(node.block_node)

          return if block_node.nil? || block_node.multiline?
          return if method_called_on_attribute?(block_node)

          comparison_method(block_node) do |comparison|
            return if comparison != :==
          end

          local_variable(block_node) do |lvar|
            return if lvar.parent.arguments.include?(lvar)
          end

          range = offense_range(node)
          add_offense(range, message: MSG) do |corrector|
            autocorrect(corrector, node)
          end
        end

        private

        def offense_range(node)
          range_between(node.loc.selector.begin_pos, node.block_node.loc.expression.end_pos)
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
          left, _, right = node.children
          if right.receiver&.lvar_type?
            left, right = right, left
          end
          attr_name = left.method_name
          attr_value = right.source
          attrs = [[attr_name, attr_value]]
        end
      end
    end
  end
end
