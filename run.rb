require 'parser/current'
require 'pry'

KEY_WORDS = %i(
  if
  send
  lvar
  include?
  send
  next
)

def helper(res, level, test_skeleton, return_value)
  while res.length > 0
    if res.any? and res.first == :class
      level[0] = :class
      res.shift # remove 1st elem
      next
    end

    if res.any? and res.first.is_a? Array
      if res.first.first == :const and level[0] == :class
        test_skeleton[0] += "describe #{res.first[2]} do\n"
        res.shift
        next
      end

      if res.any? and res.first.first == :def
        level[0] == :def
        test_skeleton[0] += ' ' * 2 + "describe '.#{res.first[1]}' do\n"
        # res = res.first
        res.first.shift # remove :def
        res.first.shift # remove method name
        res.first.shift # remove method params (?)
        helper(res.first, level, test_skeleton, return_value)
        level[0] == :def
      end

      if res.any? and (res.first.first == :begin or res.first.first == :block)
        # res = res.first
        res.first.shift # remove :begin or :block
        helper(res.first, level, test_skeleton, return_value)
      end
      
      if res.any? and res.first.first == :if
        level[0] == :context
        test_skeleton[0] += ' ' * 4 + "context 'when "
        res.first.flatten!
        res.first.each do |item|
          unless KEY_WORDS.include? item
            test_skeleton[0] += "#{item}-"
          end
        end
        test_skeleton[0] += "' do\n"
        test_skeleton[0] += ' ' * 6 + "it 'returns #{return_value}'\n"
        test_skeleton[0] += ' ' * 8 + "# Write your test here!\n\n"
        test_skeleton[0] += ' ' * 4 + "end\n\n"
        res.shift
        next
      end

      if res.any? and res.first.first == :lvar and level[0] == :def
        return_value[0] = res.first.last.to_s
        res.shift
        next
      end
    end
    res.shift
  end
end

# file_name = ARGV
file_name = ['collusion_cycle.rb']
file_path = "/home/expertiza_developer/expertiza/app/models/#{file_name.first}"
# puts file_path
source_code = File.open(file_path).read rescue nil
res = Parser::CurrentRuby.parse(source_code) if source_code
# puts res.to_sexp
# puts res.to_sexp_array
res = res.to_sexp_array
level = ['']
test_skeleton = ['']
return_value = ['']
helper(res, level, test_skeleton, return_value)
puts test_skeleton

