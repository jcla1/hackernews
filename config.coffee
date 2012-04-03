exports.Config = class Config
  @numberOfPostToGet = 60

  @punctuationRegEx = /['";:,.\/?\\-]/g
  @slashRegEx = /\//g
  @pointsRegEx = /^(.*) point/
  @postDateRegEx = /<\/a>\s(.*)\s\s\|/
  @commentsRegEx = /((.*)\scomment)|(discuss)/
  @comheadRegEx = /^\s\((.*)\)\s$/
  @questionRegEx = /\?$/

  @yesnoRegEx = /([yn])\n$/
  @stripStartRegex = /^\s+/
  @stripEndRegex = /\s+$/



Array::each = (f) ->
  len = @length;
  i = 0
  while i < len
  	f @[i]
  	i++

Array::inject = (memo, iterator, context) ->
  iterator = iterator.bind context
  @each (value, index) ->
    memo = iterator memo, value, index

  memo