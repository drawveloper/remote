## Remote

**Remote** is a simple tool to work in local files while consuming an API from a remote server. An easy reverse proxy in Node, if you will.

It serves your static files locally and *bounces* some requests to an external server. It aims to solve the dreaded **cross domain request** problem, so you can freely *ajax* like you have a local server-side.

You determine which requests are *bounced* by writing some regex in a small json configuration file. 

### Install

	npm install -g remote

### Usage

	remote [options]

	Options:

    -h, --help                  output usage information
    -V, --version               output the version number
    -d, --directory [path]      Path to local static files directory [./]
    -h, --host [127.0.0.1]      Host of the remote API [127.0.0.1]
    -p, --port [80]             Port of the remote API [80]
    -n, --hostname [localhost]  Hostname to serve the files in [localhost]
    -l, --localport [3000]      Port of the local server [3000]
    -m, --mock [true]           Whether to use the mock rules [true]
    -f, --file [remote.json]    Specific configuration file [remote.json]

Sample `remote.json` config file:

	{
		"directory" : "./src/",
		"host" : "remote-api-host.com",
		"bounces" : [
		    ".*/api/.*",
		    ".*/pub/.*"
		],
		"mocks" : [
			{	
				"url" : ".*/api/awesomes/.*",
				"unless" : ".*/api/awesomes/not",
				"response" : {"level":"awesome"},
				"file" : "./awesome-mock.json"
			}
		]
	}

In this case, any call to `localhost:3000/api/(...)` will be *bounced* to `remote-api-host.com/api/(...)`.

Mocks take precedence over bounces, however. so, exceptionally, a call to `localhost:3000/api/awesomes/` will not be *bounced* and will, instead, return the mock JSON `{'level':'awesome'}`.

You can define an `unless` property in the mock to prevent some specific *URLs* from being matched by a too-generic regex rule. In this case, a call to `localhost:3000/api/awesomes/not` **will not** be responded with the mock data. (And will rather be bounced, because it matches a *bounce* rule)

If you wouldn't like to define an inline mock, you may use a `file` attribute with the path to a json file containing the mock, instead of `response`. If both are defined, `response` takes precedence.

Command line options take precedence over `remote.json` options.

Have fun!
