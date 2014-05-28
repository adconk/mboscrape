require 'nokogiri'
require 'open-uri'

require 'watir-webdriver'

@mbo_id = ARGV[0]
browser = Watir::Browser.new :firefox
browser.goto "https://clients.mindbodyonline.com/ASP/home.asp?studioid=#{@mbo_id}"
sleep 4

data = Nokogiri::HTML(browser.frame(:name => "mainFrame").html)

even_rows = data.css('.evenRow')
odd_rows = data.css('.oddRow')

instructors = Array.new
classes = Array.new
booked_spots = Array.new
open_spots = Array.new

even_rows.each do |er|
  if defined? er.at_css('.modalClassDesc').text
    classes.push(er.at_css('.modalClassDesc').text)
  elsif defined? er.css('td')[2].text
    classes.push(er.css('td')[2].text)
  end
  if defined? er.at_css('.modalBio').text
    instructors.push(er.at_css('.modalBio').text)
  elsif defined? er.css('td')[3].text
    instructors.push(er.css('td')[3].text)
  end
  if defined? er.css('td')[1].text
    booked_spots.push(er.css('td')[1].text.scan(/\d+/).map(&:to_i)[0])
    open_spots.push(er.css('td')[1].text.scan(/\d+/).map(&:to_i)[1])
  end
end

odd_rows.each do |er|
  if defined? er.at_css('.modalClassDesc').text
    classes.push(er.at_css('.modalClassDesc').text)
  elsif defined? er.css('td')[2].text
    classes.push(er.css('td')[2].text)
  end
  if defined? er.at_css('.modalBio').text
    instructors.push(er.at_css('.modalBio').text)
  elsif defined? er.css('td')[3].text
    instructors.push(er.css('td')[3].text)
  end
  if defined? er.css('td')[1].text
    booked_spots.push(er.css('td')[1].text.scan(/\d+/).map(&:to_i)[0])
    open_spots.push(er.css('td')[1].text.scan(/\d+/).map(&:to_i)[1])
  end
end

browser.close

total_booked_spots = booked_spots.map(&:to_f).reduce(:+)
total_open_spots = open_spots.map(&:to_f).reduce(:+)

puts "Total Weekly Classes is #{classes.count}"
puts "Instructor Count is #{instructors.uniq.count}"
if (total_booked_spots != 0 ) && (total_open_spots != 0)
  puts "#{(total_booked_spots / (total_booked_spots + total_open_spots) * 100).to_i}% full"
end
puts "\n"

instructors.uniq.each do |i|
  if i != "Cancelled Today"
    puts "#{i}"
  end
end
