# lineman + Rails 3

If you're on Rails 4, be sure to use the officially supported `rails-lineman` gem and `lineman-rails` npm module duo. You can read about them [at Lineman's homepage](http://linemanjs.com/rails.html).

If you're on Rails 3, however, the `assets:precompile` rake task changed enough that it is not compatible with the official gem.

This repo gives an unsupported example of how you might work around that.

Enclosed is a lineman application in the `lineman-app` directory. You can start it up with:

# Lineman in development mode

`lineman run`

And note that it sets up static routes from "js","css", and "img" to "assets/lineman/js" (and "css", and "img") in its `config/server.js` file.

It also turns on asset fingerprinting and server proxying in `config/application.js`

``` javascript

server: {
  apiProxy: {
    enabled: true,
    host: 'localhost',
    port: 3000
  }
},
enableAssetFingerprint: true

```

You'll develop against Lineman's port so that it can proxy back to Rails (e.g. always hit your app in your browser from port 8000 when you want to see Lineman assets)

# Rails in development mode

The rails application only referencs lineman in the `app/views/things/index.html.erb` template:

``` erb
<%= stylesheet_link_tag    "lineman/css/app", :media => "all" %>
<%= javascript_include_tag "lineman/js/app" %>
```

So long as you hit the app on port 8000 with both Rails & Lineman running, the route [/things](http://localhost:8000/things) should show you both the "I AM RAILS" text of the rails view and also the lineman JS (an alert) & CSS (a background image)

# Rails in production

The repo monkey-patches Rails 3's rake task "assets:precompile:nondigest" in `lib/tasks/lineman_assets_precompile_ext.rake`. First, `assets:precompile` will run as it always has, but then three more things will happen:

1. The lineman project will be built (`npm install && lineman clean build`)
2. The lineman built assets (in `lineman-app/dist`) will be copied to `public/assets/lineman`
3. The rake task modifies Rails' `public/assets/manifest.yml` by appending all of the Lineman resources to it, so that the view helpers can find the precompiled assets with their fingerprinted filenames.
