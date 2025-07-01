class LatexController < ApplicationController
  skip_before_action :verify_authenticity_token

  def parse
    input = params[:latex]
    priority = params[:priority] || []
    parser = LatexPropositionParser.new(input, priority)
    latex_result = parser.parse
    # latex_result = "(p \\lor (q \\land \\neg r))"

    render json: { latex_result: latex_result.fetch(:latex, ""), steps: latex_result.fetch(:steps, []) }
  end
end