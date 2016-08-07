#!/usr/bin/env node
// Generated by CoffeeScript 1.10.0
(function() {
  var args, commandToExecute, exec, executeCommandFor, fs, getDirName, glob, globToRun, help, options, path, processPath, regEx, yargs;

  options = {
    'g': {
      alias: 'glob',
      describe: 'Specify the glob ',
      type: 'string',
      demand: true
    },
    'x': {
      alias: 'execute',
      describe: 'Command to execute upon file addition/change',
      type: 'string',
      demand: true
    }
  };

  fs = require('fs');

  path = require('path');

  glob = require('glob');

  exec = require('child_process').exec;

  yargs = require('yargs').usage("Usage: -g <glob> -x <command>").options(options).help('h').alias('h', 'help');

  args = yargs.argv;

  globToRun = args.g || args.glob || args[0];

  commandToExecute = args.x || args.execute || args[1];

  help = args.h || args.help;

  regEx = {
    placeholder: /\#\{([^\/\}]+)\}/ig
  };

  if (help) {
    process.stdout.write(yargs.help());
    process.exit(0);
  }

  glob(globToRun, function(err, files) {
    if (err) {
      return console.log(err);
    }
    this.queue = files.slice();
    return processPath(this.queue.pop());
  });

  processPath = function(filePath) {
    if (filePath) {
      return executeCommandFor(filePath).then(function() {
        return processPath(this.queue.pop());
      });
    }
  };

  executeCommandFor = function(filePath) {
    return new Promise(function(resolve) {
      var command, pathParams;
      pathParams = path.parse(filePath);
      pathParams.reldir = getDirName(pathParams, path.resolve(filePath));
      console.log("Executing command for: " + filePath);
      command = commandToExecute.replace(regEx.placeholder, function(entire, placeholder) {
        if (placeholder === 'path') {
          return filePath;
        } else if (pathParams[placeholder] != null) {
          return pathParams[placeholder];
        } else {
          return entire;
        }
      });
      return exec(command, function(err, stdout, stderr) {
        if (err) {
          console.log(err);
        }
        if (stdout) {
          console.log(stdout);
        }
        if (stderr) {
          console.log(stderr);
        }
        return resolve();
      });
    });
  };

  getDirName = function(pathParams, filePath) {
    var dirInGlob;
    dirInGlob = globToRun.match(/^[^\*\/]*/)[0];
    dirInGlob += dirInGlob ? '/' : '';
    return filePath.replace(pathParams.base, '').replace(process.cwd() + ("/" + dirInGlob), '').slice(0, -1);
  };

}).call(this);
