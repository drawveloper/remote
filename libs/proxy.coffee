_u = require("underscore")
bouncy = require("bouncy")
fs = require('fs')
path = require('path')

class ProxyServer
  constructor: (@options) ->

  # Utility function to read mock from file
  readMapping: (mapping) =>
    try
      return JSON.parse(mapping)
    # Not a JSON string, treat as a path
    catch e
      try
        pathMapping = path.resolve(process.cwd(), mapping)
        return fs.readFileSync(pathMapping, 'utf8')
      catch e2
        console.error "Error reading mapping", mapping, e2

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
  serveMapping: (res, data) ->

  start: =>
    # Bounce requests
    bouncy((req, res, bounce) =>
      req.on('error', (e) ->
        console.error('Problem with the bounced request... ', e)
        req.end()
      )

      # Test if this request fits a mapping
      mappingTarget = @findMapping(req.url)

      # Test what bounce rule this request fits first
      matchedBounce = @findBounce(req.url)

      # Bounce matching requests to this host:port
      bounceHost = if @options.bounceToRemote then @options.remotehost else @options.localhost
      bouncePort = if @options.bounceToRemote then @options.remoteport else @options.bounceport
      # All other requests
      defaultHost = if @options.bounceToRemote then @options.localhost else @options.remotehost
      defaultPort = if @options.bounceToRemote then @options.bounceport else @options.remoteport

      @applyHeaders(res)

      if mappingTarget
        res.end(@readMapping(mappingTarget))
      else if matchedBounce
        console.log 'Bouncing request: ', req.url, ' - Matched bounce rule: ', matchedBounce
        bounce bounceHost, bouncePort
      else
        console.log 'Forwarding request: ', req.url
        bounce defaultHost, defaultPort

    ).listen @options.localport, @options.hostname


module.exports = ProxyServer