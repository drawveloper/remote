StaticServer = require('./static.coffee')
ProxyServer = require('./proxy.coffee')
RemoteInitializer = require('./init.coffee')

GLOBAL.remote = {}
GLOBAL.remote.log = console.log

module.exports = (options = {}) ->
  new RemoteInitializer(options).initialize()
  new StaticServer(options).start()
  new ProxyServer(options).start()

  GLOBAL.remote.log "Remote -- serving local files at " + options.localhost + ":" + options.localport
