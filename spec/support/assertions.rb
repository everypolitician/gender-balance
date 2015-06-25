class Minitest::Spec
  # Copied from active support http://git.io/vIYii
  def assert_difference(expression, difference = 1, message = nil, &block)
    expressions = Array(expression)

    exps = expressions.map do |e|
      e.respond_to?(:call) ? e : -> { eval(e, block.binding) }
    end
    before = exps.map(&:call)

    yield

    expressions.zip(exps).each_with_index do |(code, e), i|
      error  = "#{code.inspect} didn't change by #{difference}"
      error  = "#{message}.\n#{error}" if message
      assert_equal(before[i] + difference, e.call, error)
    end
  end
end
