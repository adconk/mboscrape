require 'sinatra'
require 'capybara/poltergeist'
require 'uri'

get '/' do
  erb :input
end

post '/' do
  require 'capybara/poltergeist'
  session = Capybara::Session.new(:poltergeist)

  #@mbo_id = '3954'
  session.visit "https://clients.mindbodyonline.com/classic/home?studioid=#{params[:id]}"

  sleep 4
  begin
    @title = session.title.sub(" Online","")
    mbo_studio_page = session.within_frame 'mainFrame' do
      Nokogiri::HTML(session.html)
    end
    even_rows = mbo_studio_page.css('.evenRow')
    odd_rows = mbo_studio_page.css('.oddRow')

    @instructors = Array.new
    @classes = Array.new
    @booked_spots = Array.new
    @open_spots = Array.new

    even_rows.each do |er|
      if defined? er.at_css('.modalClassDesc').text
        @classes.push(er.at_css('.modalClassDesc').text)
      elsif defined? er.css('td')[2].text
        @classes.push(er.css('td')[2].text)
      end
      if defined? er.at_css('.modalBio').text
        @instructors.push(er.at_css('.modalBio').text)
      elsif defined? er.css('td')[3].text
        @instructors.push(er.css('td')[3].text)
      end
      if defined? er.css('td')[1].text
        @booked_spots.push(er.css('td')[1].text.scan(/\d+/).map(&:to_i)[0])
        @open_spots.push(er.css('td')[1].text.scan(/\d+/).map(&:to_i)[1])
      end
    end
    odd_rows.each do |er|
      if defined? er.at_css('.modalClassDesc').text
        @classes.push(er.at_css('.modalClassDesc').text)
      elsif defined? er.css('td')[2].text
        @classes.push(er.css('td')[2].text)
      end
      if defined? er.at_css('.modalBio').text
        @instructors.push(er.at_css('.modalBio').text)
      elsif defined? er.css('td')[3].text
        @instructors.push(er.css('td')[3].text)
      end
      if defined? er.css('td')[1].text
        @booked_spots.push(er.css('td')[1].text.scan(/\d+/).map(&:to_i)[0])
        @open_spots.push(er.css('td')[1].text.scan(/\d+/).map(&:to_i)[1])
      end
    end
    @total_booked_spots = @booked_spots.map(&:to_f).reduce(:+)
    @total_open_spots = @open_spots.map(&:to_f).reduce(:+)

    erb :shows
  rescue
    erb :noresult
  end
end
