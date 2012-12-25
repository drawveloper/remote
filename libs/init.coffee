program = require("commander")
fs = require('fs')
_u = require("underscore")
path = require('path')

class RemoteInitializer
  # Default configuration options
  defaults:
    directory: './'
    remotehost: '127.0.0.1'
    remoteport: 80
    localhost: 'localhost'
    localport: 3000
    bounceport: 3001
    bounceToRemote: false
    file: './remote.json'
    mapping: false

  constructor: (@options) ->

  initialize: =>
    # Commander options
    program.version("0.1.0")
      .option("-d, --directory [path]", "Path to local static files directory [./]")
      .option("-j, --remotehost [127.0.0.1]", "Host of the remote API [127.0.0.1]")
      .option("-p, --remoteport [80]", "Port of the remote API [80]")
      .option("-l, --localhost [localhost]", "Hostname to serve the files in [localhost]")
      .option("-q, --localport [3000]", "Port of the local proxy server [3000]")
      .option("-b, --bounceport [3001]", "Port of the local file server [3001]")
      .option("-m, --mapping [false]", "Whether to use the mapping rules [false]")
      .option("-f, --file [remote.json]", "Specific configuration file [remote.json]")
      .parse process.argv

    # Initialize options with file name
    _u.extend @options, @defaults, _u.pick(program, 'file')
    # Resolve relative path
    @options.file = path.resolve(process.cwd(), @options.file)

    @readOptions(@options.file)

    # If file is defined at this point, it has been read.
    if @options.file
      fs.watchFile @options.file, { persistent: true, interval: 1000 }, (curr, prev) ->
        unless curr.size is prev.size and curr.mtime.getTime() is prev.mtime.getTime()
          console.log "Config file changed - updating options."
          readOptions(@options.file)

    # Convert "mapping" attribute to boolean
    @options.mapping = if (not @options.mapping or @options.mapping is 'false') then false else true


  # Read configuration file and override any options with it
  readOptions: (filePath) ->
    @options.bounces = @options.mappings = undefined
    try
      fileConfig = JSON.parse(fs.readFileSync(filePath))
      _u.extend(@options, fileConfig) if fileConfig
    catch e
      console.error "No configuration file found!", e
      @options.file = undefined
    finally
      # Override any file options with command line options
      _u.extend(@options, _u.pick(program, 'directory', 'remotehost', 'remoteport', 'localhost', 'localport', 'bounceport', 'mapping'))
      # Resolve relative path
      @options.directory = path.resolve(process.cwd(), @options.directory)
      # Show the user the selected options
      console.log @options


module.exports = RemoteInitializer