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
tplDepth = 0

defaults =
	fileExtension: "def"
	options:
		templateSettings: 
			cache: true
			literalDelimiters:
				start: '{{@'
				end: '@}}'

if html then defaults.options.prettyPrint =
	indent_char: "	"
	indent_size: 1

# CoffeeScript version of fast string repeat posted at http://stackoverflow.com/a/14026829/2057996
repeat = (s, count) ->
	return "" if count < 1
	result = ""
	pattern = s.valueOf()
	while count > 1
		result += pattern if count & 1
		count >>= 1
		pattern += pattern
	result += pattern

class Defines
	include: (filename, vars) ->
		tplDepth++
		returnValue = undefined
		filename = "#{filename}.#{defaults.fileExtension}" if !path.extname filename
		filename = path.resolve curPath, filename if curPath
		curPath = path.dirname filename
		workingPaths.push curPath
		switch typeof vars
			when "object"
				vars = mergeObjects true, clone(curOptions), vars
			when "boolean"
				# it's a flag for whether to "bubble wrap" the template in literal tags
				# this will ensure that wherever the define is used, it comes out literally
				lDepth = if vars then tplDepth else 1
			when "number"
				lDepth = vars
			when "undefined", "string"
				vars = curOptions

		try
			if curOptions.templateSettings.cache and filename of cache
				template = cache[filename]
			else
				template = cache[filename] = fs.readFileSync filename, 'utf8'

			if typeof vars == "object"
				returnValue = doT.template(template, curOptions.templateSettings, @)(vars)
			else
				if lDepth > 1
					ld = defaults.options.templateSettings.literalDelimiters
					returnValue =  " #{repeat(ld.start, lDepth - 1)} #{template} #{repeat(ld.end, lDepth - 1)} "
				else 
					returnValue = template
				console.log "filename = #{filename}"
				console.log "returnValue = " + returnValue
			workingPaths.pop()
			tplDepth--
		catch err
			workingPaths.pop()
			tplDepth--
			curPath = if workingPaths.length then workingPaths[workingPaths.length - 1] else null
			throw err

		curPath = if workingPaths.length then workingPaths[workingPaths.length - 1] else null
		returnValue

# modeled after jQuery's extend method
mergeObjects = () ->
	target = arguments[0]
	if typeof target is "boolean"
		deep = target
		target = arguments[1] or {}
		start = 2
	else
		deep = false
		target = arguments[0] or {}
		start = 1

	argLength = arguments.length

	if deep
		for i in [start..argLength]
			arg = arguments[i]
			continue if !arg
			for key of arg
				val = arg[key]
				continue if target == val
				t = target[key]
				valIsArray = val instanceof Array
				valIsObject = !valIsArray and typeof val == "object"
				if (val) and (valIsObject or valIsArray)
					val = val.slice(0) if valIsArray
					if key of target
						if valIsArray
							t = if t instanceof Array then t else []
						else
							t = if typeof t is "object" then t else {}
						target[key] = mergeObjects true, (if valIsArray then [] else {}), t, val
					else
						target[key] = val
				else if val != undefined
					target[key] = val
	else
		for i in [start..argLength]
			arg = arguments[i]
			for key of arg
				val = arg[key]
				target[key] = val if val != undefined

	target

clone = (obj) -> mergeObjects true, {}, obj

renderFile = (filename, options, fn) ->
	if typeof options == "function"
		fn = options
		options = {}
	fn = ( -> ) if typeof fn != "function"
	curOptions = mergeObjects true, options, defaults.options, templateSettings: doT.templateSettings
	def = new Defines()

	try
		if html and curOptions.pretty
			fn null, html.prettyPrint def.include(filename), curOptions.prettyPrint or {}
		else
			fn null, def.include filename
	catch err
		fn err

exports.__express = renderFile
exports.renderFile = renderFile
exports.Defines = Defines
exports.mergeObjects = mergeObjects
exports.clone = clone
exports.init = (settings) ->
	defaults = mergeObjects true, defaults, settings
	# rebuild literal regex
	ts = defaults.options.templateSettings
	ts.literal = new RegExp(
		ts.literalDelimiter.start.replace(/[-[\]{}()*+?.,\\^$|#\s]/g, "\\$&") +
		"([\\s\\S]+?)" +
		ts.literalDelimiter.end.replace(/[-[\]{}()*+?.,\\^$|#\s]/g, "\\$&"),
		"g"
	)
	exports
