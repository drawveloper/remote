nodestatic = require("node-static")
program = require("commander")
_u = require("underscore")
http = require("http")
bouncy = require("bouncy")
defaults =
  directory: './'
  host: '127.0.0.1'
  port: '80'
  localport: '3000'
  file: './remote.json'

# Commander options
program.version("0.0.1")
  .option("-d, --directory [path]", "Path to local static files directory [./]")
  .option("-h, --host [127.0.0.1]", "Host of the remote API [127.0.0.1]")
  .option("-p, --port [80]", "Port of the remote API [80]")
  .option("-l, --localport [3000]", "Port of the local server [3000]")
  .option("-f, --file [remote.json]", "Specific configuration file [remote.json]")
  .parse process.argv

# Program configurations, either set by command line, configuration file or defaults
options = {}
_u.extend options, defaults, _u.pick(program, 'directory', 'host', 'port', 'localport', 'file')

# Read configuration file and override any options with it
fileConfig = require(options.file)
if (fileConfig)
  _u.extend options, fileConfig

# Override any file options with command line options
_u.extend options, _u.pick(program, 'directory', 'host', 'port', 'localport', 'file')

options.localBouncePort = options.localport*1 + 1

console.log options

# Serve files!
staticServer = http.createServer((request, response) ->
  request.addListener "end", ->
    new (nodestatic.Server)(options.directory, { cache: 0 }).serve request, response
)

# If user defined bounces ( why else would you use this? )
if options.bounces
  # Start serving the files in the local bounce port
  staticServer.listen options.localBouncePort
  bouncy((req, bounce) ->

    rules = _u.filter( options.bounces, (bounce) -> new RegExp(bounce).test req.url )

    if rules?.length > 0
      console.log 'Bouncing to remote: ', req.url, ' - Matched bounce rules: ', rules
      bounce options.host, options.port
    else
      console.log 'Serving static file: ', req.url
      bounce options.localBouncePort

  ).listen options.localport
# else, simply serve the static files.
else
  console.log "Not bouncing!"
  staticServer.listen options.localport

console.log "Serving local files at localhost:" + options.localport