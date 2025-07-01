class Utils::PostfixExpressionBuilder
  # This class converts a logical expression in LaTeX format to postfix notation (Reverse Polish Notation).
  # It uses the Shunting Yard algorithm to handle operator precedence and parentheses.

  attr_reader :input_latex, :postfix_expression, :rewriting_steps
  # Default operator precedence (highest number = highest priority)
  # 
  DEFAULT_PRECEDENCES = {
    "¬" => 4,
    "∧" => 3,
    "∨" => 2,
    "→" => 1,
    "↔" => 0
  }

  OPERATORS = DEFAULT_PRECEDENCES.keys

  RewritingStep = Struct.new(:input_token, :type, :stack, :output_queue, :remaining_input, :action, keyword_init: true)

  def initialize(latex_input, precedences = nil)
    @latex_input = latex_input
    @precedences = precedences || DEFAULT_PRECEDENCES
    @postfix_expression = []
    @rewriting_steps = []
  end

  def build
    shunting_yard_output = run_shunting_yard()
    @postfix_expression = shunting_yard_output[:output]
    @rewriting_steps = shunting_yard_output[:rewriting_steps]
  end

  private

  def tokenize_latex
    @latex_input.gsub("\\neg", "¬")
         .gsub("\\lor", "∨")
         .gsub("\\land", "∧")
         .gsub("\\rightarrow", "→")
         .gsub("\\leftrightarrow", "↔")
         .scan(/¬|∧|∨|→|↔|\(|\)|[a-z]/)
  end

  def run_shunting_yard
    # This method implements the Shunting Yard algorithm to convert infix expressions to postfix notation.
    # It uses a stack to hold operators and outputs the final postfix expression.
    output = []
    stack = []
    rewriting_steps = []

    # Tokenize the input LaTeX expression
    # and iterate through each token.
    # The tokens are expected to be operators, operands (variables), and parentheses.
    # Example tokens: ["p", "∨", "q", "∧", "¬", "r", "(", "s", "→", "t", ")"]
    # The algorithm handles operator precedence and parentheses correctly.
    # The output will be in postfix notation, e.g., ["p", "q", "¬", "r", "s", "t", "→", "∧", "
    tokens = tokenize_latex()


    rewriting_steps << RewritingStep.new(
      input_token: "",
      type: :operand,
      stack: stack.dup,
      output_queue: output.dup,
      remaining_input: tokens.join(" "),
      action: "Expresión inicial"
    )

    tokens.each_with_index do |token, i|
      if token.match?(/[a-z]/)
        output << token
        rewriting_steps << RewritingStep.new(
          input_token: token,
          type: :operand,
          stack: stack.dup,
          output_queue: output.dup,
          remaining_input: tokens[i + 1..-1].join(" "),
          action: "Se agrega operando '#{token}' a la cola de salida"
        )
      elsif token == "¬"
        while !stack.empty? && stack.last == "¬"
          output << stack.pop
          rewriting_steps << RewritingStep.new(
            input_token: token,
            type: :operator,
            stack: stack.dup,
            output_queue: output.dup,
            remaining_input: tokens[i + 1..-1].join(" "),
            action: "Se mueve el operador '¬' a la cola de salida"
          )
        end
        stack << token
        rewriting_steps << RewritingStep.new(
          input_token: token,
          type: :operator,
          stack: stack.dup,
          output_queue: output.dup,
          remaining_input: tokens[i + 1..-1].join(" "),
          action: "Se agrega el operador '¬' sobre la pila"
        )
      # Handle binary operators
      elsif OPERATORS.include?(token)
        while !stack.empty? && OPERATORS.include?(stack.last) &&
              @precedences[token] < @precedences[stack.last]
          # Pop operators from the stack to the output queue based on precedence
          operator = stack.pop
          output << operator
          rewriting_steps << RewritingStep.new(
            input_token: token,
            type: :operator,
            stack: stack.dup,
            output_queue: output.dup,
            remaining_input: tokens[i + 1..-1].join(" "),
            action: "Se mueve el operador '#{operator}' a la cola de salida"
          )
        end
        stack << token
        rewriting_steps << RewritingStep.new(
          input_token: token,
          type: :operator,
          stack: stack.dup,
          output_queue: output.dup,
          remaining_input: tokens[i + 1..-1].join(" "),
          action: "Se agrega el operador '#{token}' sobre la pila"
        )
      elsif token == "("
        stack << token
        rewriting_steps << RewritingStep.new(
          input_token: token,
          type: :operator,
          stack: stack.dup,
          output_queue: output.dup,
          remaining_input: tokens[i + 1..-1].join(" "),
          action: "Se agrega #{token} sobre la pila"
        )
      elsif token == ")"
        until stack.empty? || stack.last == "("
          # Pop operators from the stack to the output queue until a "(" is found
          element = stack.pop
          output << element
           rewriting_steps << RewritingStep.new(
            input_token: token,
            type: :operator,
            stack: stack.dup,
            output_queue: output.dup,
            remaining_input: tokens[i + 1..-1].join(" "),
            action: "Se mueve #{element} a la cola de salida"
          )
        end
        stack.pop # deletes "("
        rewriting_steps << RewritingStep.new(
          input_token: token,
          type: :operator,
          stack: stack.dup,
          output_queue: output.dup,
          remaining_input: tokens[i + 1..-1].join(" "),
          action: "Se retira ( de la pila"
        )
      end
    end

    # Pop any remaining operators from the stack to the output queue
    remaining_operators = stack.reverse
    output.concat(remaining_operators)
    rewriting_steps << RewritingStep.new(
      input_token: nil,
      type: :operator,
      stack: [],
      output_queue: output.dup,
      remaining_input: "",
      action: "Se mueven los operadores restantes a la cola de salida: #{remaining_operators.join(", ")}"
    )

    {output: output, rewriting_steps: rewriting_steps}
  end
end
