## Remote

**Remote** is a simple tool to work in local files while consuming an API from a remote server. 

It serves your static files locally and *bounces* some requests to an external server. It aims to serve the dreaded **cross domain request** problem, so you can freely *ajax* like you have a local server-side.

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
				"url" : ".*/api/awesomes/",
				"response" : "{'level':'awesome'}"
			}
		]
	}

In this case, any call to `localhost:3000/api/(...)` will be *bounced* to `remote-api-host.com/api/(...)`.
Mocks take precedence over bounces, however. So, exceptionally, a call to `localhost:3000/api/awesomes/` will not be *bounced* and will, instead, return the mock JSON `{'level':'awesome'}`.

Command line options take precedence over `remote.json` options.

Have fun!
