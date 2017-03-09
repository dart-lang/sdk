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

  class LibraryLoader {

    constructor(name, defaultValue, imports, loader) {
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
        loader._loader = null;
      } else {
        // Load / parse other modules on demand.
        let done = false;
        this._library = new Proxy(library, {
          get: function(o, name) {
            if (!done) {
              done = true;
              loader._loader.apply(null, args);
              loader._loader = null;
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
  let libraries = new Map();
  dart_library.libraries = function() { return libraries.keys(); };
  dart_library.debuggerLibraries = function() {
    var debuggerLibraries = [];
    libraries.forEach(function (value, key, map) {
      debuggerLibraries.push(value.load());
    });
    debuggerLibraries.__proto__ = null;
    return debuggerLibraries;
  };

  function library(name, defaultValue, imports, loader) {
    let result = libraries.get(name);
    if (result) {
      console.warn('Already loaded ' + name);
      return result;
    }
    result = new LibraryLoader(name, defaultValue, imports, loader);
    libraries.set(name, result);
    return result;
  }
  dart_library.library = library;

  function import_(libraryName) {
    let loader = libraries.get(libraryName);
    // TODO(vsm): A user might call this directly from JS (as we do in tests).
    // We may want a different error type.
    if (!loader) throwLibraryError('Library not found: ' + libraryName);
    return loader.load();
  }
  dart_library.import = import_;

  var _currentIsolate = false;

  function start(moduleName, libraryName) {
    if (libraryName == null) libraryName = moduleName;
    let library = import_(moduleName)[libraryName];
    let dart_sdk = import_('dart_sdk');

    if (!_currentIsolate) {
      // This import is only needed for chrome debugging. We should provide an
      // option to compile without it.
      dart_sdk._debugger.registerDevtoolsFormatter();

      // Create isolate.
      _currentIsolate = true;
      dart_sdk._isolate_helper.startRootIsolate(() => {}, []);
    }

    library.main();
  }
  dart_library.start = start;

})(dart_library);
}
