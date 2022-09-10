# frozen_string_literal: true

module RuboCop
  module Cop
    module Rails
      class EnumerableFindBy < Base
        include RangeHelp
        extend AutoCorrector

        MSG = 'Use `find_by` instead of `find` when testing attributes equality.'
        RESTRICT_ON_SEND = %i[find].freeze

        def on_send(node)
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
          if block_context.and_type?
            attrs = dig_and_nodes(block_context)
            params = attrs.map { |k, v| "#{k}: #{v}" }.join(", ")
            corrector.replace(block_node, "#{receiver}.find_by(#{params})")
          else
            # require 'debug'; debugger;
            first_node_within_block = block_context.children.first
            attr_name = first_node_within_block.method_name
            attr_value = block_context.children.last.method_name
            attrs = [[attr_name, attr_value]]
            params = attrs.map { |k, v| "#{k}: #{v}" }.join(", ")
            corrector.replace(block_node, "#{receiver}.find_by(#{params})")
          end
        end
        
        def dig_and_nodes(and_node)
          left_node = and_node.children.first
          right_node = and_node.children.last
          left_pair =
            if left_node.and_type?
              dig_and_nodes(left_node)
            else
              children = left_node.children
              [[children.first.method_name, children.last.method_name]]
            end
          right_pair = 
            begin
              children = right_node.children
              [[children.first.method_name, children.last.method_name]]
            end
          left_pair + right_pair
        end
      end
    end
  end
end
