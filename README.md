# Web Scraping: Getting Data from Awfully Complex Websites

A tutorial demonstrating web scrapping of MindBodyOnline client webpages

## Intro

In this README, you learn about some tools for scraping and parsing data from websites with Ruby, Capybara, Nokogiri, Firefox, and PhantomJS.  We will then try out a script that does site scraping by launching a separate web browser.  Next up, we'll launch a headless browser to do the same thing.  Finally, we'll wrap it up in a server side sinatra app for Heroku.

## Challenge

* Find active health professionals teaching recent classes
* Practice scrapping data from websites
* Search by studio ID on MindBody Online

## Prereqs

* Ruby is setup on the command line
* Familiarity with Gemfiles
* Have used Google Developer Tools
* Familiarity with [basic web scrapping](http://hunterpowers.com/data-scraping-and-more-with-ruby-nokogiri-sinatra-and-heroku/). Thanks Hunter Powers!
* Preview our [final source code results](https://github.com/adconk/mboscrape)

## Command Line Script using an automated browser instance

Let's check out [Kali Yoga Studio](http://kaliyogadc.com/) in Columbia Heights.  We want to see classes that are posted and click on "view class schedule." We then head off to MindBody Online with a Studio ID in the URL. Note this number for later use. \\
\\
[https://clients.mindbodyonline.com/ASP/home.asp?studioid=3954](https://clients.mindbodyonline.com/ASP/home.asp?studioid=3954) \\
\\
Inspect the page through Google Developer Tools.  Goodbye Mystery!  We can see all the information we are working with here.  An example section of valuable data is the instructor.
{% highlight ruby %}
<td style="width: 139px;"><a href="javascript:;" name="bio100000156" class="modalBio">Michael Joel Hall</a></td>
{% endhighlight %}

As we can see, we're battling an awfully complex site of frames, tables, and AJAX calls.  Let's write some code to programmatically launch a browser and load the webpage so that we capture all the AJAX calls and frames.  In a file called, "mbo_scrape_browser.rb", we load up a new instance of Firefox using watir-webdriver, and give it time to load the website.

```
require 'nokogiri'
require 'open-uri'

require 'watir-webdriver'

@mbo_id = ARGV[0]
browser = Watir::Browser.new :firefox
browser.goto "https://clients.mindbodyonline.com/ASP/home.asp?studioid=#{@mbo_id}"
sleep 4
```  

After starting up our new web browser instance, we are going to switch over to Nokogiri and parse the frame that holds our data of interest. We will also go ahead and use CSS selectors to grab both sets of nodes unfortunately named "evenRow" and "oddRow".

```
data = Nokogiri::HTML(browser.frame(:name => "mainFrame").html)

even_rows = data.css('.evenRow')
odd_rows = data.css('.oddRow')
```

Now that we have lists of classes and instructors, we can begin parsing out the text from the HTML.  The CSS classes "modalClassDesc" and "modalBio" are helpful to us.  In some cases, they do not exist and so we'll retrive by node array ID.

```
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
end
```

And finally, we tally up the classes and instructors, as well as show a list of unique instructor names.

```
puts "Total Weekly Classes is #{classes.count}"
puts "Instructor Count is #{instructors.uniq.count}"

instructors.uniq.each do |i|
  if i != "Cancelled Today"
    puts "#{i}"
  end
end
```

To run the script, make sure you have Mozilla Firefox installed.  Then type in the following:

```
gem install watir-webdriver
ruby mbo_scrape_browser.rb 3954
```

If you are lucky, this will run smoothly and you will see something like this

```
Total Weekly Classes is 42
Instructor Count is 15

Michael Joel Hall
Michelle Mae
Liz Saluke
Jonathan Ewing
Michael Peterson
Susan Gardinier (6)
Sachin Kandhari
Ariana Giovagnoli
Erjona Fatusha
Abby Dobbs
Alicia Moyer
Sam Breschi (2)
Susan Gardinier
Dieu Tran
```

## Command Line Script using a headless automated browser instance

The major difference between our first script, and this script, is that we switch gems, and use a different web driver.  The new web driver uses PhantomJS as the browser, instead of Firefox.  We are also inserting Capybara to interface with the web driver and headless browser.  

```
require 'capybara/poltergeist'
session = Capybara::Session.new(:poltergeist)

@mbo_id = ARGV[0]
session.visit "https://clients.mindbodyonline.com/ASP/home.asp?studioid=#{@mbo_id}"
sleep 4

title = session.title.sub(" Online","")
mbo_studio_page = session.within_frame 'mainFrame' do
  Nokogiri::HTML(session.html)
end

even_rows = mbo_studio_page.css('.evenRow')
odd_rows = mbo_studio_page.css('.oddRow')
```

We use several Capybara related methods to start, such as "visit", "title", "within_frame".  Then we hand over some HTML to Nokogiri for parsing and we're back to our old script code again. To run the script, make sure you have Mozilla Firefox installed.  Then type in the following:

```
brew install phantomjs
gem install capybara
gem install poltergeist
ruby mbo_scrape_browserless.rb 3954
```


If things go well, no browser will pop up this time, and you'll see the same results in the command line:

{% highlight text %}
Kali Yoga Studio
Total Weekly Classes is 42
Instructor Count is 15

Michael Joel Hall
Michelle Mae
Liz Saluke
Jonathan Ewing
Michael Peterson
Susan Gardinier (6)
Sachin Kandhari
Ariana Giovagnoli
Erjona Fatusha
Abby Dobbs
Alicia Moyer
Sam Breschi (2)
Susan Gardinier
Dieu Tran
```

## Heroku Web Application using a server-side, headless automated browser instance

How do we get this on the web you ask?  We turn it into an app running on a local server.  When we are ready we deploy it to Heroku as a web app.  We begin by setting up a Gemfile that says:

```
source 'https://rubygems.org'

ruby '2.1.2'

gem 'sinatra'
gem 'nokogiri'
gem 'poltergeist'
gem 'capybara'
gem 'shotgun'
```

There are two new gems here.  Sinatra, which is kind of like Rails, but much more lightweight.  Then shotgun, which makes it easy for us to run the app locally. We have one more file to setup so we can run our app. Create a file called "config.ru" and add the following:
```
# tell Sinatra what to load
require './app'

# tell Sinatra what to do
run Sinatra::Application
```

Now we copy the mbo_scrape_browserless.rb file into app.rb.  We then add sinatra and routes around our commands.  

```
require 'sinatra'
require 'capybara/poltergeist'
require 'uri'

get '/' do
  erb :input
end

post '/' do
  require 'capybara/poltergeist'
  ...
```

In the above code, you'll see "erb :input".  This is a view.  This is a good time to create a folder called "views", and files named "shows.erb", "noresult.erb", and "input.erb". The "input.erb" will be called get an HTTP GET request is sent to the root URL of our app. We also should change our MindBody URL to accept a parameter from our web app's URL, instead of a command line argument. When we do a HTTP POST request to the root URL of our app, we will be providing the Studio ID.

``
session.visit "https://clients.mindbodyonline.com/ASP/home.asp?studioid=#{params[:id]}"
``

We also need to change our ruby variables into class instance variables so that they will be available in our views.  This will have to be done through out the web app script.

```
@instructors = Array.new
@classes = Array.new
@booked_spots = Array.new
@open_spots = Array.new
```

And here is where the other two views will be used.

```
  erb :shows
rescue
  erb :noresult
end
```

To round out our app before we attempt to run it, please take a look at the following markup that represents our basic HTML views. \\
\\
[input.erb](https://github.com/adconk/mboscrape/blob/master/views/input.erb) \\
[shows.erb](https://github.com/adconk/mboscrape/blob/master/views/shows.erb) \\
[noresult.erb](https://github.com/adconk/mboscrape/blob/master/views/noresult.erb) \\
\\
To prepare for Heroku and run locally, download the phantomjs linux binary from the [website](http://phantomjs.org/). Save it to a new "\bin" folder. Now you should be ready to run the app locally.

```
bundle install
shotgun config.ru
```

Try out your web app via http://127.0.0.1:9393/ or whatever URL it states if different. One of the nice things about the web app, is that we took advantage of the fact we can link to other websites.  In the "shows.erb" file, we wrapped the instructor names with a Facebook search URL.  We can now find people pretty easily!

```
<body>
  <h2>Kali Yoga Studio</h2>
  Total Weekly Classes is 42<br>
  Instructor Count is 15<br>
  <br>
  Instructors:<br>
    <a href="https://www.facebook.com/search/str/Michael%20Joel%20Hall/users-named" target="_blank">
        Michael Joel Hall
    </a>
    <br>
    <a href="https://www.facebook.com/search/str/Michelle%20Mae/users-named" target="_blank">
        Michelle Mae
    </a>
    <br>
    <a href="https://www.facebook.com/search/str/Liz%20Saluke/users-named" target="_blank">
        Liz Saluke
    </a>
    <br>
    <a href="https://www.facebook.com/search/str/Jonathan%20Ewing/users-named" target="_blank">
        Jonathan Ewing
    </a>
    <br>
    <a href="https://www.facebook.com/search/str/Michael%20Peterson/users-named" target="_blank">
        Michael Peterson
    </a>
    <br>
    <a href="https://www.facebook.com/search/str/Susan%20Gardinier%20(6)/users-named" target="_blank">
        Susan Gardinier (6)
    </a>
    <br>
    <a href="https://www.facebook.com/search/str/Sachin%20Kandhari/users-named" target="_blank">
        Sachin Kandhari
    </a>
    <br>
    <a href="https://www.facebook.com/search/str/Ariana%20Giovagnoli/users-named" target="_blank">
        Ariana Giovagnoli
    </a>
    <br>
    <a href="https://www.facebook.com/search/str/Erjona%20Fatusha/users-named" target="_blank">
        Erjona Fatusha
    </a>
    <br>
    <a href="https://www.facebook.com/search/str/Abby%20Dobbs/users-named" target="_blank">
        Abby Dobbs
    </a>
    <br>
    <a href="https://www.facebook.com/search/str/Alicia%20Moyer/users-named" target="_blank">
        Alicia Moyer
    </a>
    <br>
    <a href="https://www.facebook.com/search/str/Sam%20Breschi%20(2)/users-named" target="_blank">
        Sam Breschi (2)
    </a>
    <br>
    <a href="https://www.facebook.com/search/str/Susan%20Gardinier/users-named" target="_blank">
        Susan Gardinier
    </a>
    <br>
    <a href="https://www.facebook.com/search/str/Dieu%20Tran/users-named" target="_blank">
        Dieu Tran
    </a>
    <br>
  <br>
  <a href="/">Back</a>
</body>
```

So how do we get this up on Heroku?  You can create a Heroku app as [they recommend here](https://devcenter.heroku.com/articles/creating-apps).  The phantomjs 64 bit binary file saved in "/bin" is the key.  This [stackoverflow article](http://stackoverflow.com/questions/12495463/how-to-run-phantomjs-on-heroku) was helpful.  And you can deploy the app as a standard Ruby app through a git push. 

Try our Studio ID of the day: 3954

Currently Blocked:
https://stackoverflow.com/questions/33225947/can-a-website-detect-when-you-are-using-selenium-with-chromedriver

Must recompile Chromium and pull chromedriver extension with a different variable name compiled.
https://chromium.googlesource.com/chromium/src/+/master/docs/mac_build_instructions.md
