require 'nokogiri'
require 'open-uri'

require 'watir-webdriver'

@mbo_id = ARGV[0]
browser = Watir::Browser.new :firefox
browser.goto "https://clients.mindbodyonline.com/ASP/home.asp?studioid=#{@mbo_id}"
sleep 5

data = Nokogiri::HTML(browser.frame(:name => "mainFrame").html)

even_rows = data.css('.evenRow')
odd_rows = data.css('.oddRow')

instructors = Array.new
classes = Array.new

even_rows.each do |er|
  if (defined? er.at_css('.modalBio').text) && (defined? er.at_css('.modalClassDesc').text)
    classes.push(er.at_css('.modalClassDesc').text)
    instructors.push(er.at_css('.modalBio').text)
  end
end

odd_rows.each do |er|
  if (defined? er.at_css('.modalBio').text) && (defined? er.at_css('.modalClassDesc').text)

    classes.push(er.at_css('.modalClassDesc').text)
    instructors.push(er.at_css('.modalBio').text)
  end
end

browser.close

puts "Total Weekly Classes is #{classes.count}"
puts "Instructor Count is #{instructors.uniq.count}"

instructors.uniq.each do |i|
  puts "#{i}"
end
