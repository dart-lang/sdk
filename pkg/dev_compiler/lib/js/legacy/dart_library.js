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

  const dartLibraryName = Symbol('dartLibraryName');
  dart_library.dartLibraryName = dartLibraryName;

  const libraryImports = Symbol('libraryImports');
  dart_library.libraryImports = libraryImports;

  // Module support.  This is a simplified module system for Dart.
  // Longer term, we can easily migrate to an existing JS module system:
  // ES6, AMD, RequireJS, ....

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
      args.unshift(this._library);
      this._loader.apply(null, args);
      this._state = LibraryLoader.READY;
      this._library[dartLibraryName] = this._name;
      this._library[libraryImports] = this._imports;
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
    let result = new LibraryLoader(name, defaultValue, imports, loader);
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

  function start(moduleName, libraryName) {
    if (libraryName == null) libraryName = moduleName;
    let library = import_(moduleName)[libraryName];
    let dart_sdk = import_('dart_sdk');
    dart_sdk._isolate_helper.startRootIsolate(library.main, []);
  }
  dart_library.start = start;

  let _bootstrapped = false;
  function bootstrap() {
    if (_bootstrapped) return;
    _bootstrapped = true;

    // Force import of core.
    var dart_sdk = import_('dart_sdk');

    // TODO(vsm): DOM facades?
    // See: https://github.com/dart-lang/dev_compiler/issues/173
    if (typeof NodeList !== "undefined") {
      NodeList.prototype.get = function(i) { return this[i]; };
      NamedNodeMap.prototype.get = function(i) { return this[i]; };
      DOMTokenList.prototype.get = function(i) { return this[i]; };
      HTMLCollection.prototype.get = function(i) { return this[i]; };
      // Expose constructors for DOM types dart:html needs to assume are
      // available on window.
      if (typeof PannerNode == "undefined") {
        let audioContext;
        if (typeof AudioContext == "undefined" &&
            (typeof webkitAudioContext != "undefined")) {
          audioContext = new webkitAudioContext();
        } else {
          audioContext = new AudioContext();
          window.StereoPannerNode =
              audioContext.createStereoPanner().constructor;
        }
        window.PannerNode = audioContext.createPanner().constructor;
      }
      if (typeof AudioSourceNode == "undefined") {
        window.AudioSourceNode = MediaElementAudioSourceNode.constructor;
      }
      if (typeof FontFaceSet == "undefined") {
        window.FontFaceSet = document.fonts.__proto__.constructor;
      }
      if (typeof MemoryInfo == "undefined") {
        if (typeof window.performance.memory != "undefined") {
          window.MemoryInfo = window.performance.memory.constructor;
        }
      }
      if (typeof Geolocation == "undefined") {
        navigator.geolocation.constructor;
      }
      if (typeof Animation == "undefined") {
        let d = document.createElement('div');
        if (typeof d.animate != "undefined") {
          window.Animation = d.animate(d).constructor;
        }
      }
      if (typeof SourceBufferList == "undefined") {
        window.SourceBufferList = new MediaSource().sourceBuffers.constructor;
      }
    }

    // This import is only needed for chrome debugging. We should provide an
    // option to compile without it.
    dart_sdk._debugger.registerDevtoolsFormatter();
  }

})(dart_library);
