#!/usr/bin/env node
(function() {
    var bouncy, defaults, fs, http, options, program, readMock, readOptions, send, staticServer, url, _u;

    send = require("send");

    url = require("url");

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

    program.version("0.0.7").option("-d, --directory [path]", "Path to local static files directory [./]").option("-j, --host [127.0.0.1]", "Host of the remote API [127.0.0.1]").option("-p, --port [80]", "Port of the remote API [80]").option("-n, --hostname [localhost]", "Hostname to serve the files in [localhost]").option("-l, --localport [3000]", "Port of the local server [3000]").option("-m, --mock [true]", "Whether to use the mock rules [true]").option("-f, --file [remote.json]", "Specific configuration file [remote.json]").parse(process.argv);

    options = {};

    _u.extend(options, defaults, _u.pick(program, 'file'));

    readOptions = function(filePath) {
        var fileConfig;
        options.bounces = options.mocks = void 0;
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

    staticServer = http.createServer(function(req, res) {
        var error, redirect;
        error = function(err) {
            res.statusCode = err.status || 500;
            console.error(err.message);
            return res.end(err.message);
        };
        redirect = function() {
            res.statusCode = 301;
            res.setHeader('Location', req.url + '/');
            return res.end('Redirecting to ' + req.url + '/');
        };
        return send(req, url.parse(req.url).pathname).root(options.directory).on('error', error).on('directory', redirect).pipe(res);
    });

    staticServer.listen(options.localBouncePort);

    readMock = function(filePath, callback) {
        try {
            return fs.readFile(filePath, function(err, data) {
                if (err) {
                    return callback(err);
                } else {
                    return callback(JSON.parse(data));
                }
            });
        } catch (e) {
            console.error("No file found!", e);
            return callback(e);
        }
    };

    bouncy(function(req, bounce) {
        var bounces, endResponse, mock;
        if (options.mocks) {
            mock = _u.find(options.mocks, function(mock) {
                var matchURL, matchUnless;
                matchURL = new RegExp(mock.url).test(req.url);
                matchUnless = mock.unless ? new RegExp(mock.unless).test(req.url) : false;
                return matchURL && !matchUnless;
            });
        }
        if (options.bounces) {
            bounces = _u.filter(options.bounces, function(bounce) {
                return new RegExp(bounce).test(req.url);
            });
        }
        if (options.mock && mock) {
            endResponse = function(data) {
                var mockResponse;
                console.log('Mocking url: ', req.url, 'Mock response: ', data);
                mockResponse = bounce.respond();
                mockResponse.write(JSON.stringify(data));
                return mockResponse.end();
            };
            if (mock.response) {
                return endResponse(mock.response);
            } else {
                return readMock(mock.file, endResponse);
            }
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

    console.log("Serving local files at " + options.hostname + ":" + options.localport);

}).call(this);