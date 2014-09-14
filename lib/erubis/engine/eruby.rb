##
## $Release: 2.8.0 $
## copyright(c) 2006-2011 kuwata-lab.com all rights reserved.
##

require 'erubis/engine'
require 'erubis/enhancer'


module Erubis
  ##
  ## code generator for Ruby
  ##
  module RubyGenerator
    include Generator
    include StringBufferEnhancer

    def init_generator(properties={})
      super
      @escapefunc ||= "Erubis::XmlHelper.escape_xml"
      @bufvar       = properties[:bufvar] || "_buf"
      @in_block     = 0
      @block_ignore = 0
    end

    def self.supported_properties()  # :nodoc:
      return []
    end

    def escape_text(text)
      text.gsub(/['\\]/, '\\\\\&')   # "'" => "\\'",  '\\' => '\\\\'
    end

    def escaped_expr(code)
      return "#{@escapefunc} #{code}"
    end

    def add_text(src, text)
      src << " #{@bufvar} << '" << escape_text(text) << "';" unless text.empty?
    end

    def add_stmt(src, code)
      if block_start? code
        block_ignore
      elsif block_end? code
        src << @bufvar << ?;
        block_end
      end

      src << "#{code};"
    end

    def add_expr_literal(src, code)
      if block_start? code
        src << "#@bufvar << #{code};"
        block_start
        src << "#@bufvar = '';"
      else
        src << "#{@bufvar} << (#{code}).to_s;"
      end
    end

    def add_expr_escaped(src, code)
      src << " #{@bufvar} << " << escaped_expr(code) << ';'
    end

    def add_expr_debug(src, code)
      code.strip!
      s = (code.dump =~ /\A"(.*)"\z/) && $1
      src << ' $stderr.puts("*** debug: ' << s << '=#{(' << code << ').inspect}");'
    end

    
    private
      def block_start? code
        res = code =~ /\b(do|\{)(\s*\|[^|]*\|)?\s*\Z/
      end
      def block_start
        @in_block += 1
        @bufvar << '_tmp'
      end

      def block_ignore
        @block_ignore += 1
      end

      def block_end? code
        res = @in_block != 0 && code =~ /\bend\b|}/
        if res && @block_ignore != 0
          @block_ignore -= 1
          return false
        end

        res
      end
      def block_end
        @in_block -= 1
        @bufvar.sub! /_tmp\Z/, ''
      end
  end

  ##
  ## engine for Ruby
  ##
  class Eruby < Basic::Engine
    include RubyEvaluator
    include RubyGenerator
  end

  ##
  ## fast engine for Ruby
  ##
  class FastEruby < Eruby
    include InterpolationEnhancer
  end

  ##
  ## swtich '<%= %>' to escaped and '<%== %>' to not escaped
  ##
  class EscapedEruby < Eruby
    include EscapeEnhancer
  end

  ##
  ## sanitize expression (<%= ... %>) by default
  ##
  ## this is equivalent to EscapedEruby and is prepared only for compatibility.
  ##
  class XmlEruby < Eruby
    include EscapeEnhancer
  end

  class PI::Eruby < PI::Engine
    include RubyEvaluator
    include RubyGenerator

    def init_converter(properties={})
      @pi = 'rb'
      super(properties)
    end

  end
end
