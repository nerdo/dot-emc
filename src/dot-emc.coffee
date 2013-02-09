###
doT Express Master of Ceremonies
@author Dannel Albert <cuebix@gmail.com>
###

fs = require "fs"
path = require "path"
doT = require "dot"

cache = {}
workingPaths = []
curOptions = null
curVarname = null
curPath = null

default =
	fileExtension: "def"
	options:
		cache: true

def =
	"include": (filename) ->
		returnValue = undefined
		filename = "#{filename}.#{default.fileExtension}" if !path.extname filename
		filename = path.resolve curPath, filename if curPath
		curPath = path.dirname filename
		workingPaths.push curPath

		try
			if curOptions.cache and filename of cache
				template = cache[filename]
			else
				template = cache[filename] = fs.readFileSync(filename, 'utf8')
			returnValue = doT.template(template, curOptions, def)(curOptions[curVarname])
		catch err
			workingPaths.pop()
			curPath = if workingPaths.length then workingPaths[workingPaths.length - 1] else null
			throw err

		curPath = if workingPaths.length then workingPaths[workingPaths.length - 1] else null
		returnValue

# similar to jQuery's extend method
mergeObjects = (target) ->
	deep = false
	if typeof target isnt "object"
		deep = (if target then true else false)
		target = (if arguments.legnth > 1 then arguments[1] else undefined) if deep
	i = (if deep then 2 else 1)
	argLength = arguments.length

	while i < argLength
		for key of arguments[i]
			if deep and typeof arguments[i] is "object" and typeof target[key] is "object"
				# merge recursively
				target[key] = mergeObjects deep, target[key], arguments[i][key]
			else
				target[key] = arguments[i][key]
		i++
	target

renderFile = (filename, options, fn) ->
	if typeof options == "function"
		fn = options
		options = doT.templateSettings
	fn = ( -> ) if typeof fn != "function"
	mergeObjects options, default.options, doT.templateSettings
	curVarname = options.varname or doT.templateSettings.varname
	curOptions = options

	try
		fn null, def.include filename
	catch err
		fn err

exports.__express = renderFile
exports.renderFile = renderFile
exports.init = (set) ->
	settings = mergeObjects true, settings, set
	exports
	