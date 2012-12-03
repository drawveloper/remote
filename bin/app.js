#!/usr/bin/env node
(function() {
  var bouncy, defaults, fileConfig, fileServer, http, nodestatic, options, program, staticServer, _u;

  nodestatic = require("node-static");

  program = require("commander");

  _u = require("underscore");

  http = require("http");

  bouncy = require("bouncy");

  defaults = {
    directory: './',
    host: '127.0.0.1',
    port: '80',
    hostname: 'localhost',
    localport: '3000',
    file: './remote.json',
    mock: true
  };

  program.version("0.0.1").option("-d, --directory [path]", "Path to local static files directory [./]").option("-h, --host [127.0.0.1]", "Host of the remote API [127.0.0.1]").option("-p, --port [80]", "Port of the remote API [80]").option("-n, --hostname [localhost]", "Hostname to serve the files in [localhost]").option("-l, --localport [3000]", "Port of the local server [3000]").option("-m, --mock [true]", "Whether to use the mock rules [true]").option("-f, --file [remote.json]", "Specific configuration file [remote.json]").parse(process.argv);

  options = {};

  _u.extend(options, defaults, _u.pick(program, 'file'));

  try {
    fileConfig = require(options.file);
    if (fileConfig) {
      _u.extend(options, fileConfig);
    }
  } catch (e) {
    console.error("No configuration file found!", e);
  }

  _u.extend(options, _u.pick(program, 'directory', 'host', 'port', 'hostname', 'localport', 'mock'));

  options.localBouncePort = options.localport * 1 + 1;

  options.mock = !options.mock || options.mock === 'false' ? false : true;

  console.log(options);

  fileServer = new nodestatic.Server(options.directory, {
    cache: 0
  });

  staticServer = http.createServer(function(request, response) {
    return request.addListener("end", function() {
      return fileServer.serve(request, response);
    });
  });

  if (options.bounces) {
    staticServer.listen(options.localBouncePort);
    bouncy(function(req, bounce) {
      var bounces, mock, mockResponse;
      mock = _u.find(options.mocks, function(mock) {
        return (new RegExp(mock.url).test(req.url)) && !(new RegExp(mock.unless).test(req.url));
      });
      bounces = _u.filter(options.bounces, function(bounce) {
        return new RegExp(bounce).test(req.url);
      });
      if (options.mock && mock) {
        console.log('Mocking url: ', req.url, 'Mock response: ', mock.response);
        mockResponse = bounce.respond();
        return mockResponse.end(JSON.stringify(mock.response));
      } else if ((bounces != null ? bounces.length : void 0) > 0) {
        console.log('Bouncing to remote: ', req.url, ' - Matched bounce rules: ', bounces);
        req.on('error', function(e) {
          console.error('Problem with the bounced request... ', e);
          return req.end();
        });
        return bounce(options.host, options.port);
      } else {
        console.log('Serving static file: ', req.url);
        return bounce(options.localBouncePort);
      }
    }).listen(options.localport, options.hostname);
  } else {
    console.log("Not bouncing!");
    staticServer.listen(options.localport, options.hostname);
  }

  console.log("Serving local files at " + options.hostname + ":" + options.localport);

}).call(this);
