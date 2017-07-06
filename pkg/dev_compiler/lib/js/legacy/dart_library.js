// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/* This file defines the module loader for the dart runtime.
*/
var dart_library;
if (!dart_library) {
dart_library =
  typeof module != "undefined" && module.exports || {};

(function (dart_library) {
  'use strict';

  /** Note that we cannot use dart_utils.throwInternalError from here. */
  function throwLibraryError(message) {
    throw Error(message);
  }

  const libraryImports = Symbol('libraryImports');
  dart_library.libraryImports = libraryImports;

  // Module support.  This is a simplified module system for Dart.
  // Longer term, we can easily migrate to an existing JS module system:
  // ES6, AMD, RequireJS, ....

  // Returns a proxy that delegates to the underlying loader.
  // This defers loading of a module until a library is actually used.
  const loadedModule = Symbol('loadedModule');
  dart_library.defer = function(module, name, patch) {
    let done = false;
    function loadDeferred() {
      done = true;
      var mod = module[loadedModule];
      var lib = mod[name];
      // Install unproxied module and library in caller's context.
      patch(mod, lib);
    }
    // The deferred library object.  Note, the only legal operations on a Dart
    // library object should be get (to read a top-level variable, method, or
    // Class) or set (to write a top-level variable).
    return new Proxy({}, {
      get: function(o, p) {
        if (!done) loadDeferred();
        return module[name][p];
      },
      set: function(o, p, value) {
        if (!done) loadDeferred();
        module[name][p] = value;
        return true;
      },
    });
  };

  let _reverseImports = new Map();
  class LibraryLoader {

    constructor(name, defaultValue, imports, loader) {
      imports.forEach(function(i) {
        var deps = _reverseImports.get(i);
        if (!deps) {
          deps = new Set();
          _reverseImports.set(i, deps);
        }
        deps.add(name);
      });
      this._name = name;
      this._library = defaultValue ? defaultValue : {};
      this._imports = imports;
      this._loader = loader;

      // Cyclic import detection
      this._state = LibraryLoader.NOT_LOADED;
    }

    loadImports() {
      let results = [];
      for (let name of this._imports) {
        let lib = libraries.get(name);
        if (!lib) {
          throwLibraryError('Library not available: ' + name);
        }
        results.push(lib.load());
      }
      return results;
    }

    load() {
      // Check for cycles
      if (this._state == LibraryLoader.LOADING) {
        throwLibraryError('Circular dependence on library: '
                              + this._name);
      } else if (this._state >= LibraryLoader.READY) {
        return this._library;
      }
      this._state = LibraryLoader.LOADING;

      // Handle imports
      let args = this.loadImports();

      // Load the library
      let loader = this;
      let library = this._library;

      library[libraryImports] = this._imports;
      library[loadedModule] = library;
      args.unshift(library);

      if (this._name == 'dart_sdk') {
        // Eagerly load the SDK.
        this._loader.apply(null, args);
      } else {
        // Load / parse other modules on demand.
        let done = false;
        this._library = new Proxy(library, {
          get: function(o, name) {
            if (!done) {
              done = true;
              loader._loader.apply(null, args);
            }
            return o[name];
          }
        });
      }

      this._state = LibraryLoader.READY;
      return this._library;
    }

    stub() {
      return this._library;
    }
  }
  LibraryLoader.NOT_LOADED = 0;
  LibraryLoader.LOADING = 1;
  LibraryLoader.READY = 2;

  // Map from name to LibraryLoader
  let _libraries = new Map();
  dart_library.libraries = function() { return libraries.keys(); };
  dart_library.debuggerLibraries = function() {
    var debuggerLibraries = [];
    _libraries.forEach(function (value, key, map) {
      debuggerLibraries.push(value.load());
    });
    debuggerLibraries.__proto__ = null;
    return debuggerLibraries;
  };

  // Invalidate a library and all things that depend on it
  function _invalidateLibrary(name) {
    let lib = _libraries.get(name);
    if (lib._state == LibraryLoader.NOT_LOADED) return;
    lib._state = LibraryLoader.NOT_LOADED;
    lib._library = {};
    let deps = _reverseImports.get(name);
    if (!deps) return;
    deps.forEach(_invalidateLibrary);
  }

  function library(name, defaultValue, imports, loader) {
    let result = _libraries.get(name);
    if (result) {
      console.log('Re-loading ' + name);
      _invalidateLibrary(name);
    }
    result = new LibraryLoader(name, defaultValue, imports, loader);
    _libraries.set(name, result);
    return result;
  }
  dart_library.library = library;

<<<<<<< HEAD
  function import_(libraryName) {
    let loader = libraries.get(libraryName);
    // TODO(vsm): A user might call this directly from JS (as we do in tests).
    // We may want a different error type.
    if (!loader) throwLibraryError('Library not found: ' + libraryName);
    return loader.load();
=======
  // Maintain a stack of active imports.  If a requested library/module is not
  // available, print the stack to show where/how it was requested.
  let _stack = [];
  function import_(name) {
    let lib = _libraries.get(name);
    if (!lib) {
      let message = 'Module ' + name + ' not loaded in the browser.';
      if (_stack != []) {
        message += '\nDependency via:';
        let indent = '';
        for (let last = _stack.length - 1; last >= 0; last--) {
          indent += ' ';
          message += '\n' + indent + '- ' + _stack[last];
        }
      }
      throwLibraryError(message);
    }
    _stack.push(name);
    let result = lib.load();
    _stack.pop();
    return result;
>>>>>>> origin/master
  }
  dart_library.import = import_;

  var _currentIsolate = false;

  function _restart() {
    start(_lastModuleName, _lastLibraryName, true);
  }

  function reload() {
    if (!window || !window.$dartWarmReload) {
      console.warn('Warm reload not supported in this environment.');
      return;
    }
    var result;
    if (_lastLibrary && _lastLibrary.onReloadStart) {
      result = _lastLibrary.onReloadStart();
    }
    if (result && result.then) {
      let sdk = _libraries.get("dart_sdk");
      result.then(sdk._library.dart.Dynamic)(function() {
        window.$dartWarmReload(_restart);
      });
    } else {
      window.$dartWarmReload(_restart);
    }
  }
  dart_library.reload = reload;


  var _lastModuleName;
  var _lastLibraryName;
  var _lastLibrary;
  var _originalBody;

  function start(moduleName, libraryName, isReload) {
    if (libraryName == null) libraryName = moduleName;
    _lastModuleName = moduleName;
    _lastLibraryName = libraryName;
    let library = import_(moduleName)[libraryName];
    _lastLibrary = library;
    let dart_sdk = import_('dart_sdk');

    if (!_currentIsolate) {
      // This import is only needed for chrome debugging. We should provide an
      // option to compile without it.
      dart_sdk._debugger.registerDevtoolsFormatter();

      // Create isolate.
      _currentIsolate = true;
      dart_sdk._isolate_helper.startRootIsolate(() => {}, []);
    }
    if (isReload) {
      if (library.onReloadEnd) {
        library.onReloadEnd();
        return;
      } else {
        document.body = _originalBody;
      }
    } else {
      // If not a reload then store the initial html to reset it on reload.
      _originalBody = document.body.cloneNode(true);
    }
    library.main();
  }
  dart_library.start = start;

})(dart_library);
}
