{Config} = require './config'
{Post} = require './post'
{EventEmitter} = require 'events'

jsdom = require 'jsdom'
request = require 'request'


# Public: Class to get posts from HN
#
# numOfPosts  - Number of posts to get
# callback    - A callback function that gets called when posts are ready
#
exports.Postgetter = class Postgetter extends EventEmitter
  constructor: (numOfPosts, callback) ->
    # For intializing the EventEmitter in this Object
    EventEmitter.call @

    # Logging is off by defualt
    @logging = off

    # This array will hold 'Post' objects
    @posts = []

    # This array will hold the raw titles of Posts
    @unProcessedPosts = []

    # The variable that indicates the next page's directory
    @nextPage = ""

    # The number of posts requested
    @numOfPosts = numOfPosts

    # The callback function to call after all posts have been processed
    @callback = callback

    # This will be triggered when there are enough unique raw titles
    @on 'got posts', ->
      console.log 'We have the right amount of posts' if @logging

      # Process the post titles into Post objects
      @processPosts()

      # Call the callback with the Post objects
      @callback @posts

    # Run the function to get the post titles
    @getPosts()

  # Private: Parse out post titles from a given HTML body
  #
  # err       - An error object from "request"
  # response  - The HTTP response recieved from HN
  # body      - Th raw body in HTML as a string
  #
  processResponse: (err, response, body) ->
    # See if there are any errors
    throw 'Request error.' if err or response.statusCode != 200

    # Setup the jsdom env
    jsdom.env {

            # The HTML to use
            html: body,

            # Load any extra scripts
            scripts: ['http://code.jquery.com/jquery-latest.js']
            }, (err, window) =>
              # Assign jQuery to the dollar
              $ = window.jQuery

              # This array will hold the raw titles 
              content = []

              # The "a" elements holding the post titles
              # also including the "More" link
              htmlContent = ($ '.title a')

              # Get the "More" link and cut it from the array
              # Then get the "href" attribute and replace slashes with nothing
              lastItem = htmlContent.splice(htmlContent.length - 1)
              @nextPage = $(lastItem).attr('href').replace(Config.slashRegEx, '')

              # Loop through all the "a" elements and
              # add the title to the contents array
              htmlContent.each (key, value) ->
                content.push value.innerHTML

              # Added the newly scraped post titles to the rest of the un-processed titles
              @unProcessedPosts = @unProcessedPosts.concat content

              console.log @unProcessedPosts.length if @logging

              # This if statment checks to see if you have enough posts,
              # or need more, or have too many
              if @unProcessedPosts.length < @numOfPosts
                console.log "We haven't got enough posts" if @logging

                # Get more Posts
                @getPosts()

              else if @unProcessedPosts.length > @numOfPosts
                console.log "We have too many posts" if @logging

                # Get rid of unneeded titles
                @cutPosts()

              else if @unProcessedPosts.length is @numOfPosts
                # Tell us that we have the correct amount of titles and
                # trigger the processing
                @emit "got posts"


  # Private: Make the raw titles in "@unProcessedPosts" into Post objects
  #
  processPosts: ->
    console.log "Processing Posts" if @logging
    
    # Loop through all the titles and add Post objects to "@posts"
    for title in @unProcessedPosts
      @posts.push new Post title
    
  # Private: Trim the size of the array to the requested number of posts
  #
  cutPosts: ->
    # Work out difference between the acctual number and the requested one
    diff = @unProcessedPosts.length - @numOfPosts

    # Cut off the titles that are too many
    @unProcessedPosts.splice(@unProcessedPosts.length - diff)

    # Now we have the correct amount of titles, tell the program
    @emit "got posts"


  # Private: Get the next page of post title to process
  #
  getPosts: ->
    # Add the next page's dir to the url
    uri = 'http://news.ycombinator.com/' + @nextPage

    console.log uri if @logging

    # Request the page and send it to the processing function
    request {uri: uri}, (err, response, body) =>
      @processResponse err, response, body
