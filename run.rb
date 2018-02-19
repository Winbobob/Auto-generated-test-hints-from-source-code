require 'parser/current'
require 'pry'

KEY_WORDS = %i(
  if
  send
  lvar
  include?
  nil?
  any?
  empty?
  send
  next
)

def helper(res, level, test_skeleton, nth_method, return_values)
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
        level[0] = :def
        test_skeleton[0] += ' ' * 2 + "describe '.#{res.first[1]}' do\n"
        # res = res.first
        res.first.shift # remove :def
        res.first.shift # remove method name
        res.first.shift # remove method params (?)
        nth_method[0] += 1
        helper(res.first, level, test_skeleton, nth_method, return_values)
        level[0] = :def
      end

      if res.any? and (res.first.first == :begin or res.first.first == :block)
        # res = res.first
        res.first.shift # remove :begin or :block
        helper(res.first, level, test_skeleton, nth_method, return_values)
      end
      
      if res.any? and res.first.first == :if
        level[0] = :context
        test_skeleton[0] += ' ' * 4 + "context 'when "
        # res.first.flatten!
        res.first[1].flatten.each do |item|
          unless KEY_WORDS.include? item
            test_skeleton[0] += "#{item} "
          end
          test_skeleton[0] += "is #{item}".chomp('?') if item.to_s.end_with? '?'
        end
        test_skeleton[0].rstrip!
        test_skeleton[0] += "' do\n"
        test_skeleton[0] += ' ' * 6 + "it 'returns [return_values_placeholder_#{nth_method[0]}]'\n"
        test_skeleton[0] += ' ' * 8 + "# Write your test here!\n\n"
        test_skeleton[0] += ' ' * 4 + "end\n\n"
        res.shift
        next
      end

      if res.any? and res.first.first == :lvar and level[0] == :context
        return_values << res.first.last.to_s
        # puts "return value: #{return_values[0]}"
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
nth_method = [-1]
level = ['']
test_skeleton = ['']
return_values = []
helper(res, level, test_skeleton, nth_method, return_values)
# replace [return value placeholder] with real return value
return_values.each_with_index do |value, index|
  test_skeleton[0].gsub!("[return_values_placeholder_#{index}]", value)
end
# puts test_skeleton
spec_file_name = file_name[0].gsub!('.rb', '_spec.rb')
puts "Generating #{spec_file_name}..."
begin
  file = File.open("spec/#{spec_file_name}", 'w')
  file.write(test_skeleton[0])
rescue IOError => e
ensure 
  file.close unless file.nil?
end