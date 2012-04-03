{Post} = require './post'

exports.HNPost = class HNPost extends Post
  constructor: (obj) ->
    @numOfComments = obj.numOfComments
    @numOfVotes = obj.numOfVotes
    @post_user = obj.post_user

    super obj
