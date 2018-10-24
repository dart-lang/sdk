// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// This file defines the module loader for the dart runtime.
var dart_library;
if (!dart_library) {
  dart_library = typeof module != "undefined" && module.exports || {};

(function (dart_library) {
  'use strict';

  // Throws an error related to module loading.
  //
  // This does not throw a Dart error because the Dart SDK may not have loaded
  // yet, and module loading errors cannot be caught by Dart code.
  function throwLibraryError(message) {
    // Dispatch event to allow others to react to the load error without
    // capturing the exception.
    window.dispatchEvent(
      new CustomEvent('dartLoadException', { detail: message }));
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
  dart_library.defer = function (module, name, patch) {
    let done = false;
    function loadDeferred() {
      done = true;
      let mod = module[loadedModule];
      let lib = mod[name];
      // Install unproxied module and library in caller's context.
      patch(mod, lib);
    }
    // The deferred library object.  Note, the only legal operations on a Dart
    // library object should be get (to read a top-level variable, method, or
    // Class) or set (to write a top-level variable).
    return new Proxy({}, {
      get: function (o, p) {
        if (!done) loadDeferred();
        return module[name][p];
      },
      set: function (o, p, value) {
        if (!done) loadDeferred();
        module[name][p] = value;
        return true;
      },
    });
  };

  let _reverseImports = new Map();
  class LibraryLoader {

    constructor(name, defaultValue, imports, loader) {
      imports.forEach(function (i) {
        let deps = _reverseImports.get(i);
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
        results.push(import_(name));
      }
      return results;
    }

    load() {
      // Check for cycles
      if (this._state == LibraryLoader.LOADING) {
        throwLibraryError('Circular dependence on library: ' + this._name);
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
          get: function (o, name) {
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
  dart_library.libraries = function () { return _libraries.keys(); };
  dart_library.debuggerLibraries = function () {
    let debuggerLibraries = [];
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
  }
  dart_library.import = import_;

  let _debuggerInitialized = false;

  // Called to initiate a hot restart of the application.
  //
  // "Hot restart" means all application state is cleared, the newly compiled
  // modules are loaded, and `main()` is called.
  //
  // Note: `onReloadEnd()` can be provided, and if so will be used instead of
  // `main()` for hot restart.
  //
  // This happens in the following sequence:
  //
  // 1. Look for `onReloadStart()` in the same library that has `main()`, and
  //    call it if present. This function is implemented by the application to
  //    ensure any global browser/DOM state is cleared, so the application can
  //    restart.
  // 2. Wait for `onReloadStart()` to complete (either synchronously, or async
  //    if it returned a `Future`).
  // 3. Call dart:_runtime's `hotRestart()` function to clear any state that
  //    `dartdevc` is tracking, such as initialized static fields and type
  //    caches.
  // 4. Call `window.$dartWarmReload()` (provided by the HTML page) to reload
  //    the relevant JS modules, passing a callback that will invoke `main()`.
  // 5. `$dartWarmReload` calls the callback to rerun main.
  //
  function reload(clearState) {
    // TODO(jmesserly): once we've rolled out `clearState` make it the default,
    // and eventually remove the parameter.
    if (clearState == null) clearState = false;


    // TODO(jmesserly): we may want to change these APIs to use the
    // "hot restart" terminology for consistency with Flutter. In Flutter,
    // "hot reload" refers to keeping the application state and attempting to
    // patch the code for the application while it is executing
    // (https://flutter.io/hot-reload/), whereas "hot restart" refers to what
    // dartdevc supports: tear down the app, update the code, and rerun the app.
    if (!window || !window.$dartWarmReload) {
      console.warn('Hot restart not supported in this environment.');
      return;
    }

    // Call the application's `onReloadStart()` function, if provided.
    let result;
    if (_lastLibrary && _lastLibrary.onReloadStart) {
      result = _lastLibrary.onReloadStart();
    }

    let sdk = _libraries.get("dart_sdk");

    /// Once the `onReloadStart()` completes, this finishes the restart.
    function finishHotRestart() {
      if (clearState) {
        // This resets all initialized fields and clears type caches and other
        // temporary data structures used by the compiler/SDK.
        sdk.dart.hotRestart();
      }
      // Call the module loader to reload the necessary modules.
      window.$dartWarmReload(() => {
        // Once the modules are loaded, rerun `main()`.
        start(_lastModuleName, _lastLibraryName, true);
      });
    }

    if (result && result.then) {
      result.then(sdk._library.dart.Dynamic)(finishHotRestart);
    } else {
      finishHotRestart();
    }
  }
  dart_library.reload = reload;


  let _lastModuleName;
  let _lastLibraryName;
  let _lastLibrary;
  let _originalBody;

  function start(moduleName, libraryName, isReload) {
    if (libraryName == null) libraryName = moduleName;
    _lastModuleName = moduleName;
    _lastLibraryName = libraryName;
    let library = import_(moduleName)[libraryName];
    _lastLibrary = library;
    let dart_sdk = import_('dart_sdk');

    if (!_debuggerInitialized) {
      // This import is only needed for chrome debugging. We should provide an
      // option to compile without it.
      dart_sdk._debugger.registerDevtoolsFormatter();

      // Create isolate.
      _debuggerInitialized = true;
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
