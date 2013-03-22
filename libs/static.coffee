http = require("http")
send = require("send")
url = require("url")

class StaticServer
  staticServer: null
  constructor: (@options) ->
    # Serve static files
    @staticServer = http.createServer( (req, res) =>
      error = (err) ->
        res.statusCode = err.status || 500
        console.error(err.message)
        res.end(err.message)

      redirect = ->
        res.statusCode = 301
        res.setHeader('Location', req.url + '/')
        res.end('Redirecting to ' + req.url + '/')

      send(req, url.parse(req.url).pathname)
        .root(@options.directory)
        .on('error', error)
        .on('directory', redirect)
        .pipe(res)
    )

  start: =>
    return unless @options.directory
    # Start serving the files in the local bounce port
    @staticServer.listen @options.server.port, @options.server.host
    console.log "Remote -- serving folder", @options.directory, "at " + @options.server.host + ":" + @options.server.port
    return @staticServer

module.exports = StaticServer