class PostfixToAst
  # This class converts an expression from postfix notation to an Abstract Syntax Tree (AST).

  RewritingStep = Struct.new(:input_token, :type, :stack, :current_tree, :remaining_input, :description, keyword_init: true)
  Node = Struct.new(:value, :left, :right)

  def self.build_ast(postfix_expression)
    stack = []
    rewriting_steps = []

    postfix_expression.each_with_index do |token, i|
      if token.match?(/[a-z]/)
        node = Node.new(token)
        stack << node
        rewriting_steps << RewritingStep.new(
          input_token: token,
          type: :operand,
          stack: stack.dup,
          current_tree: stack.first,
          remaining_input: postfix_expression[i + 1..-1].join(" "),
          description: "Se crea un nodo terminal nuevo a partir del operando '#{token}'"
        )
      elsif token == "¬"
        operand = stack.pop
        stack << Node.new(token, nil, operand)
        rewriting_steps << RewritingStep.new(
          input_token: token,
          type: :operator,
          stack: stack.dup,
          current_tree: stack.first,
          remaining_input: postfix_expression[i + 1..-1].join(" "),
          description: "Se crea un nodo nuevo a partir del operador '#{token}' y se enlaza a su operando '#{operand.value}'"
        )
      else
        right = stack.pop
        left = stack.pop
        stack << Node.new(token, left, right)
        rewriting_steps << RewritingStep.new(
          input_token: token,
          type: :operator,
          stack: stack.dup,
          current_tree: stack.first,
          remaining_input: postfix_expression[i + 1..-1].join(" "),
          description: "Se crea un nodo nuevo a partir del operador '#{token}'  y se enlaza a sus operandos '#{left.value}' y '#{right.value}'"
        )
      end
    end

    { ast: stack.first, rewriting_steps: rewriting_steps }
  end
end
