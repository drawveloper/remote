_u = require("underscore")
fs = require('fs')
path = require('path')
httpProxy = require('http-proxy')

class ProxyServer
  constructor: (@options) ->

  # Utility function to read mapping, either directly as JSON or from a file
  readMapping: (mapping) =>
    try
      # If it's a string, treat as a path.
      if _u.isString(mapping)
        pathMapping = path.resolve(process.cwd(), mapping)
        return fs.readFileSync(pathMapping, 'utf8')
      # Otherwise, treat it as an object and return JSON.
      else
        return JSON.stringify(mapping)
    catch e
      console.error "Error reading mapping", mapping, e

  findMapping: (url) =>
    if @options.mapping is false
      return undefined

    for key, value of @options.mappings
      return value if (new RegExp(key).test(url))

    return undefined

  findBounce: (url) =>
    if @options.bounces is undefined or @options.bounces.length is 0
      return undefined

    for bounce in @options.bounces
      return bounce if (new RegExp(bounce).test(url))

    return undefined

  start: =>
    httpProxy.createServer( (req, res, proxy) =>
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

      # Add user headers and overwrite any present headers, if necessary.
      for key, value of @options.headers
        req.headers[key] = value

      if mappingTarget
        console.log 'Mapping request: ', req.url, '- to file -', mappingTarget
        res.end(@readMapping(mappingTarget))
      else if matchedBounce
        console.log 'Bouncing request: ', bounceHost, bouncePort, req.url, ' - Matched bounce rule: ', matchedBounce
        proxy.proxyRequest(req, res, { host: bounceHost, port: bouncePort })
      else
        console.log 'Forwarding request: ', defaultHost, defaultPort, req.url
        proxy.proxyRequest(req, res, { host: defaultHost, port: defaultPort })

    ).listen(@options.localport, @options.localhost)

module.exports = ProxyServer
