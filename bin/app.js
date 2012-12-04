#!/usr/bin/env node
(function() {
    var bouncy, defaults, fileServer, fs, http, nodestatic, options, program, readMock, readOptions, staticServer, _u;

    nodestatic = require("node-static");

    program = require("commander");

    _u = require("underscore");

    http = require("http");

    bouncy = require("bouncy");

    fs = require('fs');

    defaults = {
        directory: './',
        host: '127.0.0.1',
        port: 80,
        hostname: 'localhost',
        localport: 3000,
        file: './remote.json',
        mock: true
    };

    program.version("0.0.5").option("-d, --directory [path]", "Path to local static files directory [./]").option("-h, --host [127.0.0.1]", "Host of the remote API [127.0.0.1]").option("-p, --port [80]", "Port of the remote API [80]").option("-n, --hostname [localhost]", "Hostname to serve the files in [localhost]").option("-l, --localport [3000]", "Port of the local server [3000]").option("-m, --mock [true]", "Whether to use the mock rules [true]").option("-f, --file [remote.json]", "Specific configuration file [remote.json]").parse(process.argv);

    options = {};

    _u.extend(options, defaults, _u.pick(program, 'file'));

    readOptions = function(filePath) {
        var fileConfig;
        try {
            fileConfig = JSON.parse(fs.readFileSync(filePath));
            if (fileConfig) {
                return _u.extend(options, fileConfig);
            }
        } catch (e) {
            console.error("No configuration file found!", e);
            return options.file = void 0;
        } finally {
            _u.extend(options, _u.pick(program, 'directory', 'host', 'port', 'hostname', 'localport', 'mock'));
            console.log(options);
        }
    };

    readOptions(options.file);

    if (options.file) {
        fs.watchFile(options.file, {
            persistent: true,
            interval: 1000
        }, function(curr, prev) {
            if (!(curr.size === prev.size && curr.mtime.getTime() === prev.mtime.getTime())) {
                console.log("Config file changed - updating options.");
                return readOptions(options.file);
            }
        });
    }

    options.localBouncePort = options.localport * 1 + 1;

    options.mock = !options.mock || options.mock === 'false' ? false : true;

    fileServer = new nodestatic.Server(options.directory, {
        cache: 0
    });

    staticServer = http.createServer(function(request, response) {
        return request.addListener("end", function() {
            return fileServer.serve(request, response);
        });
    });

    if (options.bounces || options.mocks) {
        staticServer.listen(options.localBouncePort);
        readMock = function(filePath) {
            try {
                return JSON.parse(fs.readFileSync(filePath));
            } catch (e) {
                console.error("No file found!", e);
                return void 0;
            }
        };
        bouncy(function(req, bounce) {
            var bounces, mock, mockJSON, mockResponse, _ref;
            mock = _u.find(options.mocks, function(mock) {
                var matchURL, matchUnless;
                matchURL = new RegExp(mock.url).test(req.url);
                matchUnless = mock.unless ? new RegExp(mock.unless).test(req.url) : false;
                return matchURL && !matchUnless;
            });
            bounces = _u.filter(options.bounces, function(bounce) {
                return new RegExp(bounce).test(req.url);
            });
            if (options.mock && mock) {
                mockJSON = (_ref = mock.response) != null ? _ref : readMock(mock.file);
                console.log('Mocking url: ', req.url, 'Mock response: ', mockJSON);
                mockResponse = bounce.respond();
                return mockResponse.end(JSON.stringify(mockJSON));
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