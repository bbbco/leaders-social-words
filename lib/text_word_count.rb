require 'uri'

class TextWordCount

    attr_reader :blacklist, :substitutions, :word_counts

    def initialize(text)

        script_dir = File.dirname(__FILE__)
        @blacklist = []
        @substitutions = {}

        begin
            @blacklist = File.open(File.join(script_dir, '..', '/conf/blacklist.txt'),'r').read.encode!('UTF-8','UTF-8', :invalid => :replace).upcase.split("\n")
        rescue
        end

        begin
            CSV.foreach(File.join(script_dir, '..', "../conf/substitutions.txt")) do |line|
                line.upcase!
                @substitutions[line[0]] = line[1].strip
            end
        rescue
        end

        words = sanitize_and_split(text)

        @word_counts = Hash.new(0)

        words.each do |word|
            @word_counts[word] += 1
        end

        @word_counts.delete('')
        @blacklist.each do |word|
            @word_counts.delete(word)
        end

        @substitutions.each do |word,replace|
            if @word_counts.include?(replace)
                @word_counts[replace] += @word_counts[word]
                @word_counts.delete(word)
            end
        end

        return @word_counts.sort_by{|word,count| count }.reverse

    end

    private

    def sanitize_and_split(text)
        text = text.upcase.strip.gsub('/--+/', '')
        text_arr = text.split.map do |w|
          unless w =~ URI::regexp
            w.gsub(/[^A-Z0-9\-']/,'').gsub(/(^-|-$)/,'')
          end
        end
        text_arr.reject!{|h| h.nil? }
        text_arr
    end

end
