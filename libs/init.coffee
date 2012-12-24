program = require("commander")
fs = require('fs')
_u = require("underscore")

class RemoteInitializer
  constructor: (@options) ->

  initialize: =>
    # Default configuration options
    defaults =
      directory: './'
      host: '127.0.0.1'
      port: 80
      hostname: 'localhost'
      localport: 3000
      file: './remote.json'
      mock: true

    # Commander options
    program.version("0.0.7")
      .option("-d, --directory [path]", "Path to local static files directory [./]")
      .option("-j, --host [127.0.0.1]", "Host of the remote API [127.0.0.1]")
      .option("-p, --port [80]", "Port of the remote API [80]")
      .option("-n, --hostname [localhost]", "Hostname to serve the files in [localhost]")
      .option("-l, --localport [3000]", "Port of the local server [3000]")
      .option("-m, --mock [true]", "Whether to use the mock rules [true]")
      .option("-f, --file [remote.json]", "Specific configuration file [remote.json]")
      .parse process.argv

    # Initialize options with file name
    _u.extend @options, defaults, _u.pick(program, 'file')

    @readOptions(@options.file)

    # If file is defined at this point, it has been read.
    if @options.file
      fs.watchFile @options.file, { persistent: true, interval: 1000 }, (curr, prev) ->
        unless curr.size is prev.size and curr.mtime.getTime() is prev.mtime.getTime()
          console.log "Config file changed - updating options."
          readOptions(@options.file)

    # Serve static files at localport + 1
    @options.localBouncePort = @options.localport*1 + 1
    # Convert "mock" attribute to boolean
    @options.mock = if (not @options.mock or @options.mock is 'false') then false else true


  # Read configuration file and override any options with it
  readOptions: (filePath) ->
    @options.bounces = @options.mocks = undefined
    try
      fileConfig = JSON.parse(fs.readFileSync(filePath))
      _u.extend(@options, fileConfig) if fileConfig
    catch e
      console.error "No configuration file found!", e
      @options.file = undefined
    finally
    # Override any file options with command line options
      _u.extend(@options, _u.pick(program, 'directory', 'host', 'port', 'hostname', 'localport', 'mock'))
      # Show the user the selected options
      console.log @options


module.exports = RemoteInitializer