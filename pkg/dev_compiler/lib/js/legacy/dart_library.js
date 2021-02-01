// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// This file defines the module loader for the dart runtime.
var dart_library;
if (!dart_library) {
  dart_library = typeof module != 'undefined' && module.exports || {};

  (function(dart_library) {
    'use strict';

    // Throws an error related to module loading.
    //
    // This does not throw a Dart error because the Dart SDK may not have loaded
    // yet, and module loading errors cannot be caught by Dart code.
    function throwLibraryError(message) {
      // Dispatch event to allow others to react to the load error without
      // capturing the exception.
      if (!!self.dispatchEvent) {
        self.dispatchEvent(
            new CustomEvent('dartLoadException', {detail: message}));
      }
      throw Error(message);
    }

    const libraryImports = Symbol('libraryImports');
    dart_library.libraryImports = libraryImports;

    const _metrics = Symbol('metrics');
    const _logMetrics = false;

    // Returns a map from module name to various metrics for module.
    function metrics() {
      const map = {};
      const keys = Array.from(_libraries.keys());
      for (const key of keys) {
        const lib = _libraries.get(key);
        map[lib._name] = lib._library[_metrics];
      }
      return map;
    }
    dart_library.metrics = metrics;

    function _sortFn(key1, key2) {
      const t1 = _libraries.get(key1)._library[_metrics].loadTime;
      const t2 = _libraries.get(key2)._library[_metrics].loadTime;
      return t1 - t2;
    }

    // Convenience method to print the metrics in the browser console
    // in CSV format.
    function metricsCsv() {
      let buffer =
          'Module, JS Size, Dart Size, Load Time, Cumulative JS Size\n';
      const keys = Array.from(_libraries.keys());
      keys.sort(_sortFn);
      let cumulativeJsSize = 0;
      for (const key of keys) {
        const lib = _libraries.get(key);
        const jsSize = lib._library[_metrics].jsSize;
        cumulativeJsSize += jsSize;
        const dartSize = lib._library[_metrics].dartSize;
        const loadTime = lib._library[_metrics].loadTime;
        buffer += '"' + lib._name + '", ' + jsSize + ', ' + dartSize + ', ' +
            loadTime + ', ' + cumulativeJsSize + '\n';
      }
      return buffer;
    }
    dart_library.metricsCsv = metricsCsv;

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
        let mod = module[loadedModule];
        let lib = mod[name];
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

    // Set of libraries that were not only loaded on the page but also executed.
    let _executedLibraries = new Set();

    class LibraryLoader {
      constructor(name, defaultValue, imports, loader, data) {
        imports.forEach(function(i) {
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
        data.jsSize = loader.toString().length;
        data.loadTime = Infinity;
        this._metrics = data;

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
        _executedLibraries.add(this._name);
        this._state = LibraryLoader.LOADING;

        // Handle imports
        let args = this.loadImports();

        // Load the library
        let loader = this;
        let library = this._library;

        library[libraryImports] = this._imports;
        library[loadedModule] = library;
        library[_metrics] = this._metrics;
        args.unshift(library);

        if (this._name == 'dart_sdk') {
          // Eagerly load the SDK.
          if (!!self.performance) {
            library[_metrics].loadTime = self.performance.now();
          }
          if (_logMetrics) console.time('Load ' + this._name);
          this._loader.apply(null, args);
          if (_logMetrics) console.timeEnd('Load ' + this._name);
        } else {
          // Load / parse other modules on demand.
          let done = false;
          this._library = new Proxy(library, {
            get: function(o, name) {
              if (name == _metrics) {
                return o[name];
              }
              if (!done) {
                done = true;
                if (!!self.performance) {
                  library[_metrics].loadTime = self.performance.now();
                }
                if (_logMetrics) console.time('Load ' + loader._name);
                loader._loader.apply(null, args);
                if (_logMetrics) console.timeEnd('Load ' + loader._name);
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
    dart_library.libraries = function() {
      return _libraries.keys();
    };
    dart_library.debuggerLibraries = function() {
      let debuggerLibraries = [];
      _libraries.forEach(function(value, key, map) {
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

    function library(name, defaultValue, imports, loader, data = {}) {
      let result = _libraries.get(name);
      if (result) {
        console.log('Re-loading ' + name);
        _invalidateLibrary(name);
      }
      result = new LibraryLoader(name, defaultValue, imports, loader, data);
      _libraries.set(name, result);
      return result;
    }
    dart_library.library = library;

    // Store executed modules upon reload.
    if (!!self.addEventListener && !!self.localStorage) {
      self.addEventListener('beforeunload', function(event) {
        let libraryCache = {
          'time': new Date().getTime(),
          'modules': Array.from(_executedLibraries.keys())
        };
        self.localStorage.setItem(
            'dartLibraryCache', JSON.stringify(libraryCache));
      });
    }

    // Map from module name to corresponding proxy library.
    let _proxyLibs = new Map();

    function import_(name) {
      let proxy = _proxyLibs.get(name);
      if (proxy) return proxy;
      let proxyLib = new Proxy({}, {
        get: function(o, p) {
          let lib = _libraries.get(name);
          if (self.$dartJITModules) {
            // The backing module changed so update the reference
            if (!lib) {
              let xhr = new XMLHttpRequest();
              let sourceURL = $dartLoader.moduleIdToUrl.get(name);
              xhr.open('GET', sourceURL, false);
              xhr.withCredentials = true;
              xhr.send();
              // Append sourceUrl so the resource shows up in the Chrome
              // console.
              eval(xhr.responseText + '//@ sourceURL=' + sourceURL);
              lib = _libraries.get(name);
            }
          }
          if (!lib) {
            throwLibraryError('Module ' + name + ' not loaded in the browser.');
          }
          // Always load the library before accessing a property as it may have
          // been invalidated.
          return lib.load()[p];
        }
      });
      _proxyLibs.set(name, proxyLib);
      return proxyLib;
    }
    dart_library.import = import_;

    // Removes the corresponding library and invalidates all things that
    // depend on it.
    function _invalidateImport(name) {
      let lib = _libraries.get(name);
      if (!lib) return;
      _invalidateLibrary(name);
      _libraries.delete(name);
    }
    dart_library.invalidateImport = _invalidateImport;

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
      // TODO(jmesserly): once we've rolled out `clearState` make it the
      // default, and eventually remove the parameter.
      if (clearState == null) clearState = true;


      // TODO(jmesserly): we may want to change these APIs to use the
      // "hot restart" terminology for consistency with Flutter. In Flutter,
      // "hot reload" refers to keeping the application state and attempting to
      // patch the code for the application while it is executing
      // (https://flutter.io/hot-reload/), whereas "hot restart" refers to what
      // dartdevc supports: tear down the app, update the code, and rerun the
      // app.
      if (!self || !self.$dartWarmReload) {
        console.warn('Hot restart not supported in this environment.');
        return;
      }

      // Call the application's `onReloadStart()` function, if provided.
      let result;
      if (_lastLibrary && _lastLibrary.onReloadStart) {
        result = _lastLibrary.onReloadStart();
      }

      let sdk = _libraries.get('dart_sdk');

      /// Once the `onReloadStart()` completes, this finishes the restart.
      function finishHotRestart() {
        self.console.clear();
        if (clearState) {
          // This resets all initialized fields and clears type caches and other
          // temporary data structures used by the compiler/SDK.
          sdk._library.dart.hotRestart();
        }
        // Call the module loader to reload the necessary modules.
        self.$dartWarmReload(() => {
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
          if (!!self.document) {
            // Note: we expect _originalBody to be undefined in non-browser
            // environments, but in that case so is the body.
            if (!_originalBody && !!self.document.body) {
              self.console.warn('No body saved to update on reload');
            } else {
              self.document.body = _originalBody;
            }
          }
        }
      } else {
        // If not a reload then store the initial html to reset it on reload.
        if (!!self.document && !!self.document.body) {
          _originalBody = self.document.body.cloneNode(true);
        }
      }
      library.main([]);
    }
    dart_library.start = start;
  })(dart_library);
}
