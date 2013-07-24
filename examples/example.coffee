express = require "express"
app = module.exports = express()

# going to make mount point for `facebook` auth for optins
# this will allow us to not use passport to create the optin,
# but still keep up with our consistency. 

facebook = require "../../apps/express-facebook-authorize"

Optin = require "../../../app/models/donation/optin"

conf = require "../../../helpers/config"

findOrCreate = (profile, fn) ->

  # we're going to check for the existence of this optin
  # user and update their account or make a new one..
  
  # rename profile to `fb` keeps some scope
  fb = profile

  # build out a query string, we can be pretty strict here
  # because we're requiring an email directly from facebook
  # and not determined upon user input..
  query = if fb? then {email: fb.email} else {}

  # let's just be super truthy here and make sure that we've
  # actually got this validating.
  if query.hasOwnProperty("email")

    # build out our new optin object
    _optin = fb
    # we're going to store extended as JSON, we'll parse it later
    # if necessary
    json = JSON.stringify profile

    _optin.ts = new Date()
    _optin._extended = json
    _optin.facebook = JSON.parse json

    # do findOrCreate and set upsert to true, this will give us a 
    # pseudo update that we'll appreciate later    
    Optin.findOrCreate query, _optin, {upsert: true}, (err, optin) ->
      return if err? then fn err, null

      # check that optin is there, otherwise -- issues.
      if optin? 

        # pass through our optin, just in case we need to add another
        # middleware to the stack later on
        fn null, optin

options =
  model: Optin
  client_id: conf.pass.fb.id
  client_secret: conf.pass.fb.secret
  redirect_uri: conf.pass.redirectUrl + conf.pass.fb.route
  key: "optin"
  strategy: findOrCreate

fb = new facebook options
app.use fb.session
fb.mount app