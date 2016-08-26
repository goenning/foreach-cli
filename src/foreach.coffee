#!/usr/bin/env node
options =
	'g': 
		alias: 'glob'
		describe: 'Specify the glob '
		type: 'string'
	'x': 
		alias: 'execute'
		describe: 'Command to execute upon file addition/change'
		type: 'string'


fs = require('fs')
path = require('path')
glob = require('glob')
chalk = require('chalk')
statusBar = require('node-status')
console = statusBar.console()
exec = require('child_process').exec
yargs = require('yargs')
		.usage("Usage: -g <glob> -x <command>  |or|  <glob> <command>")
		.options(options)
		.help('h')
		.alias('h', 'help')
args = yargs.argv
globToRun = args.g || args.glob || args[0]
commandToExecute = args.x || args.execute || args[1]
help = args.h || args.help
regEx = placeholder: /\#\{([^\/\}]+)\}/ig
finalLogs = 'log':{}, 'warn':{}, 'error':{}

if help or not globToRun or not commandToExecute
	process.stdout.write(yargs.help());
	process.exit(0)






## ==========================================================================
## Logic
## ========================================================================== 
glob globToRun, (err, files)-> if err then return console.error(err) else
	@progress = statusBar.addItem
		'type': ['bar', 'percentage']
		'name': 'Processed'
		'max': files.length
		'color': 'green'
	
	@errorCount = statusBar.addItem
		'type': 'count'
		'name': 'Errors'
		'color': 'red'

	@totalTime = statusBar.addItem
		'type': 'time'
		'name': 'Time'
	
	statusBar.start('invert':false, 'interval':50, 'uptime':false)

	@queue = files.slice()
	processPath(@queue.pop())




processPath = (filePath)->
	if filePath
		executeCommandFor(filePath).then ()-> processPath(@queue.pop())
	
	else
		statusBar.stop()
		
		for file,message of finalLogs.log
			console.log chalk.bgWhite.black.bold.underline(file)
			console.log message
		
		for file,message of finalLogs.warn
			console.log chalk.bgYellow.black.bold.underline(file)
			console.warn message
		
		for file,message of finalLogs.error
			console.log chalk.bgRed.black.bold.underline(file)
			console.error message






executeCommandFor = (filePath)-> new Promise (resolve)->
	pathParams = path.parse filePath
	pathParams.reldir = getDirName(pathParams, path.resolve(filePath))

	console.log "Executing command for: #{filePath}"
	@progress.inc()
	@totalTime.count = process.uptime()*1000

	command = commandToExecute.replace regEx.placeholder, (entire, placeholder)-> switch
		when placeholder is 'path' then filePath
		when pathParams[placeholder]? then pathParams[placeholder]
		else entire
		

	exec command, (err, stdout, stderr)->
		if err then finalLogs.warn[filePath] = err
		if stdout then finalLogs.log[filePath] = stdout
		if stderr then @errorCount.inc(); finalLogs.error[filePath] = stderr
		resolve()






getDirName = (pathParams, filePath)->
	dirInGlob = globToRun.match(/^[^\*\/]*/)[0]
	dirInGlob += if dirInGlob then '/' else ''
	filePath
		.replace pathParams.base, ''
		.replace process.cwd()+"/#{dirInGlob}", ''
		.slice(0, -1)







