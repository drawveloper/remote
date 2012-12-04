nodestatic = require("node-static")
program = require("commander")
_u = require("underscore")
http = require("http")
bouncy = require("bouncy")
fs = require('fs')
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
program.version("0.0.5")
  .option("-d, --directory [path]", "Path to local static files directory [./]")
  .option("-h, --host [127.0.0.1]", "Host of the remote API [127.0.0.1]")
  .option("-p, --port [80]", "Port of the remote API [80]")
  .option("-n, --hostname [localhost]", "Hostname to serve the files in [localhost]")
  .option("-l, --localport [3000]", "Port of the local server [3000]")
  .option("-m, --mock [true]", "Whether to use the mock rules [true]")
  .option("-f, --file [remote.json]", "Specific configuration file [remote.json]")
  .parse process.argv

options = {}
# Initialize options with file name
_u.extend options, defaults, _u.pick(program, 'file')

# Read configuration file and override any options with it
readOptions = (filePath) ->
  try
    fileConfig = JSON.parse(fs.readFileSync(filePath))
    _u.extend(options, fileConfig) if fileConfig
  catch e
    console.error "No configuration file found!", e
    options.file = undefined
  finally
    # Override any file options with command line options
    _u.extend(options, _u.pick(program, 'directory', 'host', 'port', 'hostname', 'localport', 'mock'))
    # Show the user the selected options
    console.log options

readOptions(options.file)

# If file is defined at this point, it has been read.
if options.file
  fs.watchFile options.file, { persistent: true, interval: 1000 }, (curr, prev) ->
    unless curr.size is prev.size and curr.mtime.getTime() is prev.mtime.getTime()
      console.log "Config file changed - updating options."
      readOptions(options.file)

# Serve static files at localport + 1
options.localBouncePort = options.localport*1 + 1
# Convert "mock" attribute to boolean
options.mock = if (not options.mock or options.mock is 'false') then false else true

# Serve static files
fileServer = new (nodestatic.Server)(options.directory, { cache: 0 })
staticServer = http.createServer((request, response) ->
  request.addListener "end", ->
    fileServer.serve request, response
)

# If user defined bounces or mocks ( why else would you use this? )
if options.bounces or options.mocks
  # Start serving the files in the local bounce port
  staticServer.listen options.localBouncePort

  # Utility function to read mock from file
  readMock = (filePath) ->
    try
      return JSON.parse fs.readFileSync(filePath)
    catch e
      console.error "No file found!", e
      return undefined

  # Bounce requests
  bouncy((req, bounce) ->

    # Test if this request fits a mock (and *doesnt* fit its "unless" regex)
    mock = _u.find( options.mocks, (mock) ->
      matchURL = (new RegExp(mock.url).test req.url)
      matchUnless = if mock.unless then (new RegExp(mock.unless).test req.url) else false
      return matchURL and not matchUnless
    )
    # Test which bounce rules this request fits
    bounces = _u.filter( options.bounces, (bounce) -> (new RegExp(bounce).test req.url ) )

    if options.mock and mock
      mockJSON = mock.response ? readMock(mock.file)
      console.log 'Mocking url: ', req.url, 'Mock response: ', mockJSON
      mockResponse = bounce.respond()
      # Simply return the mock data
      mockResponse.end(JSON.stringify mockJSON)
    else if bounces?.length > 0
      console.log 'Bouncing to remote: ', req.url, ' - Matched bounce rules: ', bounces
      req.on('error', (e) ->
        console.error('Problem with the bounced request... ', e)
        req.end()
      )
      bounce options.host, options.port
    else
      console.log 'Serving static file: ', req.url
      bounce options.localBouncePort

  ).listen options.localport, options.hostname
# else, simply serve the static files.
else
  console.log "Not bouncing!"
  staticServer.listen options.localport, options.hostname

console.log "Serving local files at " + options.hostname + ":" + options.localport