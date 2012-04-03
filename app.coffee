{Rater} = require './rater'
{Postgetter} = require './postgetter'
{Config} = require './config'
{HNPost} = require './hnpost'

b = new Rater
b.load 'model.json'

a = new Postgetter 150, (posts) =>
  #b.rate posts
  #b.save 'model.json'
  for post in posts
    console.log post.rawTitle + ': ' + b.classify post
