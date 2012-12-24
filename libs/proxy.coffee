_u = require("underscore")
bouncy = require("bouncy")
fs = require('fs')
class ProxyServer
  constructor: (@options) ->

  # Utility function to read mock from file
  readMock: (filePath, callback) =>
    try
      fs.readFile(filePath, (err, data) ->
        if err then callback(err) else callback(JSON.parse data)
      )
    catch e
      console.error "No file found!", e
      callback(e)

  start: =>
    # Bounce requests
    bouncy((req, res, bounce) =>
      # Test if this request fits a mock (and *doesnt* fit its "unless" regex)
      mock = _u.find( @options.mocks, (mock) ->
        matchURL = (new RegExp(mock.url).test req.url)
        matchUnless = if mock.unless then (new RegExp(mock.unless).test req.url) else false
        return matchURL and not matchUnless
      ) if @options.mocks

      # Test which bounce rules this request fits
      bounces = _u.filter( @options.bounces,
      (bounce) -> (new RegExp(bounce).test req.url ) ) if @options.bounces

      if @options.mock and mock
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
          @readMock(mock.file, endResponse)

      else if @options.bounces and bounces?.length > 0
        console.log 'Bouncing to remote: ', req.url, ' - Matched bounce rules: ', bounces
        req.on('error', (e) ->
          console.error('Problem with the bounced request... ', e)
          req.end()
        )
        bounce @options.host, @options.port
      else
        console.log 'Serving static file: ', req.url
        bounce @options.localBouncePort

    ).listen @options.localport, @options.hostname


module.exports = ProxyServer