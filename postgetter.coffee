{Config} = require './config'
{HNPost} = require './hnpost'
{EventEmitter} = require 'events'

date = require './date'

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
      console.log "We have the right amount of posts (#{@unProcessedPosts.length})" if @logging

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
              console.log "jQuerying out the content" if @logging
              # Assign jQuery to the dollar
              $ = window.jQuery

              # This array will hold the raw titles 
              content = []
              
              htmlContent = ($ $('td')[4]).find 'table tr'

              # Get the "More" link and cut it from the array
              # Then get the "href" attribute and replace slashes with nothing
              lastItem = htmlContent.splice htmlContent.length - 1
              moreLink = ($ lastItem).find('a').attr 'href'
              @nextPage = moreLink.replace Config.slashRegEx, ''
              console.log "The next page is: #{@nextPage}" if @logging
              # Splice of an extra tr to get rid of some layout stuff
              htmlContent.splice htmlContent.length - 1

              counter = 0
              currentPost = {}

              htmlContent.each (key, value) =>

                pagePart = ($ value)
                
                if counter is 0

                  currentPost.title = pagePart.find('.title a').html()
                  currentPost.url = pagePart.find('.title a').attr 'href'
                  currentPost.domain = pagePart.find('.comhead').html()?.match(Config.comheadRegEx)[1]
                  
                  if typeof currentPost.domain isnt 'string'
                    currentPost.domain = "news.ycombinator.com"
                  
                  counter += 1
                  

                else if counter is 1
                  
                  if pagePart.find('span').html()
                    pointText = pagePart.find('span').html()
                    currentPost.numOfVotes = pointText.match(Config.pointsRegEx)[1]
                    currentPost.post_user = pagePart.find('a')[0].innerHTML
                    currentPost.date_posted = Date.parse pagePart.find('.subtext').html().match(Config.postDateRegEx)[1]

                    commentText = pagePart.find('a')[1].innerHTML
                    commentsMatch = commentText.match Config.commentsRegEx
                    currentPost.numOfComments = if commentsMatch[2] then commentsMatch[2] else 0
                  else 
                    currentPost.numOfVotes = 0
                    currentPost.post_user = "hackernews"
                    currentPost.date_posted = Date.parse pagePart.find('.subtext').html()
                    currentPost.numOfComments = 0

                  counter += 1
                  

                else if counter is 2
                  content.push currentPost
                  currentPost = {}
                  counter = 0
                  
                  
              
              # Added the newly scraped post titles to the rest of the un-processed titles
              @unProcessedPosts = @unProcessedPosts.concat content

              # This if statment checks to see if you have enough posts,
              # or need more, or have too many
              if @unProcessedPosts.length < @numOfPosts
                console.log "We haven't got enough posts (#{@unProcessedPosts.length})" if @logging

                # Get more Posts
                @getPosts()

              else if @unProcessedPosts.length > @numOfPosts
                console.log "We have too many posts (#{@unProcessedPosts.length})" if @logging

                # Get rid of unneeded titles
                @cutPosts()

              else if @unProcessedPosts.length is @numOfPosts
                # Tell us that we have the correct amount of titles and
                # trigger the processing
                @emit 'got posts'


  # Private: Make the raw titles in "@unProcessedPosts" into Post objects
  #
  processPosts: ->
    console.log "Processing Posts" if @logging
    
    # Loop through all the titles and add Post objects to "@posts"
    for m_obj in @unProcessedPosts
      @posts.push new HNPost m_obj
    
  # Private: Trim the size of the array to the requested number of posts
  #
  cutPosts: ->

    # Work out difference between the acctual number and the requested one
    diff = @unProcessedPosts.length - @numOfPosts

    # Cut off the titles that are too many
    @unProcessedPosts.splice(@unProcessedPosts.length - diff)

    # Now we have the correct amount of titles, tell the program
    @emit 'got posts'


  # Private: Get the next page of post title to process
  #
  getPosts: ->
    # Add the next page's dir to the url
    uri = 'http://news.ycombinator.com/' + @nextPage

    console.log "Requesting #{uri}" if @logging

    # Request the page and send it to the processing function
    request {uri: uri}, (err, response, body) =>
      @processResponse err, response, body