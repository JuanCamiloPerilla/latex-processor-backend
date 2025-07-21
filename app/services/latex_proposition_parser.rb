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
    postfix_builder_result = PostfixExpressionBuilder.build(@input_latex, @precedence)
    postfix_to_ast_result = PostfixToAst.build_ast(postfix_builder_result[:postfix_expression])

    # Build the AST from the postfix expression
    # and convert it to LaTeX format.
    #ast = build_ast(postfix_expression)
    result = to_latex(postfix_to_ast_result[:ast])

    { latex: result, steps: postfix_builder_result[:rewriting_steps], ast_steps: postfix_to_ast_result[:rewriting_steps] }
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
