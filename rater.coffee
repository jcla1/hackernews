{Config} = require './config'
fs = require 'fs'


exports.Rater = class Rater
  constructor: ->
    @logging = off
    @model = 
      words: 
        like: {}
        dislike: {}
      numberOfPostsLiked: 0
      numberOfPostsDisliked: 0
      totalNumberOfPosts: 0

  inc_word: (word, like) ->
    if like is yes
      @model.words.like[word] |= 0
      @model.words.like[word] += 1
    else if like is no
      @model.words.dislike[word] |= 0
      @model.words.dislike[word] += 1  

  inc_category: (like) ->
    @model.totalNumberOfPosts += 1
    if like is yes
      @model.numberOfPostsLiked += 1
    else if like is no
      @model.numberOfPostsDisliked += 1  

  train: (post, like) ->
    words = post.split()
    @inc_category like
    for word in words
      if word isnt undefined
        @inc_word word, like

  word_count: (word, category) ->
    console.log "start word_count" if @logging
    @model.words[category][word] or= 0.0

  word_prob: (word, cat) ->
    console.log "start word_prob" if @logging
    @word_count(word, cat) / 2.0 #num of categories


  word_weighted_average: (w, category, opts = {}) ->
    console.log "start word_weighted_average" if @logging
    weight = 1.0
    assumed_prob = 0.5

    # calculate current probability
    basic_prob = @word_prob w, category
    console.log "basic prob is #{basic_prob}" if @logging

    # count the number of times this word has appeared in all
    # categories
    w1 = parseFloat @model.words["like"][w] or= 0.0
    w2 = parseFloat @model.words["dislike"][w] or= 0.0
    totals = w1 + w2

    # the final weighted average
    (weight * assumed_prob + totals * basic_prob) / (weight + totals)
    



  doc_prob: (post, category) ->
    console.log "start doc_prob" if @logging
    m_arr = []
    words = post.split()
    for w in words
      if w isnt undefined
        m_arr.push @word_weighted_average w, category

    m_arr = m_arr.inject 1, (p,c) -> p * c
    m_arr



  text_prob: (category, post) ->
    console.log "start text_prob" if @logging
    cat_prob = @model.numberOfPostsDisliked / @model.totalNumberOfPosts
    doc_prob = @doc_prob post, category
    cat_prob * doc_prob


  cat_scores: (post) ->
    console.log "start cat_scores" if @logging
    probabilities = {}

    for k,v of @model.words
      probabilities[k] = @text_prob k, post
    probs = []
    for k,v of probabilities
      probs.push [k,v]

    probs



  classify: (post) ->
    default_cat = null
    # Find the category with the highest probability
    max_prob = 0.0
    best = undefined

    scores = @cat_scores post
    for score in scores
      category = score[0]
      probability = score[1]

      if probability > max_prob
        max_prob = probability
        best = category

    return default_cat unless best

    for score in scores
      category = score[0]
      probability = score[1]
      break if category is best
      return default_cat if probability > max_prob
    return best



  rate: (posts) ->
    for post in posts
      console.log "\033[0m"
      console.log "Title: \033[35m #{post.rawTitle} \033[0m"
      console.log "URL: #{post.url}"
      console.log "Date: #{post.date_posted}"
      console.log "User: #{post.post_user}"
      console.log "Domain: #{post.domain}"
      console.log "Votes: #{post.numOfVotes}"
      console.log "Comments: #{post.numOfComments}"
      console.log ""

      console.log "Do you like this post? (y or n):\n"
      stringResponse = fs.readSync 0, 2, null, 'utf-8'
      match = stringResponse[0].match(Config.yesnoRegEx)
      
      response = @parseResponse match

      @train post, response
      

      
  parseResponse: (match, invalidAnsw = no) ->
    if invalidAnsw
      console.log "Invalid input! Try again!"
      console.log "Do you like this post? (y or n):\n"
      stringResponse = fs.readSync 0, 2, null, 'utf-8'
      match = stringResponse[0].match(Config.yesnoRegEx)

    if match is null
      return arguments.callee match, yes
    else if match[1] is 'y'
      return yes
    else if match[1] is 'n'
      return no



  load: (path) ->
    @model = JSON.parse fs.readFileSync path

  save: (path) ->
    fs.writeFileSync path, JSON.stringify @model