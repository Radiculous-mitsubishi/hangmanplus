require 'csv'

MAX_CUSTOM_WORD_FILE_BYTES = 1_048_576
MAX_CUSTOM_WORDS = 5_000
MAX_CUSTOM_WORD_LENGTH = 30

# Load a local TXT/CSV-style word list from an absolute or relative path.
# Accepted formats: one word per line, comma-separated, or CSV rows.
def load_custom_word_list(path)
  expanded_path = File.expand_path(path.to_s.strip.gsub(/\A['"]|['"]\z/, ''))
  raise ArgumentError, 'Enter a file path.' if path.to_s.strip.empty?
  raise ArgumentError, 'That path is not a readable file.' unless File.file?(expanded_path) && File.readable?(expanded_path)
  raise ArgumentError, 'Word-list files must be 1 MB or smaller.' if File.size(expanded_path) > MAX_CUSTOM_WORD_FILE_BYTES

  contents = File.read(expanded_path, encoding: 'UTF-8')
  raise ArgumentError, 'The file must be valid UTF-8 text.' unless contents.valid_encoding?

  words = CSV.parse(contents, liberal_parsing: true).flatten.map do |entry|
    word = entry.to_s.delete_prefix("\uFEFF").strip.downcase
    next if word.empty? || word.start_with?('#')

    unless word.match?(/\A[a-z]{2,#{MAX_CUSTOM_WORD_LENGTH}}\z/)
      raise ArgumentError, "Invalid word '#{word}'. Use only 2-#{MAX_CUSTOM_WORD_LENGTH} letters per word."
    end
    word
  end.compact.uniq

  raise ArgumentError, 'The file contains no usable words.' if words.empty?
  raise ArgumentError, "Lists may contain at most #{MAX_CUSTOM_WORDS} unique words." if words.length > MAX_CUSTOM_WORDS

  { name: File.basename(expanded_path, File.extname(expanded_path)), words: words, source_path: expanded_path }
rescue CSV::MalformedCSVError
  raise ArgumentError, 'Could not parse that text/CSV word list.'
rescue Encoding::InvalidByteSequenceError, Encoding::UndefinedConversionError
  raise ArgumentError, 'The file must be valid UTF-8 text.'
end
