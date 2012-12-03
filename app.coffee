nodestatic = require("node-static")
program = require("commander")
_u = require("underscore")
http = require("http")
defaults =
  directory: './'
  host: '127.0.0.1'
  port: '80'
  localport: '3000'
  file: './remote.json'

# Commander options
program.version("0.0.1")
  .option("-d, --directory [path]", "Path to local static files directory [./]", defaults.directory)
  .option("-h, --host [127.0.0.1]", "Host of the remote API [127.0.0.1]", defaults.host)
  .option("-p, --port [80]", "Port of the remote API [80]", defaults.port)
  .option("-lp, --localport [3000]", "Port of the local server [3000]", defaults.localport)
  .option("-f, --file [remote.json]", "Specific configuration file. Ignores others options [remote.json]", defaults.file)
  .parse process.argv

# Program configurations, either set by command line, configuration file or defaults
options = {}
_u.extend options, defaults, _u.pick(program, 'directory', 'host', 'port', 'localport', 'file')

# Read configuration file and override any options with it
fileConfig = require(options.file)
if (fileConfig)
  _u.extend options, fileConfig

console.log options

# Create a node-static server instance to serve the './public' folder
staticServer = new (nodestatic.Server)(options.directory)

# Serve files!
http.createServer((request, response) ->
  request.addListener "end", ->
    staticServer.serve request, response
).listen options.localport

console.log "Serving local files at localhost:" + options.localport