exports.Config = class Config
  @numberOfPostToGet = 60
  @punctuationRegEx = /['";:,.\/?\\-]/g
  @slashRegEx = /\//g
  @questionRegEx = /\?$/