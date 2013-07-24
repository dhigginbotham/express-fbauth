(function() {
  var facebook, fbgraph, oauth, _;

  _ = require("underscore");

  fbgraph = require("fbgraph");

  oauth = require("./auth");

  facebook = function(opts) {
    var self;
    this.model = null;
    this.prefix = "/auth/facebook";
    this.redirect_uri = "/callback";
    this.callback_url = "/callback";
    this.client_id = null;
    this.key = null;
    this.client_secret = null;
    this.scope = "email, publish_actions";
    this.strategy = null;
    if (opts != null) {
      _.extend(this, opts);
    }
    this._col = this.key + "_id";
    self = this;
    this.oauth = function(req, res, next) {
      var oauth_callback, oauth_uri;
      if (!req.query.code) {
        oauth_uri = fbgraph.getOauthUrl({
          client_id: self.client_id,
          redirect_uri: self.redirect_uri,
          scope: self.scope
        });
        if (!req.query.error) {
          return res.redirect(oauth_uri);
        } else {
          return next("Sorry, facebook has reported an error: " + req.query.error, null);
        }
      } else {
        oauth_callback = {
          client_id: self.client_id,
          client_secret: self.client_secret,
          redirect_uri: self.redirect_uri,
          code: req.query.code
        };
        return fbgraph.authorize(oauth_callback, function(err, response) {
          if (err != null) {
            return next(err, null);
          }
          if (response.access_token != null) {
            fbgraph.setAccessToken(response.access_token);
          }
          return fbgraph.get("me", function(err, response) {
            if (err != null) {
              return next(err, null);
            }
            if (response != null) {
              if (self.strategy === null) {
                req[self.key] = res.locals[self.key] = response;
                return next(null, response);
              } else {
                return self.strategy(response, function(err, saved) {
                  if (err != null) {
                    return next(err, null);
                  }
                  if (saved != null) {
                    req[self.key] = res.locals[self.key] = saved;
                    return next(null, saved);
                  }
                });
              }
            } else {
              return fn("Facebook lost your token while redirecting back here, please try again.", null);
            }
          });
        });
      }
    };
    this.auth = new oauth(self.model, self.key);
    this.authenticate = function(req, res) {
      return self.auth.serialize(req[self.key], function(err, id) {
        req.session[self._col] = id;
        return res.redirect(req.get("Referer"));
      });
    };
    this.mount = function(app) {
      app.get(self.prefix, self.oauth);
      if (self.strategy === null) {
        return app.get(self.prefix + self.callback_url, self.oauth, self.authenticate);
      } else {
        return app.get(self.prefix + self.callback_url, self.oauth, self.authenticate, self.strategy);
      }
    };
    return this;
  };

  facebook.prototype.session = function(req, res, next) {
    var self;
    self = this;
    if (req.session.hasOwnProperty(self._col)) {
      return self.deserialize(req.session[self._col], function(err, deserialized) {
        if (err != null) {
          return next(err, null);
        }
        if (deserialized != null) {
          req[self.key] = res.locals[self.key] = deserialized;
        }
        return next();
      });
    } else {
      return next();
    }
  };

  module.exports = facebook;

}).call(this);
