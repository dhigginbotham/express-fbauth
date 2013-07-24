(function() {
  var auth, _;

  _ = require("underscore");

  auth = function(model, key, opts) {
    this.model = model;
    this.key = key;
    this._col = key + "_id";
    if (opts != null) {
      return _.extend(this, opts);
    }
  };

  auth.prototype.serialize = function(user, fn) {
    if (user != null) {
      return fn(null, user._id);
    } else {
      return fn("Sorry, we couldn't connect you to the server, please try again.", null);
    }
  };

  auth.prototype.deserialize = function(id, fn) {
    var self;
    self = this;
    return self.model.findOne({
      _id: id
    }, function(err, model) {
      if (err != null) {
        return fn(err, null);
      }
      if (model != null) {
        return fn(null, model);
      }
    });
  };

  auth.prototype.ensureAuthenticated = function(req, fn) {
    var query, self;
    self = this;
    if (req.session.hasOwnProperty(self._col)) {
      query = req.session[self._col];
      return self.model.findOne({
        _id: query
      }, function(err, model) {
        if (err != null) {
          return fn(err, null);
        }
        if (model != null) {
          return fn(null, model);
        } else {
          return fn("Your _id could not be validated, please try again", null);
        }
      });
    } else {
      return fn("You must be authenticated to use this route", null);
    }
  };

  module.exports = auth;

}).call(this);
