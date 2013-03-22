StaticServer = require('./static.coffee')
ProxyServer = require('./proxy.coffee')
Initializer = require('./init.coffee')
_u = require("underscore")
fs = require('fs')
GLOBAL.verbose = true

module.exports = (options = {}) ->
  GLOBAL.verbose = options.verbose or GLOBAL.verbose
  options = _u.defaults options, Initializer.defaults

  # If we are being started from command line
  if options.cli
    cliOptions = Initializer.parseOptionsFromCLI()
    console.log 'CLI Options', cliOptions if GLOBAL.verbose

  # If the user has specified a file
  file = cliOptions?.file or options?.file
  if file
    console.log("Using file:", file)
    fileOptions = Initializer.parseOptionsFromFile(file)
    console.log 'File Options', fileOptions if GLOBAL.verbose

  # Override any file options with command line options
  options = _u.extend(options, fileOptions, cliOptions)
  # Show the user the selected options
  console.log options

  # Watch changes to configuration.
  if options.file
    fs.watchFile options.file, { persistent: true, interval: 1000 }, (curr, prev) =>
      unless curr.size is prev.size and curr.mtime.getTime() is prev.mtime.getTime()
        console.log "Configuration file changed - updating options."
        Initializer.parseOptionsFromFile(options.file)

  # Start the static server if a directory has been provided
  new StaticServer(options).start() if options.directory
  console.log("Remote -- bouncing to server at", options.server.host + ":" + options.server.port) unless options.directory

  # Start the reverse proxy
  new ProxyServer(options).start()
