{Config} = require './config'
{Stopwords} = require './stopwords'
{Stemmer} = require './stemmer'

exports.Post = class Post
  constructor: (obj) ->
    
    # Indicates to the program specific things about the Post
    @processed = no
    @is_question = no
    @is_quote = no

    # Attributes of a general Post
    @rawTitle = obj.title
    @url = obj.url
    @domain = obj.domain
    @date_posted = obj.date_posted


  process: ->
  	@processed = yes

  split: ->
    title = @rawTitle.replace /[\(\)'";:,.\/?\\-]/g, ''
    title = title.replace /\s{2,}/g, ' '
    words = title.split ' '
    for word in words
      word = word.toLowerCase()
      if !Stopwords::is_stopword word
        word
