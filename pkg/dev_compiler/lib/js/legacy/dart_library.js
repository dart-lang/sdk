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

    // Returns a map from module name to various metrics for module.
    function moduleMetrics() {
      const map = {};
      const keys = Array.from(_libraries.keys());
      for (const key of keys) {
        const lib = _libraries.get(key);
        map[lib._name] = lib.firstLibraryValue[_metrics];
      }
      return map;
    }
    dart_library.moduleMetrics = moduleMetrics;

    // Returns an application level overview of the module metrics.
    function appMetrics() {
      const metrics = moduleMetrics();
      let dartSize = 0;
      let jsSize = 0;
      let sourceMapSize = 0;
      let evaluatedModules = 0;
      const keys = Array.from(_libraries.keys());

      let firstLoadStart = Number.MAX_VALUE;
      let lastLoadEnd = Number.MIN_VALUE;

      for (const module of keys) {
        let data = metrics[module];
        if (data != null) {
          evaluatedModules++;
          dartSize += data.dartSize;
          jsSize += data.jsSize;
          sourceMapSize += data.sourceMapSize;
          firstLoadStart = Math.min(firstLoadStart, data.loadStart);
          lastLoadEnd = Math.max(lastLoadEnd, data.loadEnd);
        }
      }
      return {
        'dartSize': dartSize,
        'jsSize': jsSize,
        'sourceMapSize': sourceMapSize,
        'evaluatedModules': evaluatedModules,
        'loadTimeMs': lastLoadEnd - firstLoadStart
      };
    }
    dart_library.appMetrics = appMetrics;

    function _sortFn(key1, key2) {
      const t1 = _libraries.get(key1).firstLibraryValue[_metrics].loadStart;
      const t2 = _libraries.get(key2).firstLibraryValue[_metrics].loadStart;
      return t1 - t2;
    }

    // Convenience method to print the metrics in the browser console
    // in CSV format.
    function metricsCsv() {
      let buffer =
          'Module, JS Size, Dart Size, Load Start, Load End, Cumulative JS Size\n';
      const keys = Array.from(_libraries.keys());
      keys.sort(_sortFn);
      let cumulativeJsSize = 0;
      for (const key of keys) {
        const lib = _libraries.get(key);
        const jsSize = lib.firstLibraryValue[_metrics].jsSize;
        cumulativeJsSize += jsSize;
        const dartSize = lib.firstLibraryValue[_metrics].dartSize;
        const loadStart = lib.firstLibraryValue[_metrics].loadStart;
        const loadEnd = lib.firstLibraryValue[_metrics].loadEnd;
        buffer += '"' + lib._name + '", ' + jsSize + ', ' + dartSize + ', ' +
            loadStart + ', ' + loadEnd + ', ' + cumulativeJsSize + '\n';
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

    // App name to set of libraries that were not only loaded on the page but
    // also executed.
    const _executedLibraries = new Map();
    dart_library.executedLibraryCount = function() {
      let count = 0;
      _executedLibraries.forEach(function(executedLibraries, _) {
        count += executedLibraries.size;
      });
      return count;
    };

    // Library instance that is going to be loaded or has been loaded.
    class LibraryInstance {
      constructor(libraryValue) {
        this.libraryValue = libraryValue;
        // Cyclic import detection
        this.loadingState = LibraryLoader.NOT_LOADED;
      }

      get isNotLoaded() {
        return this.loadingState == LibraryLoader.NOT_LOADED;
      }
    }

    class LibraryLoader {
      constructor(name, defaultLibraryValue, imports, loader, data) {
        imports.forEach(function(i) {
          let deps = _reverseImports.get(i);
          if (!deps) {
            deps = new Set();
            _reverseImports.set(i, deps);
          }
          deps.add(name);
        });
        this._name = name;
        this._defaultLibraryValue =
            defaultLibraryValue ? defaultLibraryValue : {};
        this._imports = imports;
        this._loader = loader;
        data.jsSize = loader.toString().length;
        data.loadStart = NaN;
        data.loadEnd = NaN;
        this._metrics = data;

        // First loaded instance for supporting logic that assumes there is only
        // one app.
        // TODO(b/204209941): Remove _firstLibraryInstance after debugger and
        // metrics support multiple apps.
        this._firstLibraryInstance =
            new LibraryInstance(this._deepCopyDefaultValue());
        this._firstLibraryInstanceUsed = false;

        // App name to instance map.
        this._instanceMap = new Map();
      }

      /// First loaded value for supporting logic that assumes there is only
      /// one app.
      get firstLibraryValue() {
        return this._firstLibraryInstance.libraryValue;
      }

      /// The loaded instance value for the given `appName`.
      libraryValueInApp(appName) {
        return this._instanceMap.get(appName).libraryValue;
      }

      load(appName) {
        let instance = this._instanceMap.get(appName);
        if (!instance && !this._firstLibraryInstanceUsed) {
          // If `_firstLibraryInstance` is already assigned to an app, creates a
          // new instance clone (with deep copy) and assigns it the given app.
          // Otherwise, reuse `_firstLibraryInstance`.
          instance = this._firstLibraryInstance;
          this._firstLibraryInstanceUsed = true;
          this._instanceMap.set(appName, instance);
        }
        if (!instance) {
          instance = new LibraryInstance(this._deepCopyDefaultValue());
          this._instanceMap.set(appName, instance);
        }

        // Check for cycles
        if (instance.loadingState == LibraryLoader.LOADING) {
          throwLibraryError('Circular dependence on library: ' + this._name);
        } else if (instance.loadingState >= LibraryLoader.READY) {
          return instance.libraryValue;
        }
        if (!_executedLibraries.has(appName)) {
          _executedLibraries.set(appName, new Set());
        }
        _executedLibraries.get(appName).add(this._name);
        instance.loadingState = LibraryLoader.LOADING;

        // Handle imports
        let args = this._loadImports(appName);

        // Load the library
        let loader = this;
        let library = instance.libraryValue;

        library[libraryImports] = this._imports;
        library[loadedModule] = library;
        library[_metrics] = this._metrics;
        args.unshift(library);

        if (this._name == 'dart_sdk') {
          // Eagerly load the SDK.
          if (!!self.performance && !!self.performance.now) {
            library[_metrics].loadStart = self.performance.now();
          }
          this._loader.apply(null, args);
          if (!!self.performance && !!self.performance.now) {
            library[_metrics].loadEnd = self.performance.now();
          }
        } else {
          // Load / parse other modules on demand.
          let done = false;
          instance.libraryValue = new Proxy(library, {
            get: function(o, name) {
              if (name == _metrics) {
                return o[name];
              }
              if (!done) {
                done = true;
                if (!!self.performance && !!self.performance.now) {
                  library[_metrics].loadStart = self.performance.now();
                }
                loader._loader.apply(null, args);
                if (!!self.performance && !!self.performance.now) {
                  library[_metrics].loadEnd = self.performance.now();
                }
              }
              return o[name];
            }
          });
        }

        instance.loadingState = LibraryLoader.READY;
        return instance.libraryValue;
      }

      _loadImports(appName) {
        let results = [];
        for (let name of this._imports) {
          results.push(import_(name, appName));
        }
        return results;
      }

      _deepCopyDefaultValue() {
        return JSON.parse(JSON.stringify(this._defaultLibraryValue));
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
        debuggerLibraries.push(value.load(_firstStartedAppName));
      });
      debuggerLibraries.__proto__ = null;
      return debuggerLibraries;
    };

    // Invalidate a library and all things that depend on it
    function _invalidateLibrary(name) {
      let lib = _libraries.get(name);
      if (lib._instanceMap.size === 0) return;
      lib._firstLibraryInstance =
          new LibraryInstance(lib._deepCopyDefaultValue());
      lib._firstLibraryInstanceUsed = false;
      lib._instanceMap.clear();
      let deps = _reverseImports.get(name);
      if (!deps) return;
      deps.forEach(_invalidateLibrary);
    }

    function library(name, defaultLibraryValue, imports, loader, data = {}) {
      let result = _libraries.get(name);
      if (result) {
        console.log('Re-loading ' + name);
        _invalidateLibrary(name);
      }
      result =
          new LibraryLoader(name, defaultLibraryValue, imports, loader, data);
      _libraries.set(name, result);
      return result;
    }
    dart_library.library = library;

    // Store executed modules upon reload.
    if (!!self.addEventListener && !!self.localStorage) {
      self.addEventListener('beforeunload', function(event) {
        _nameToApp.forEach(function(_, appName) {
          if (!_executedLibraries.get(appName)) {
            return;
          }
          let libraryCache = {
            'time': new Date().getTime(),
            'modules': Array.from(_executedLibraries.get(appName).keys()),
          };
          self.localStorage.setItem(
              `dartLibraryCache:${appName}`, JSON.stringify(libraryCache));
        });
      });
    }

    // Map from module name to corresponding app to proxy library map.
    let _proxyLibs = new Map();

    function import_(name, appName) {
      // For backward compatibility.
      if (!appName && _lastStartedSubapp) {
        appName = _lastStartedSubapp.appName;
      }

      let proxy;
      if (_proxyLibs.has(name)) {
        proxy = _proxyLibs.get(name).get(appName);
      }
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
              // Add inline policy to make eval() call Trusted Types compatible
              // when running in a TT compatible browser
              let policy = {
                createScript: function(script) {
                  return script;
                }
              };
              if (self.trustedTypes && self.trustedTypes.createPolicy) {
                policy = self.trustedTypes.createPolicy(
                    'dartDdcModuleLoading#dart_library', policy);
              }
              // Append sourceUrl so the resource shows up in the Chrome
              // console.
              eval(policy.createScript(
                  xhr.responseText + '//@ sourceURL=' + sourceURL));
              lib = _libraries.get(name);
            }
          }
          if (!lib) {
            throwLibraryError('Module ' + name + ' not loaded in the browser.');
          }
          // Always load the library before accessing a property as it may have
          // been invalidated.
          return lib.load(appName)[p];
        }
      });
      if (!_proxyLibs.has(name)) {
        _proxyLibs.set(name, new Map());
      }
      _proxyLibs.get(name).set(appName, proxyLib);
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

    // Caches the last N runIds to prevent hot reload requests from the same
    // runId from executing more than once.
    const _hotRestartRunIdCache = new Array();

    // Called to initiate a hot restart of the application for a given uuid. If
    // it is not set, the last started application will be hot restarted.
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
    // 4. Call `self.$dartReloadModifiedModules()` (provided by the HTML page)
    //    to reload the relevant JS modules, passing a callback that will invoke
    //    `main()`.
    // 5. `$dartReloadModifiedModules` calls the callback to rerun main.
    //
    async function hotRestart(config) {
      if (!self || !self.$dartReloadModifiedModules) {
        console.warn('Hot restart not supported in this environment.');
        return;
      }

      // If `config.runId` is set (e.g. a unique build ID that represent the
      // current build and shared by multiple subapps), skip the following runs
      // with the same id.
      if (config && config.runId) {
        if (_hotRestartRunIdCache.indexOf(config.runId) >= 0) {
          // The run has already started (by other subapp or app)
          return;
        }
        _hotRestartRunIdCache.push(config.runId);

        // Only cache the runIds for the last N runs. We assume that there are
        // less than N requests with different runId can happen in a very short
        // period of time (e.g. 1 second).
        if (_hotRestartRunIdCache.length > 10) {
          _hotRestartRunIdCache.shift();
        }
      }

      self.console.clear();
      const sdk = _libraries.get('dart_sdk');

      // Finds out what apps and their subapps should be hot restarted in
      // their starting order.
      const dirtyAppNames = new Array();
      const dirtySubapps = new Array();
      if (config && config.runId) {
        _nameToApp.forEach(function(app, appName) {
          dirtySubapps.push(...app.uuidToSubapp.values());
          dirtyAppNames.push(appName);
        });
      } else {
        dirtySubapps.push(_lastStartedSubapp);
        dirtyAppNames.push(_lastStartedSubapp.appName);
      }

      // Invokes onReloadStart for each subapp in reversed starting order.
      const onReloadStartPromises = new Array();
      for (const subapp of dirtySubapps.reverse()) {
        // Call the application's `onReloadStart()` function, if provided.
        if (subapp.library && subapp.library.onReloadStart) {
          const result = subapp.library.onReloadStart();
          if (result && result.then) {
            let resolve;
            onReloadStartPromises.push(new Promise(function(res, _) {
              resolve = res;
            }));
            const dart = sdk.libraryValueInApp(subapp.appName).dart;
            result.then(dart.dynamic, function() {
              resolve();
            });
          }
        }
      }
      // Reverse the subapps back to starting order.
      dirtySubapps.reverse();

      await Promise.all(onReloadStartPromises);

      // Invokes SDK `hotRestart` to reset all initialized fields and clears
      // type caches and other temporary data structures used by the
      // compiler/SDK.
      for (const appName of dirtyAppNames) {
        sdk.libraryValueInApp(appName).dart.hotRestart();
      }

      // Starts the subapps in their starting order.
      for (const subapp of dirtySubapps) {
        // Call the module loader to reload the necessary modules.
        self.$dartReloadModifiedModules(subapp.appName, function() {
          // Once the modules are loaded, rerun `main()`.
          start(
              subapp.appName, subapp.uuid, subapp.moduleName,
              subapp.libraryName, true);
        });
      }
    }
    dart_library.reload = hotRestart;

    /// An App contains one or multiple Subapps, all of the subapps share the
    /// same memory copy of library instances, and as a result they share state
    /// in Dart statics and top-level fields. There can be one or multiple Apps
    /// in a browser window, all of the Apps are isolated from each other
    /// (i.e. they create different instances even for the same module).
    class App {
      constructor(name) {
        this.name = name;

        // Subapp's uuid to subapps in initial starting order.
        // (ES6 preserves iteration order)
        this.uuidToSubapp = new Map();
      }
    }

    class Subapp {
      constructor(uuid, appName, moduleName, libraryName, library) {
        this.uuid = uuid;
        this.appName = appName;
        this.moduleName = moduleName;
        this.libraryName = libraryName;
        this.library = library;

        this.originalBody = null;
      }
    }

    // App name to App map in initial starting order.
    // (ES6 preserves iteration order)
    const _nameToApp = new Map();
    let _firstStartedAppName;
    let _lastStartedSubapp;

    /// Starts a subapp that is identified with `uuid`, `moduleName`, and
    /// `libraryName` inside a parent app that is identified by `appName`.
    function start(appName, uuid, moduleName, libraryName, isReload) {
      console.info(
          `DDC: Subapp Module [${appName}:${moduleName}:${uuid}] is starting`);
      if (libraryName == null) libraryName = moduleName;
      const library = import_(moduleName, appName)[libraryName];

      let app = _nameToApp.get(appName);
      if (!isReload) {
        if (!app) {
          app = new App(appName);
          _nameToApp.set(appName, app);
        }

        let subapp = app.uuidToSubapp.get(uuid);
        if (!subapp) {
          subapp = new Subapp(uuid, appName, moduleName, libraryName, library);
          app.uuidToSubapp.set(uuid, subapp);
        }

        _lastStartedSubapp = subapp;
        if (!_firstStartedAppName) {
          _firstStartedAppName = appName;
        }
      }

      const subapp = app.uuidToSubapp.get(uuid);
      const sdk = import_('dart_sdk', appName);

      if (!_debuggerInitialized) {
        // This import is only needed for chrome debugging. We should provide an
        // option to compile without it.
        sdk._debugger.registerDevtoolsFormatter();

        // Create isolate.
        _debuggerInitialized = true;
      }
      if (isReload) {
        // subapp may have been modified during reload, `subapp.library` needs
        // to always point to the latest data.
        subapp.library = library;

        if (library.onReloadEnd) {
          library.onReloadEnd();
          return;
        } else {
          if (!!self.document) {
            // Note: we expect originalBody to be undefined in non-browser
            // environments, but in that case so is the body.
            if (!subapp.originalBody && !!self.document.body) {
              self.console.warn('No body saved to update on reload');
            } else {
              self.document.body = subapp.originalBody;
            }
          }
        }
      } else {
        // If not a reload and `onReloadEnd` is not defined, store the initial
        // html to reset it on reload.
        if (!library.onReloadEnd && !!self.document && !!self.document.body) {
          subapp.originalBody = self.document.body.cloneNode(true);
        }
      }
      library.main([]);
    }
    dart_library.start = start;
  })(dart_library);
}
