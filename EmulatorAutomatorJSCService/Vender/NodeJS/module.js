// Copyright Joyent, Inc. and other Node contributors.
//
// Permission is hereby granted, free of charge, to any person obtaining a
// copy of this software and associated documentation files (the
// "Software"), to deal in the Software without restriction, including
// without limitation the rights to use, copy, modify, merge, publish,
// distribute, sublicense, and/or sell copies of the Software, and to permit
// persons to whom the Software is furnished to do so, subject to the
// following conditions:
//
// The above copyright notice and this permission notice shall be included
// in all copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS
// OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
// MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN
// NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM,
// DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR
// OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE
// USE OR OTHER DEALINGS IN THE SOFTWARE.

'use strict';

var runInThisContext = vm.runInThisContext;
var runInNewContext = vm.runInNewContext;

var global = {};

function Module(id, parent) {
    this.id = id;
    this.exports = {};
    this.parent = parent;
    if (parent && parent.children) {
        parent.children.push(this);
    }
    
    this.filename = null;
    this.loaded = false;
    this.children = [];
}
// module.exports = Module;

Module._contextLoad = true

Module._cache = {};
// Module._pathCache = {};
Module._extensions = {};
var modulePaths = [];
// Module.globalPaths = [];

Module.wrapper = NativeModule.wrapper;
Module.wrap = NativeModule.wrap;


Module._debug = util.debuglog;

// We use this alias for the preprocessor that filters it out
var debug = Module._debug;

// Check the cache for the requested file.
// 1. If a module already exists in the cache: return its exports object.
// 2. If the module is native: call `NativeModule.require()` with the
//    filename and return the result.
// 3. Otherwise, create a new module for the file and save it to the cache.
//    Then have it load  the file contents before returning its exports
//    object.
Module._load = function(request, parent, isMain) {
    if (parent) {
        debug('Module._load REQUEST  ' + (request) + ' parent: ' + parent.id);
    }
    
    var filename = Module._resolveFilename(request);
    if (!filename) {
        var err = new Error("Cannot find module '" + request + "'");
        err.code = 'MODULE_NOT_FOUND';
        throw err;
    }
    
    var cachedModule = Module._cache[filename];
    if (cachedModule) {
        debug('Module._load use cachedModule: ' + filename);
        return cachedModule.exports;
    }
    
    debug('Module._load create new module ' + filename);
    var module = new Module(filename, parent);
    
    if (isMain) {
        module.id = '.';
    }
    
    Module._cache[filename] = module;
    
    var hadException = true;
    
    try {
        module.load(filename);
        hadException = false;
    } finally {
        if (hadException) {
            delete Module._cache[filename];
        }
    }
    
    return module.exports;
};

Module._resolveFilename = function(request, parent) { 
    var filename = './' + request + '.js'
    var resolved = NativeModule.resolve(filename)
    if (!resolved) {
        var err = new Error("Cannot find module '" + request + "'");
        err.code = 'MODULE_NOT_FOUND';
        throw err;
    }
    return filename;
};


// Given a file name, pass it to the proper extension handler.
Module.prototype.load = function(filename) {
    debug('Module.prototype.load load ' + JSON.stringify(filename) +
          ' for module ' + JSON.stringify(this.id));
    
    assert(!this.loaded, 'Module.prototype.load module should not loaded');
    this.filename = filename;
    // this.paths = Module._nodeModulePaths(path.dirname(filename));
    
    var extension = '.js';
    //if (!Module._extensions[extension]) extension = '.js';
    Module._extensions[extension](this, filename);
    this.loaded = true;
};


// Loads a module at the given file path. Returns that module's
// `exports` property.
Module.prototype.require = function(path) {
    assert(path, 'missing path');
    return Module._load(path, this);
};

// Run the file contents in the correct scope or sandbox. Expose
// the correct helper variables (require, module, exports) to
// the file.
// Returns exception, if any.
Module.prototype._compile = function(content, filename) {
    var self = this;
    // remove shebang
    content = content.replace(/^\#\!.*/, '');
    
    function require(path) {
        return self.require(path);
    }
    
    require.resolve = function(request) {
        return Module._resolveFilename(request, self);
    };
    
    Object.defineProperty(require, 'paths', { get: function() {
        throw new Error('require.paths is removed. Use ' +
                        'node_modules folders, or the NODE_PATH ' +
                        'environment variable instead.');
    }});
        
    // Enable support to add extra extension types
    require.extensions = Module._extensions;
    require.registerExtension = function() {
        throw new Error('require.registerExtension() removed. Use ' +
                        'require.extensions instead.');
    };
    
    require.cache = Module._cache;
    
    var dirname = NativeModule.dirname(filename);
    
    // create wrapper function
    var wrapper = Module.wrap(content);
    
    var compiledWrapper = runInThisContext(wrapper, { filename: filename });
    debug('Module.prototype._compile compiledWrapper: ' + compiledWrapper);

    var args = [self.exports, require, self, filename, dirname];
    debug('Module.prototype._compile compiledWrapper.apply(self.exports, args)');
    return compiledWrapper.apply(self.exports, args);
};

function stripBOM(content) {
    // Remove byte order marker. This catches EF BB BF (the UTF-8 BOM)
    // because the buffer-to-string conversion in `fs.readFileSync()`
    // translates it to FEFF, the UTF-16 BOM.
    if (content.charCodeAt(0) === 0xFEFF) {
        content = content.slice(1);
    }
    return content;
}

// Native extension for .js
Module._extensions['.js'] = function(module, filename) {
    var content = NativeModule.readFileSync(filename);
    module._compile(stripBOM(content), filename);
};

// bootstrap main module.
Module.runMain = function(request) {
    debug('Module.runMain: ' + request);
    // Load the main module--the command line argument.
    Module._load(request, null, true);
};
