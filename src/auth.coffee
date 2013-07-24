_ = require "underscore"

auth = (model, key, opts) ->

  @model = model
  @key = key
  @_col = key + "_id"

  if opts? then _.extend @, opts

# serializing your oauth client is easy, just like passport
auth::serialize = (user, fn) ->
  if user? then fn null, user._id 
  
  else fn "Sorry, we couldn't connect you to the server, please try again.", null

# deserializing your oauth client is easy, just like passport
auth::deserialize = (id, fn) ->

  self = @

  self.model.findOne {_id: id}, (err, model) ->
    return if err? then fn err, null

    if model? then fn null, model

auth::ensureAuthenticated = (req, fn) ->

  self = @

  if req.session.hasOwnProperty(self._col)

    query = req.session[self._col]

    self.model.findOne {_id: query}, (err, model) ->
      return if err? then fn err, null
      
      if model?
        fn null, model
      else
        fn "Your _id could not be validated, please try again", null

  else fn "You must be authenticated to use this route", null

module.exports = auth
