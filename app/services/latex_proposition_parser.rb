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
    @expression_builder = Utils::PostfixExpressionBuilder.new(input_latex, @precedence)
  end

  def parse
    @expression_builder.build
    postfix_expression = @expression_builder.postfix_expression
    # Build the AST from the postfix expression
    # and convert it to LaTeX format.
    ast = build_ast(postfix_expression)
    result = to_latex(ast)

    { latex: result, steps: @expression_builder.rewriting_steps }
  end

  private

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
      right = resolve_branch(node.right)
      "\\neg (#{right})"
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
