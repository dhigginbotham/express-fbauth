## Express FBAuth
I needed a way to play with facebook that did things like passport, but allowed me to store things to different `req` objects, as well as send `res.locals` some goods. I decided that I would implement someone elses library to handle to oauth/facebook graph stuff, why reinvent a perfectly good wheel? I chose `fbgraph` and from experience it's one of the better facebook graph api wrappers for node. I plan on adding in a bunch of the auth routes so it's easy to return json from internal paths -- but thats all tbd once I get this proof of concept off the ground.

Use this as you choose, submit any errors and I'll fix them :)

![](https://badge.fury.io/js/express-fbauth.png)

### Usage
```md
npm install express-fbauth
```

### Example setup
```js
var express = require('express');
var app = express();

// require fbauth
var fbauth = require('express-fbauth');

// some collection you'd like to use for your authed users
var Model = require('./some/db/collection/path');

// options you'll want to set... 
var options = {
  model: Model,
  prefix: "/auth/facebook",
  client_id: "CLIENT_ID",
  client_secret: "CLIENT_SECRET",
  redirect_uri: "http://localhost:3000/auth/facebook/callback",
  scope: "email, publish_actions",
  key: "optin",
  strategy: function (profile, fn) {
    // do a crud task with `mongoose` like `findAndUpdate` or `findAndCreate`
  }
};

// create your `facebook` object so you can do stuff
facebook = new fbauth(options);

// persist your session like you can in `passport.js`
app.use(facebook.session);

// mount the auth routes
facebook.mount(app);
```

You'll receive some routes based on this:

```md
http://localhost:3000/auth/facebook
http://localhost:3000/auth/facebook/logout
```

## Options
Key | Default | Description
--- | --- | ---
**model** | `null` | The users/optins model you want to use
**prefix** | `/auth/facebook` | route prefix, ie `http://localhost:3000/auth/facebook`
**logout** | `/auth/facebook/logout` | defaults to `prefix + /logout`
**redirect_uri** | `http://localhost:3000/auth/facebook/callback` | use full url path
**callback_uri** | `/callback` | use last path ie `/callback`
**client_id** | `null` | use the one from your facebook app
**key** | `null` | almost anything works, however I am not sanitizing yet
**client_secret** | `null` | use the one from your facebook app
**scope** | `email, publish_actions` | see facebook docs for full list of scope/perms
**strategy** | `null` | finally, your end-point, the little guy that goes in and finds, updates or creates something

## License
```md
The MIT License (MIT)

Copyright (c) 2013 David Higginbotham 

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in
all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
THE SOFTWARE.
```

