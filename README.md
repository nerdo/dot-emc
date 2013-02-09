dot-emc
=======

doT Express Master of Ceremonies is a doT stub for Express 3.x with support for caching and partials.

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

The following will set up doT as the default view engine for filenames with the .def extension:

	app.engine("def", require("dot-emc").__express);
	app.set("view engine", "def");

If you would rather use a different extension, you can change it in the code above, however, you will need to also let dot-emc know about it if you plan to use partials without specifying the extension, like so:

	// use .dot extension
	app.engine("dot", require("dot-emc").init({fileExtension:"dot"}).__express);
	app.set("view engine", "dot");

dot-emc will cache template files in memory by default. A useful pattern for development is to turn it off during  development. This can be done by using the init function...

	app.engine("dot", require("dot-emc").init({options:{templateSettings:{cache:false}}}).__express);
	app.set("view engine", "dot");

...but the preferred way is to set it as a template setting on doT itself, like so:

	app.configure("development", function() {
		require("dot").templateSettings.cache = false;
	});

The init function can set defaults for the doT.templateSettings object, but setting them on doT directly trumps the settings passed to init.

Partials
--------

dot-emc provides partial support by introducing the include define. Here is a very simple example:

index.def:

	{{##def.content:
		<p>dot-emc is the doT bridge for me</p>
	#}}
	{{#def.include('page')}}

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

The content block is defined in index.def and when page.def is included, it gets used as the html inside the content div.

Views
-----

To use the doT templates above as a view, call render as you normally would from a route:

	app.get("/", function(req, res) {
		res.render("index", {"title": "dot-emc sample"});
	});

For more information on doT and its syntax, visit https://github.com/olado/doT

License
-------
http://opensource.org/licenses/MIT
