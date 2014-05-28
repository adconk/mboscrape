require 'sinatra'
require 'capybara/poltergeist'

get '/' do
  erb :input
end

post '/' do
  require 'capybara/poltergeist'
  session = Capybara::Session.new(:poltergeist)

  #@mbo_id = '3954'
  session.visit "https://clients.mindbodyonline.com/ASP/home.asp?studioid=#{params[:id]}"
  sleep 4
  mbo_studio_page = session.within_frame 'mainFrame' do
    Nokogiri::HTML(session.html)
  end
  even_rows = mbo_studio_page.css('.evenRow')
  odd_rows = mbo_studio_page.css('.oddRow')

  @instructors = Array.new
  @classes = Array.new

  even_rows.each do |er|
    if (defined? er.at_css('.modalBio').text) && (defined? er.at_css('.modalClassDesc').text)
      @classes.push(er.at_css('.modalClassDesc').text)
      @instructors.push(er.at_css('.modalBio').text)
    end
  end

  odd_rows.each do |er|
    if (defined? er.at_css('.modalBio').text) && (defined? er.at_css('.modalClassDesc').text)
      @classes.push(er.at_css('.modalClassDesc').text)
      @instructors.push(er.at_css('.modalBio').text)
    end
  end
  erb :shows
end
