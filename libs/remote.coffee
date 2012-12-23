send = require("send")
url = require("url")
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
program.version("0.0.7")
  .option("-d, --directory [path]", "Path to local static files directory [./]")
  .option("-j, --host [127.0.0.1]", "Host of the remote API [127.0.0.1]")
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
  options.bounces = options.mocks = undefined
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
staticServer = http.createServer( (req, res) ->
  error = (err) ->
    res.statusCode = err.status || 500
    console.error(err.message)
    res.end(err.message)

  redirect = ->
    res.statusCode = 301
    res.setHeader('Location', req.url + '/')
    res.end('Redirecting to ' + req.url + '/')

  send(req, url.parse(req.url).pathname)
    .root(options.directory)
    .on('error', error)
    .on('directory', redirect)
    .pipe(res)
)

# Start serving the files in the local bounce port
staticServer.listen options.localBouncePort

# Utility function to read mock from file
readMock = (filePath, callback) ->
  try
    fs.readFile(filePath, (err, data) ->
      if err then callback(err) else callback(JSON.parse data)
    )
  catch e
    console.error "No file found!", e
    callback(e)

# Bounce requests
bouncy((req, bounce) ->
  # Test if this request fits a mock (and *doesnt* fit its "unless" regex)
  mock = _u.find( options.mocks, (mock) ->
    matchURL = (new RegExp(mock.url).test req.url)
    matchUnless = if mock.unless then (new RegExp(mock.unless).test req.url) else false
    return matchURL and not matchUnless
  ) if options.mocks

  # Test which bounce rules this request fits
  bounces = _u.filter( options.bounces,
    (bounce) -> (new RegExp(bounce).test req.url ) ) if options.bounces

  if options.mock and mock
    # Handler to end this response with a mock
    endResponse = (data) ->
      console.log 'Mocking url: ', req.url, 'Mock response: ', data
      mockResponse = bounce.respond()
      # Simply return the mock data
      mockResponse.write(JSON.stringify data)
      mockResponse.end()

    if mock.response
      endResponse(mock.response)
    else
      readMock(mock.file, endResponse)

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

console.log "Serving local files at " + options.hostname + ":" + options.localport