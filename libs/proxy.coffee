_u = require("underscore")
bouncy = require("bouncy")
fs = require('fs')
class ProxyServer
  constructor: (@options) ->

  # Utility function to read mock from file
  readFile: (filePath, callback) =>
    try
      fs.readFile(filePath, (err, data) ->
        if err then callback(err) else callback(JSON.parse data)
      )
    catch e
      console.error "No file found!", e
      callback(e)

  findMapping: (url) =>
    if @options.mapping is false
      return undefined

    for key, value of @options.mappings
      return value if (new RegExp(key).test(url))

    return undefined

  findBounce: (url) =>
    if @options.bounces is undefined or @options.bounces.length is 0
      return undefined

    for bounce of @options.bounces
      return bounce if (new RegExp(bounce).test(url))

    return undefined

  applyHeaders: (res) =>

  # Handler to end this response with a mock
  serveMapping: (data, res) ->
    res.write(JSON.stringify data)
    res.end()

  start: =>
    # Bounce requests
    bouncy((req, res, bounce) =>
      req.on('error', (e) ->
        console.error('Problem with the bounced request... ', e)
        req.end()
      )

      # Test if this request fits a mapping
      mappingPath = @findMapping(req.url)

      # Test what bounce rule this request fits first
      matchedBounce = @findBounce(req.url)

      bounceOption = if @options.bounceToRemote then 'remote' else 'local'
      defaultOption = if @options.bounceToRemote then 'local' else 'remote'

      bounceHost = @options[bounceOption + 'host']
      bouncePort = @options[bounceOption + 'port']
      defaultHost = @options[defaultOption + 'host']
      defaultPort = @options[defaultOption + 'port']

      @applyHeaders(res)

      if mappingPath
        @serveMapping()
      else if matchedBounce
        console.log 'Bouncing to remote host: ', req.url, ' - Matched bounce rule: ', matchedBounce
        bounce bounceHost, bouncePort
      else
        console.log 'Bouncing to default option: ', req.url
        bounce defaultHost, defaultPort

    ).listen @options.localport, @options.hostname


module.exports = ProxyServer