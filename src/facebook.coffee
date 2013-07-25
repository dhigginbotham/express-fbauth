_ = require "underscore"

fbgraph = require "fbgraph"

oauth = require "./auth"

# initial facebook class object which should pave the way for the rest of this circus

facebook = (opts) ->

  # collection/model to use for oauth  
  @model = null

  # prefix for initial route listening
  @prefix = "/auth/facebook"

  # add an option to set your logout prefix
  @logout_url = @prefix + "/logout"
  
  # redirect uri for facebook oauth
  @redirect_uri = "/callback"

  # callback_url is for validating your route
  # however when i designed this i forked my brain
  # for some reason, this will change -- or be gone
  # completely.
  @callback_url = "/callback"
  
  # your facebook app id
  @client_id = null

  # custom key name for either `req` or `res.locals`
  @key = null
  
  # your facebook app secret
  @client_secret = null

  # define permissions `scope`
  @scope = "email, publish_actions"

  @strategy = null

  if opts? then _.extend @, opts

  @_col = @key + "_id"
  _logout = @prefix + @logout_url

  @logout_url = _logout

  self = @

  # oauth through `fbgraph`
  @oauth = (req, res, next) ->

    # evaluate what url to pass
    if not req.query.code

      # start to build our `oauthurl`
      oauth_uri = fbgraph.getOauthUrl
        client_id: self.client_id
        redirect_uri: self.redirect_uri
        scope: self.scope

      # check to make sure we're error free!!
      if not req.query.error

        # redirect to the oauth uri
        res.redirect oauth_uri

      else

        # we've got an error, let's do something with it
        next "Sorry, facebook has reported an error: #{req.query.error}", null
    else

      # build our oauth_callback object so we can get some access to facebook
      oauth_callback =
        client_id: self.client_id
        client_secret: self.client_secret
        redirect_uri: self.redirect_uri
        code: req.query.code

      # do fbgraph.authorize to get us in the field!
      fbgraph.authorize oauth_callback, (err, response) ->
        return if err? then next err, null

        # store our access token so we can use it for awhile
        if response.access_token? then fbgraph.setAccessToken response.access_token 

        # no user found, maybe someone's being tricky?
        # else next "Whoops! It looks like Facebook didn't give us a real answer.", null

        # this will do a facebook graph call to get
        # consumable user data..
        
        fbgraph.get "me", (err, response) ->
          return if err? then next err, null

          # pass this response to a callback
          if response?
            
            if self.strategy == null 
                req[self.key] = res.locals[self.key] = response
                next null, response

            else self.strategy response, (err, saved) ->
              return if err? then next err, null

              if saved?
                req[self.key] = res.locals[self.key] = saved
                next null, saved

          else
            fn "Facebook lost your token while redirecting back here, please try again.", null

  # auth functions, `serialize, deserialize, and ensureAuthenticated` reside
  @auth = new oauth self.model, self.key
  
  @authenticate = (req, res) ->

    self.auth.serialize req[self.key], (err, id) ->
      # set session to the `optin_id` so we can `pseudo` serialize
      req.session[self._col] = id
      # send optin to their referring page
      res.redirect "back"

  # build out a way to logout -- defaults to 
  # `/auth/facebook/logout` it'll have an option though
  @logout = (req, res) ->

    # build a `route` for logging out / ie deleting your session
    # easily enough to reproduce yourself if you so choose
    if req.session.hasOwnProperty(self._col)
      delete req.session[self._col]
      res.redirect "/"
    else

      # back is a fancy fallback that will look for `referer` but
      # give the home page if not found, safely.
      res.redirect "back"

  @mount = (app) ->

    # build initial route point with oauth handler
    app.get self.prefix, self.oauth

    # we're gonna do something fancy here if there isn't a strategy --
    # we're going to store the whole shabang in to our session
    if self.strategy == null
      app.get self.prefix + self.callback_url, self.oauth, self.authenticate
    else
      app.get self.prefix + self.callback_url, self.oauth, self.authenticate, self.strategy
    
    # give access to `/logout`
    app.get self.prefix + self.logout_url, self.logout

  # persistent session
  @session = (req, res, next) ->

    # if the session exists, lets deserialize it so we can play with it in our
    # application
    if req.session.hasOwnProperty(self._col)
      
      # run those traps!
      self.auth.deserialize req.session[self._col], (err, deserialized) ->
        return if err? then next err, null

        if deserialized? then req[self.key] = res.locals[self.key] = deserialized
        
        next()

    else next()

  @

module.exports = facebook
