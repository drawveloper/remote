## Remote

**Remote** is a simple CLI tool that enables you to work in local files while consuming an API from a remote server. An easy reverse proxy in Node, if you will.

It starts a local server for your files, *bounces* some requests to this server, and *forwards* the rest to the remote host.
You determine which requests are *bounced* by writing some regex in a small json configuration file.
It also gives you the capability to serve arbitrary files at a given URL with **mappings**, and to set arbitrary request headers.

It aims to solve the dreaded **cross domain request** problem, so you can freely *ajax* like you have a local server-side.

### Install

	npm install -g remote

### Usage

	remote [options]

    Options:

    -h, --help                    output usage information
    -V, --version                 output the version number
    -d, --directory [path]        Path to local static files directory [./]
    -j, --remotehost [127.0.0.1]  Host of the remote API [127.0.0.1]
    -p, --remoteport [80]         Port of the remote API [80]
    -l, --localhost [localhost]   Hostname to serve the files in [localhost]
    -q, --localport [3000]        Port of the local proxy server [3000]
    -b, --bounceport [3001]       Port of the local file server [3001]
    -m, --mapping [false]         Whether to use the mapping rules [false]
    -f, --file [remote.json]      Specific configuration file [remote.json]

After installing, create a `remote.json` configuration file in your folder and simply call `remote`.

Read on for the possible options for your `remote.json` file.

### Bounces

This is the simplest `remote.json`, with some bounce rules defined:

	{
		"directory" : "./src/",
		"remotehost" : "remote-api-host.com",
		"bounces" : [
		    "public/.*",
		    "assets/.*"
		]
	}

In this case, any call to `localhost:3000/public/(...)` or `localhost:3000/assets/(...)`  will be *bounced* to your local files under `./src/`.
Other URL's will be forwarded to `remote-api-host.com`

### Headers

You may wish to send along some headers with your request. For example:

    {
		"directory" : "./src/",
		"remotehost" : "remote-api-host.com",
        "headers": {
            "Host": "remote-api-host.com",
            "X-Secret-Header" : "awesome"
        },
		"bounces" : [
		    "public/.*",
		    "assets/.*"
		]
    }

These will be added to every request made by `remote`.

### Mappings

A mapping is like a bounce rule, only more specific. You define what you want served given a request URL. For example:

    {
		"directory" : "./src/",
		"remotehost" : "remote-api-host.com",
        "headers": {
            "Host": "walmartv5.vtexcommercebeta.com.br",
            "X-Track" : "mkp1"
        },
		"bounces" : [
		    "public/.*",
		    "assets/.*"
		],
        "mapping": true,
        "mappings": {
            ".*/api/users/1/remove": {"result": "ok"},
            ".*/api/users/.*":"./test/mocks/users-mock.json",
            ".*/public/js/awesome.js":"./src/special/path/awesome-2.js"
        }
    }

As you can see, mappings can be:

- A JSON object.
- A path to any file.

When any of these URL's are requested, remote will serve the given resource.

**Note that mappings take precedence over bounce rules!**

You can disable all mappings setting `mapping` to **false**.

### Bounce to remote

If you like to keep things complicated, you may use the `bounceToRemote: true` option in your configuration file.
This will invert the `bounces` rules, so they will actually bounce to the remote API. All other requests will be forwarded to the local server.

### Other notes

Command line options take precedence over `remote.json` options.
Also, any command line option may be specified in the json configuration file.
Have fun!

-----------------

#### Note for Mac OS X users (or: *what to do when I get EMFILE errors*)

OS X has a arbitrarily low limit for the amount of files that a process can open of 256.
Use the `ulimit` command to check your current limit.
For sites with large amounts of files, or in any situation when encountering **EMFILE** errors, simply issue:

    ulimit -n 2048

Or any such large value, before turning on remote.

-----------------

### Changelog:
v 0.1.0:

- Major rewrite. Nothing of note before this ;)
- Using nodejitsu's http-proxy
- Add the capability to map arbitrary url to arbitrary files or JSON
- Add the capability to add request headers