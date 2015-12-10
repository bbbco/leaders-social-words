#!/usr/bin/env ruby
#encoding: utf-8

script_dir = File.dirname(__FILE__)
$LOAD_PATH.unshift File.join(script_dir, '..', 'lib')

require 'koala'
require 'json'
require 'pry'
require 'text_word_count'

fb_token = ARGV[0]

unless fb_token

  puts "Usage: #{$0} <token>"
  puts "This script requires a Facebook API Graph token passed as its first parameter."
  puts "You can a temporary one here: https://developers.facebook.com/tools/explorer/"
  exit

end

begin
  leaders_file = File.read("#{script_dir}/../conf/leaders_ids.json")
rescue
  puts "Cannot find the ./conf/leaders_ids.json file!"
  exit
end

leaders_json = JSON.parse(leaders_file)["leaders"]

begin
  @graph = Koala::Facebook::API.new(fb_token)
  @graph.get_object("me")
rescue Koala::Facebook::AuthenticationError
  puts "Your token has expired! Please get a new token at: https://developers.facebook.com/tools/explorer/"
  exit
end

leaders_text = {}

leaders_json.each do |leader|

    puts "Culling #{leader["id"]}"
    all_text = []
    posts = @graph.get_connection(leader["facebook_id"], 'posts', {fields: ['message','from', 'created_time'], limit: 10, since: "2015-01-01"})
    begin
      all_text += posts.map{|post| post["message"] }
    end while posts = posts.next_page
    leaders_text[leader["id"]] = TextWordCount.new(all_text.join(" ")).word_counts.to_a.sort_by{|x,y| y}.reverse.first(150)

end

File.open(File.join(script_dir, '..', 'data', 'facebook', 'results.json'), 'w') do |f|
  f.write(leaders_text.to_json)
end





