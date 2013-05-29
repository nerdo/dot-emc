dot-emc
=======

dot-emc is a doT stub for Express 3.x with support for caching and partials.

It is written in CoffeeScript, so if you plan to contribute, please make sure to work with the file in the src directory, not the js file.

Dependencies
------------
* doT
* html (optional, for pretty-printed output)

Installation
------------
`npm install dot-emc`

Usage
-----

The following is the simplest way to set up doT as the default view engine for filenames with the .def extension:

	app.engine("def", require("dot-emc").__express);
	app.set("view engine", "def");

As of version 0.1.2, the following is the recommended setup to enable all the view partial features discussed further below. Notice the call to init where the app object is passed in:

	app.set("views", path.join(__dirname, "views"));
	...
	app.engine("def", require("dot-emc").init({app: app}).__express);
	app.set("view engine", "def");

If you would rather use a different extension, you can change it in the code above, however, you will need to also let dot-emc know about it if you plan to use partials without specifying the extension, like so:

	app.set("views", path.join(__dirname, "views"));
	...
	// use .dot extension
	app.engine("dot", require("dot-emc").init({app: app, fileExtension:"dot"}).__express);
	app.set("view engine", "dot");

Views
-----

To use doT templates as views in Express, simply call render as you normally would from a route:

	app.get("/", function(req, res) {
		res.render("index", {"title": "dot-emc sample"});
	});

Partials
--------

dot-emc provides partial support by introducing the include define. Here is a very simple example:

index.def:

	{{##def.content:
		<p>dot-emc is the doT bridge for me</p>
	#}}
	{{#def.include('page')}}

The content block is defined in index.def and when page.def is included, it gets used as the html inside the content div defined below.

page.def:

	<!DOCTYPE html>
	<html>
		<head>
			<meta charset="utf-8">
			<title>dot-emc sample</title>
		</head>
		<body>
			<div id="page">
				<div class="content">
					{{#def.content || ""}}
				</div>
			</div>
		</body>
	</html>

You can also override values for includes from a view by passing an object as a 2nd parameter to include. The scope of the override is limited to the include and is illustrated in the sample below. Notice that the title returns to its original value outside of the include.

index.def:

	{{##def.content:
		<p>dot-emc is the doT bridge for me</p>
	#}}
	{{#def.include('page', {"title": "overriding the title set in the route"})}}
	{{=it.title}}

If you use the recommended dot-emc setup and pass in the app object that has the default views directory set, dot-emc will expand the ~ character in filenames to the views directory.

Suppose our page.def file was in the subdirectory layouts/default, and there is a partial named forms/login.def that defines a login form. A page template using partials might look like:

	{{##def.content:
		{{#def.include('forms/login')}}
		<p>dot-emc is the doT bridge for me</p>
	#}}
	{{#def.include('layouts/default/page')}}

The filename 'forms/login' will get expanded to 'layouts/default/forms/login'. This is because the guts of a {{##def: ... }} section don't get evaluated until the define is used. In this case, it's used inside the include to 'layouts/default/page.def', and because the working directory changes when we do the include the include to 'forms/login' is done relative to it.

One solution is to change the include to '../../forms/login'. It works, but it makes understanding the include more confusing than it needs to be, and if you move page.def, you have to update the include manually.

A better solution is to use ~ to refer to the views directory in the filename. A modified version of the template might look like:

	{{##def.content:
		{{#def.include('~/forms/login')}}
		<p>dot-emc is the doT bridge for me</p>
	#}}
	{{#def.include('~/layouts/default/page')}}

Note: The ~ will only get expanded if you pass a reference to the Express app to dot-emc's init function.

Template Caching
----------------

dot-emc will cache template files in memory by default. A useful pattern for development is to turn it off during  development. This can be done by using the init function...

	app.set("views", path.join(__dirname, "views"));
	...
	app.engine("dot", require("dot-emc").init({app: app, options:{templateSettings:{cache:false}}}).__express);
	app.set("view engine", "dot");

...but the preferred way is to set it as a template setting on doT itself, like so:

	app.configure("development", function() {
		require("dot").templateSettings.cache = false;
	});

Note: The init function can set defaults for the doT.templateSettings object, but setting them on doT directly trumps the settings passed to init.

As of version 0.1.2, you can replace the built-in cache manager with your own custom implementation. Just supply an object with get and set functions.

Here's an example that sets up a cache manager which logs cache hits and misses to the console:

	dotemc = require("dot-emc");
	...
	app.set("views", path.join(__dirname, "views"));
	dotemc.init({
		app: app,
		cacheManager: {
			get: function(filename) {
				if (filename of this.cache) {
					console.log("dot-emc cache HIT");
					return this.cache[filename];
				} else {
					console.log("dot-emc cache MISS");
				}
			},
			set: function(filename, data) {
				this.cache[filename] = data;
			},
			cache: {}
		}
	});
	app.engine("def", dotemc.__express);
	app.set("view engine", "def");

For more information on doT and its syntax, visit https://github.com/olado/doT

License
-------
http://opensource.org/licenses/MIT
