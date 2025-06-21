class LatexPropositionParser
  # Default operator precedence (highest number = highest priority)
  PRECEDENCE = {
    "¬" => 4,
    "∧" => 3,
    "∨" => 2,
    "→" => 1,
    "↔" => 0
  }

  OPERATORS = PRECEDENCE.keys

  def initialize(input_latex, precedence = nil)
    @input_latex = input_latex
    @precedence = precedence ? precedence.reverse.each_with_index.to_h : PRECEDENCE
  end

  def parse
    tokens = tokenize(@input_latex)
    output_queue = shunting_yard(tokens)
    ast = build_ast(output_queue)
    to_latex(ast)
  end

  private

  def tokenize(input)
    input.gsub("\\neg", "¬")
         .gsub("\\lor", "∨")
         .gsub("\\land", "∧")
         .gsub("\\rightarrow", "→")
         .gsub("\\leftrightarrow", "↔")
         .scan(/¬|∧|∨|→|↔|\(|\)|[a-z]/)
  end

  def shunting_yard(tokens)
    output = []
    stack = []

    tokens.each do |token|
      if token.match?(/[a-z]/)
        output << token
      elsif OPERATORS.include?(token)
        while !stack.empty? && OPERATORS.include?(stack.last) &&
              @precedence[token] < @precedence[stack.last]
          output << stack.pop
        end
        stack << token
      elsif token == "("
        stack << token
      elsif token == ")"
        until stack.empty? || stack.last == "("
          output << stack.pop
        end
        stack.pop # deletes "("
      end
    end

    output.concat(stack.reverse)
    output
  end


  Node = Struct.new(:value, :left, :right)

  def build_ast(rpn)
    stack = []

    rpn.each do |token|
      if token.match?(/[a-z]/)
        stack << Node.new(token)
      elsif token == "¬"
        operand = stack.pop
        stack << Node.new(token, nil, operand)
      else
        right = stack.pop
        left = stack.pop
        stack << Node.new(token, left, right)
      end
    end

    stack.first
  end

  def to_latex(node)
    return node.value if is_operand?(node)

    if node.value == "¬"
      "\\neg #{wrap_if_needed(node.right)}"
    else
      op_map = {
        "∧" => "\\land",
        "∨" => "\\lor",
        "→" => "\\rightarrow",
        "↔" => "\\leftrightarrow"
      }

      left = resolve_branch(node.left)
      right = resolve_branch(node.right)
      "(#{left} #{op_map[node.value]} #{right})"
    end
  end

  def resolve_branch(node)
    if is_operand?(node)
      node.value
    else
      to_latex(node)
    end
  end

  def is_operand?(node)
    node.left.nil? && node.right.nil?
  end
end
