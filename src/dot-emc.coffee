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

workingPaths = []
curOptions = null
curPath = null

defaults =
	fileExtension: "def"
	cacheManager:
		get: (filename) -> @cache[filename]
		set: (filename, data) -> @cache[filename] = data
		cache: {}
	options:
		templateSettings:
			cache: true

if html then defaults.options.prettyPrint =
	indent_char: "	"
	indent_size: 1

class Defines
	include: (filename, vars) ->
		returnValue = undefined
		filename = filename.replace '~', defaults.app?.get "views" or '~'
		filename = "#{filename}.#{defaults.fileExtension}" if !path.extname filename
		filename = path.resolve curPath, filename if curPath
		curPath = path.dirname filename
		workingPaths.push curPath
		vars = if typeof vars != "object" then curOptions else mergeObjects true, clone(curOptions), vars

		try
			usingCache = curOptions.templateSettings.cache
			if usingCache
				cacheManager = defaults.cacheManager
				template =  cacheManager.get filename
			if typeof template is "undefined"
				template = fs.readFileSync filename, "utf8"
			cacheManager.set filename, template if usingCache
			returnValue = doT.template(template, curOptions.templateSettings, @)(vars)
			workingPaths.pop()
		catch err
			workingPaths.pop()
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
exports.init = (settings) ->
	defaults = mergeObjects true, defaults, settings
	exports
