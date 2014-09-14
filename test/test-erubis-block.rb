require 'minitest/autorun'
require 'byebug'

unless defined?(TESTDIR)
  TESTDIR = File.dirname(__FILE__)
  LIBDIR  = TESTDIR == '.' ? '../lib' : File.dirname(TESTDIR) + '/lib'
  $: << TESTDIR
  $: << LIBDIR
end

require 'erubis'
require 'erubis/engine/enhanced'
require 'erubis/engine/optimized'

class ErubisBlockTest < Minitest::Test
  class TestContext
    def content_tag(tag)
      "<#{tag}>#{yield}</#{tag}>"
    end
  end

  def test_block
    erb = '' <<
      "<%= content_tag('div') do %>\n" <<
      "  Hello World\n" <<
      '<% end %>'
    assert_equal "<div>\n  Hello World\n</div>", result(erb)
  end

  def test_nested_block
    erb = ''
    .<<("<%= content_tag('div') do %>\n")
    .<<("  <% %w[Jack Sparrow].each do |name| %>\n")
    .<<("    Hello <%= name %>\n")
    .<<("  <% end %>\n")
    .<<("<% end %>")
    assert_equal "<div>\n    Hello Jack\n    Hello Sparrow\n</div>", result(erb)
  end

  private
  def result(erb)
    Erubis::Eruby.new(erb).evaluate(TestContext.new)
  end
end
