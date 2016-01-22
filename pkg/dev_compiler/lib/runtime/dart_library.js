// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/* This file defines the module loader for the dart runtime.
*/

var dart_library =
  typeof module != "undefined" && module.exports || {};

(function (dart_library) {
  'use strict';

  /** Note that we cannot use dart_utils.throwInternalError from here. */
  function throwLibraryError(message) {
    throw Error(message);
  }

  // Module support.  This is a simplified module system for Dart.
  // Longer term, we can easily migrate to an existing JS module system:
  // ES6, AMD, RequireJS, ....

  class LibraryLoader {
    constructor(name, defaultValue, imports, lazyImports, loader) {
      this._name = name;
      this._library = defaultValue ? defaultValue : {};
      this._imports = imports;
      this._lazyImports = lazyImports;
      this._loader = loader;

      // Cyclic import detection
      this._state = LibraryLoader.NOT_LOADED;
    }

    loadImports(pendingSet) {
      return this.handleImports(this._imports, (lib) => lib.load(pendingSet));
    }

    deferLazyImports(pendingSet) {
      return this.handleImports(this._lazyImports,
        (lib) => {
          pendingSet.add(lib._name);
          return lib.stub();
      });
    }

    loadLazyImports(pendingSet) {
      return this.handleImports(pendingSet, (lib) => lib.load());
    }

    handleImports(list, handler) {
      let results = [];
      for (let name of list) {
        let lib = libraries.get(name);
        if (!lib) {
          throwLibraryError('Library not available: ' + name);
        }
        results.push(handler(lib));
      }
      return results;
    }

    load(inheritedPendingSet) {
      // Check for cycles
      if (this._state == LibraryLoader.LOADING) {
        throwLibraryError('Circular dependence on library: '
                              + this._name);
      } else if (this._state >= LibraryLoader.LOADED) {
        return this._library;
      }
      this._state = LibraryLoader.LOADING;

      // Handle imports and record lazy imports
      let pendingSet = inheritedPendingSet ? inheritedPendingSet : new Set();
      let args = this.loadImports(pendingSet);
      args = args.concat(this.deferLazyImports(pendingSet));

      // Load the library
      args.unshift(this._library);
      this._loader.apply(null, args);
      this._state = LibraryLoader.LOADED;

      // Handle lazy imports
      if (inheritedPendingSet === void 0) {
        // Drain the queue
        this.loadLazyImports(pendingSet);
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
  LibraryLoader.LOADED = 2;
  LibraryLoader.READY = 3;

  // Map from name to LibraryLoader
  let libraries = new Map();
  dart_library.libraries = function() { return libraries.keys(); }

  function library(name, defaultValue, imports, lazyImports, loader) {
    let result = new LibraryLoader(name, defaultValue, imports, lazyImports, loader);
    libraries.set(name, result);
    return result;
  }
  dart_library.library = library;

  function import_(libraryName) {
    bootstrap();
    let loader = libraries.get(libraryName);
    // TODO(vsm): A user might call this directly from JS (as we do in tests).
    // We may want a different error type.
    if (!loader) throwLibraryError('Library not found: ' + libraryName);
    return loader.load();
  }
  dart_library.import = import_;

  function start(libraryName) {
    let library = import_(libraryName);
    let _isolate_helper = import_('dart/_isolate_helper');
    _isolate_helper.startRootIsolate(library.main, []);
  }
  dart_library.start = start;

  let _bootstrapped = false;
  function bootstrap() {
    if (_bootstrapped) return;
    _bootstrapped = true;

    // Force import of core.
    var core = import_('dart/core');
    core.Object.toString = function() {
      // Interface types are represented by the corresponding constructor
      // function.  This ensures that Dart interface types print properly.
      return this.name;
    }

    // TODO(vsm): DOM facades?
    // See: https://github.com/dart-lang/dev_compiler/issues/173
    if (typeof NodeList !== "undefined") {
      NodeList.prototype.get = function(i) { return this[i]; };
      NamedNodeMap.prototype.get = function(i) { return this[i]; };
      DOMTokenList.prototype.get = function(i) { return this[i]; };
      HTMLCollection.prototype.get = function(i) { return this[i]; };
    }

    // This import is only needed for chrome debugging. We should provide an
    // option to compile without it.
    var devtoolsDebugger = import_('dart/_debugger');
    devtoolsDebugger.registerDevtoolsFormatter();
  }

})(dart_library);
