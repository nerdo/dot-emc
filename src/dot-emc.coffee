###
doT Express Master of Ceremonies
@author Dannel Albert <cuebix@gmail.com>
@license http://opensource.org/licenses/MIT
###

fs = require "fs"
path = require "path"
doT = require "dot"

# optional html pretty printer
try
	html = require "html"
catch e
	throw e if e.code != "MODULE_NOT_FOUND"

cache = {}
workingPaths = []
curOptions = null
curPath = null

defaults =
	fileExtension: "def"
	options:
		templateSettings: 
			cache: true

if html then defaults.options.prettyPrint =
	indent_char: "	"
	indent_size: 1

def =
	"include": (filename) ->
		returnValue = undefined
		filename = "#{filename}.#{defaults.fileExtension}" if !path.extname filename
		filename = path.resolve curPath, filename if curPath
		curPath = path.dirname filename
		workingPaths.push curPath

		try
			if curOptions.templateSettings.cache and filename of cache
				template = cache[filename]
			else
				template = cache[filename] = fs.readFileSync filename, 'utf8'
			returnValue = doT.template(template, curOptions.templateSettings, def)(curOptions)
		catch err
			workingPaths.pop()
			curPath = if workingPaths.length then workingPaths[workingPaths.length - 1] else null
			throw err

		curPath = if workingPaths.length then workingPaths[workingPaths.length - 1] else null
		returnValue

# modeled after jQuery's extend method
mergeObjects = (target) ->
	if typeof target isnt "object"
		return target if arguments.length == 1
		deep = (if target then true else false)
		target = arguments[1]
		i = 2
	else
		deep = false
		i = 1

	argLength = arguments.length

	if deep
		while i < argLength
			arg = arguments[i]
			for key of arg
				if typeof arg is "object" and typeof target[key] is "object"
					# merge recursively
					target[key] = mergeObjects deep, target[key], arg[key]
				else
					target[key] = arg[key]
			i++
	else
		while i < argLength
			arg = arguments[i]
			for key of arg
					target[key] = arg[key]
			i++

	target

renderFile = (filename, options, fn) ->
	if typeof options == "function"
		fn = options
		options = {}
	fn = ( -> ) if typeof fn != "function"
	curOptions = mergeObjects true, options, defaults.options, templateSettings: doT.templateSettings

	try
		if html and curOptions.pretty
			fn null, html.prettyPrint def.include(filename), curOptions.prettyPrint or {}
		else
			fn null, def.include filename
	catch err
		fn err

exports.__express = renderFile
exports.renderFile = renderFile
exports.init = (settings) ->
	defaults = mergeObjects true, defaults, settings
	exports
