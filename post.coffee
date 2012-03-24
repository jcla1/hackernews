{Config} = require "./config"

exports.Post = class Post
  constructor: (title) ->
    @rawTitle = title
    @processed = no
    @is_question = no
    @is_quote = no

  process: ->
  	@is_question = Config.questionRegEx.test @rawTitle