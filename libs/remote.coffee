send = require("send")
url = require("url")
_u = require("underscore")
http = require("http")
bouncy = require("bouncy")
fs = require('fs')
coffee = require('coffee-script')
StaticServer = require('./static.coffee')
ProxyServer = require('./proxy.coffee')
RemoteInitializer = require('./init.coffee')

options = {}

new RemoteInitializer(options).initialize()

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