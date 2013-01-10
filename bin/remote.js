#!/usr/bin/env node
(function() {
    require('coffee-script');
    // Call the main function
    require('../libs/remote.coffee')({cli:true});
}).call(this);