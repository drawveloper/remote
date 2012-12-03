nodestatic = require("node-static")
program = require("commander")
_u = require("underscore")
http = require("http")
bouncy = require("bouncy")
# Default configuration options
defaults =
  directory: './'
  host: '127.0.0.1'
  port: '80'
  hostname: 'localhost'
  localport: '3000'
  file: './remote.json'
  mock: true

# Commander options
program.version("0.0.1")
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
try
  fileConfig = require(options.file)
  if (fileConfig)
    _u.extend options, fileConfig
catch e
  console.error "No configuration file found!", e

# Override any file options with command line options
_u.extend options, _u.pick(program, 'directory', 'host', 'port', 'hostname', 'localport', 'mock')

# Serve static files at localport + 1
options.localBouncePort = options.localport*1 + 1
# Convert "mock" attribute to boolean
options.mock = if (not options.mock or options.mock is 'false') then false else true

# Show the user the selected options
console.log options

# Serve static files
fileServer = new (nodestatic.Server)(options.directory, { cache: 0 })
staticServer = http.createServer((request, response) ->
  request.addListener "end", ->
    fileServer.serve request, response
)

# If user defined bounces ( why else would you use this? )
if options.bounces
  # Start serving the files in the local bounce port
  staticServer.listen options.localBouncePort

  # Bounce requests
  bouncy((req, bounce) ->

    # Test if this request fits a mock (and *doesnt* fit its "unless" regex)
    mock = _u.find( options.mocks, (mock) -> (new RegExp(mock.url).test req.url) and not (new RegExp(mock.unless).test req.url) )
    # Test which bounce rules this request fits
    bounces = _u.filter( options.bounces, (bounce) -> (new RegExp(bounce).test req.url ) )

    if options.mock and mock
      console.log 'Mocking url: ', req.url, 'Mock response: ', mock.response
      mockResponse = bounce.respond()
      # Simply return the mock data
      mockResponse.end(JSON.stringify mock.response)
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