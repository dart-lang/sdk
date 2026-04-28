// Copyright 2020 The Dart Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:io' show Platform;

// Note: this is a copy from flutter tools, updated to work with dwds tests

/// JavaScript snippet to determine the base URL of the current path.
const String _baseUrlScript = '''
var baseUrl = (function () {
  // Attempt to detect --precompiled mode for tests, and set the base url
  // appropriately, otherwise set it to '/'.
  var pathParts = location.pathname.split("/");
  if (pathParts[0] == "") {
    pathParts.shift();
  }
  if (pathParts.length > 1 && pathParts[1] == "test") {
    return "/" + pathParts.slice(0, 2).join("/") + "/";
  }
  // Attempt to detect base url using <base href> html tag
  // base href should start and end with "/"
  if (typeof document !== 'undefined') {
    var el = document.getElementsByTagName('base');
    if (el && el[0] && el[0].getAttribute("href") && el[0].getAttribute
    ("href").startsWith("/") && el[0].getAttribute("href").endsWith("/")){
      return el[0].getAttribute("href");
    }
  }
  // return default value
  return "/";
}());
var _trimmedBaseUrl = baseUrl.endsWith('/') ? baseUrl.substring(0, baseUrl.length - 1) : baseUrl;
var _currentDirectory = window.location.origin + _trimmedBaseUrl;
''';

/// Used to load prerequisite scripts such as ddc_module_loader.js
const String _simpleLoaderScript = r'''
window.$dartCreateScript = (function() {
  // Find the nonce value. (Note, this is only computed once.)
  var scripts = Array.from(document.getElementsByTagName("script"));
  var nonce;
  scripts.some(
      script => (nonce = script.nonce || script.getAttribute("nonce")));
  // If present, return a closure that automatically appends the nonce.
  if (nonce) {
    return function() {
      var script = document.createElement("script");
      script.nonce = nonce;
      return script;
    };
  } else {
    return function() {
      return document.createElement("script");
    };
  }
})();

// Loads a module [relativeUrl] relative to [root].
//
// If not specified, [root] defaults to the directory serving the main app.
var forceLoadModule = function (relativeUrl, root) {
  var actualRoot = root ?? _currentDirectory;
  var trimmedRoot = actualRoot.endsWith('/') ? actualRoot.substring(0, actualRoot.length - 1) : actualRoot;
  return new Promise(function(resolve, reject) {
    var script = self.$dartCreateScript();
    let policy = {
      createScriptURL: function(src) {return src;}
    };
    if (self.trustedTypes && self.trustedTypes.createPolicy) {
      policy = self.trustedTypes.createPolicy('dartDdcModuleUrl', policy);
    }
    script.onload = resolve;
    script.onerror = reject;
    script.src = policy.createScriptURL(trimmedRoot + "/" + relativeUrl);
    document.head.appendChild(script);
  });
};
''';

/// The JavaScript bootstrap script to support in-browser hot restart.
///
/// The [requireUrl] loads our cached RequireJS script file. The [mapperUrl]
/// loads the special Dart stack trace mapper. The [entrypoint] is the
/// actual main.dart file.
///
/// This file is served when the browser requests "main.dart.js" in debug mode,
/// and is responsible for bootstrapping the RequireJS modules and attaching
/// the hot reload hooks.
String generateBootstrapScript({
  required String requireUrl,
  required String mapperUrl,
  required String entrypoint,
}) {
  return '''
"use strict";

// Attach source mapping.
var mapperEl = document.createElement("script");
mapperEl.defer = true;
mapperEl.async = false;
mapperEl.src = "$mapperUrl";
document.head.appendChild(mapperEl);

// Attach require JS.
var requireEl = document.createElement("script");
requireEl.defer = true;
requireEl.async = false;
requireEl.src = "$requireUrl";
// This attribute tells require JS what to load as main (defined below).
requireEl.setAttribute("data-main", "main_module.bootstrap");
document.head.appendChild(requireEl);
''';
}

/// Generate a synthetic main module which captures the application's main
/// method.
///
/// RE: Object.keys usage in app.main:
/// This attaches the main entrypoint and hot reload functionality to the
/// window. The app module will have a single property which contains the
/// actual application code. The property name is based off of the entrypoint
/// that is generated, for example the file `foo/bar/baz.dart` will generate a
/// property named approximately `foo__bar__baz`. Rather than attempt to guess,
/// we assume the first property of this object is the module.
String generateMainModule({required String entrypoint}) {
  return '''/* ENTRYPOINT_EXTENTION_MARKER */

// Create the main module loaded below.
define("main_module.bootstrap", ["$entrypoint", "dart_sdk"], function(app, dart_sdk) {
  dart_sdk._isolate_helper.startRootIsolate(() => {}, []);
  dart_sdk._debugger.registerDevtoolsFormatter();
  let voidToNull = () => (voidToNull = dart_sdk.dart.constFn(dart_sdk.dart.fnType(dart_sdk.core.Null, [dart_sdk.dart.void])))();

  // See the generateMainModule doc comment.
  var child = {};
  child.main = app[Object.keys(app)[0]].main;

  /* MAIN_EXTENSION_MARKER */
  child.main();
});
''';
}

String generateDDCBootstrapScript({
  required String ddcModuleLoaderUrl,
  required String mapperUrl,
  required String entrypoint,
  required String bootstrapUrl,
}) {
  return '''
$_baseUrlScript
$_simpleLoaderScript

(function() {
  let appName = "$entrypoint";

  // A uuid that identifies a subapp.
  let uuid = "00000000-0000-0000-0000-000000000000";

  window.postMessage(
      {type: "DDC_STATE_CHANGE", state: "initial_load", targetUuid: uuid}, "*");

  // Load pre-requisite DDC scripts. We intentionally use invalid names to avoid namespace clashes.
  let prerequisiteScripts = [
    {
      "src": "$ddcModuleLoaderUrl",
      "id": "dart_library \x00"
    },
    {
      "src": "$mapperUrl",
      "id": "dart_stack_trace_mapper \x00"
    }
  ];

  // Load ddc_module_loader.js to access DDC's module loader API.
  let prerequisiteLoads = [];
  for (let i = 0; i < prerequisiteScripts.length; i++) {
    prerequisiteLoads.push(forceLoadModule(prerequisiteScripts[i].src));
  }
  Promise.all(prerequisiteLoads).then((_) => afterPrerequisiteLogic());

  // Save the current script so we can access it in a closure.
  var _currentScript = document.currentScript;

  var afterPrerequisiteLogic = function() {
    window.\$dartLoader.rootDirectories.push(_currentDirectory);
    let scripts = [
      {
        "src": "dart_sdk.js",
        "id": "dart_sdk"
      },
      {
        "src": "$bootstrapUrl",
        "id": "data-main"
      }
    ];
    let loadConfig = new window.\$dartLoader.LoadConfiguration();
    loadConfig.root = _currentDirectory;
    loadConfig.bootstrapScript = scripts[scripts.length - 1];

    if (window.\$dartJITModules) {
      loadConfig.loadScriptFn = function(loader) {
        // Loads just the entrypoint module and required SDK modules.
        let moduleSet = new Set();
        // This cache is populated by ddc_module_loader.js
        let libraryCache = JSON.parse(window.localStorage.getItem(`dartLibraryCache:\${appName}`));
        if (libraryCache) {
          // TODO(b/165021238) - when should this be invalidated?
          moduleSet = new Set(libraryCache["modules"])
        }
        loader.addScriptsToQueue(scripts, function(script) {
            // Preemptively load the ddc module loader and previously executed modules.
            return moduleSet.size == 0
                  || script.id.includes("dart_library")
                  // We preemptively load the stack_trace_mapper module so that we can
                  // translate JS errors to Dart.
                  || script.id.includes("stack_trace_mapper")
                  || moduleSet.has(script.id);
        });
        loader.loadEnqueuedModules();
      }
      loadConfig.ddcEventForLoadStart = /* LOAD_ENTRYPOINT_MODULES_START */ 4;
      loadConfig.ddcEventForLoadedOk = /* LOAD_ENTRYPOINT_MODULES_END_OK */ 5;
      loadConfig.ddcEventForLoadedError = /* LOAD_ENTRYPOINT_MODULES_END_ERROR */ 6;
    } else {
      loadConfig.loadScriptFn = function(loader) {
        loader.addScriptsToQueue(scripts, null);
        loader.loadEnqueuedModules();
      }
      loadConfig.ddcEventForLoadStart = /* LOAD_ALL_MODULES_START */ 1;
      loadConfig.ddcEventForLoadedOk = /* LOAD_ALL_MODULES_END_OK */ 2;
      loadConfig.ddcEventForLoadedError = /* LOAD_ALL_MODULES_END_ERROR */ 3;
    }

    let loader = new window.\$dartLoader.DDCLoader(loadConfig);

    // Record prerequisite scripts' fully resolved URLs.
    prerequisiteScripts.forEach(script => loader.registerScript(script));

    // Note: these variables should only be used in non-multi-app scenarios since
    // they can be arbitrarily overridden based on multi-app load order.
    window.\$dartLoader.loadConfig = loadConfig;
    window.\$dartLoader.loader = loader;
    loader.nextAttempt();

    let currentUri = _currentScript.src;
    let fetchEtagsUri;
    if (currentUri.indexOf("?") == -1) {
      fetchEtagsUri = currentUri + "?fetch-etags=true";
    } else {
      fetchEtagsUri = currentUri + "&fetch-etags=true";
    }

    if (!window.\$dartAppNameToMetadata) {
      window.\$dartAppNameToMetadata = new Map();
    }
    window.\$dartAppNameToMetadata.set(appName, {
        currentDirectory: _currentDirectory,
        currentUri: currentUri,
        fetchEtagsUri: fetchEtagsUri,
    });

    if (!window.\$dartReloadModifiedModules) {
      window.\$dartReloadModifiedModules = (function(appName, callback) {
        function cb() {
          window.postMessage(
              {
                type: "DDC_STATE_CHANGE",
                state: "restart_end",
                targetUuid: uuid,
              },
              "*");
          callback();
        }
        window.postMessage(
            {
              type: "DDC_STATE_CHANGE",
              state: "restart_begin",
              targetUuid: uuid,
            },
            "*");
        var xhttp = new XMLHttpRequest();
        xhttp.withCredentials = true;
        xhttp.onreadystatechange = function() {
          // https://developer.mozilla.org/en-US/docs/Web/API/XMLHttpRequest/readyState
          if (this.readyState == 4 && this.status == 200 || this.status == 304) {
            var scripts = JSON.parse(this.responseText);
            var numToLoad = 0;
            var numLoaded = 0;
            for (var i = 0; i < scripts.length; i++) {
              var script = scripts[i];
              if (script.id == null) continue;
              var src =
                  window.\$dartAppNameToMetadata.get(appName).currentDirectory +
                  script.src.toString();
              var oldSrc = window.\$dartLoader.moduleIdToUrl.get(script.id);
              // Only compare the search parameters which contain the cache
              // busting portion of the uri. The path might be different if the
              // script is loaded from a different application on the page.
              if (new URL(oldSrc).search == new URL(src).search) continue;

              // We might actually load from a different uri, delete the old one
              // just to be sure.
              window.\$dartLoader.urlToModuleId.delete(oldSrc);

              window.\$dartLoader.moduleIdToUrl.set(script.id, src);
              window.\$dartLoader.urlToModuleId.set(src, script.id);

              if (window.\$dartJITModules) {
              // Simply invalidate the import and the corresponding module will
              // be lazily loaded.
              dart_library.invalidateImport(script.id);
              continue;
              } else {
                numToLoad++;
              }

              var el = document.getElementById(script.id);
              if (el) el.remove();
              el = window.\$dartCreateScript();
              el.src = policy.createScriptURL(src);
              el.async = false;
              el.defer = true;
              el.id = script.id;
              el.onload = function() {
                numLoaded++;
                if (numToLoad == numLoaded) cb();
              };
              document.head.appendChild(el);
            }
            // Call `cb` right away if we found no updated scripts.
            if (numToLoad == 0) cb();
          }
        };
        xhttp.open("GET",
          window.\$dartAppNameToMetadata.get(appName).fetchEtagsUri, true);
        let sdk = dart_library.import("dart_sdk", appName);
        let developer = sdk.developer;
        if (developer._extensions.containsKey("ext.flutter.disassemble")) {
          developer.invokeExtension("ext.flutter.disassemble", "{}").then(() => {
            // TODO(b/204210914): we should really be clearing all statics for all
            // apps, but for now we just do it for flutter apps which we recognize
            // based on this extension.
            sdk.dart.hotRestart();
            xhttp.send();
          });
        } else {
          xhttp.send();
        }
      });
    }
  }
})();
''';
}

String generateDDCMainModule({
  required String entrypoint,
  String? exportedMain,
}) {
  final exportedMainName = exportedMain ?? entrypoint.split('.')[0];
  return '''/* ENTRYPOINT_EXTENTION_MARKER */

(function() {
  let appName = "$entrypoint";

  // A uuid that identifies a subapp.
  let uuid = "00000000-0000-0000-0000-000000000000";

  let dart_sdk = dart_library.import('dart_sdk', appName);

  dart_sdk._debugger.registerDevtoolsFormatter();
  dart_sdk._isolate_helper.startRootIsolate(() => {}, []);

  let child = {};
  child.main = function() {
    dart_library.start(appName, uuid, "$entrypoint", "$exportedMainName");
  }

  /* MAIN_EXTENSION_MARKER */
  child.main();
})();
''';
}

String generateDDCLibraryBundleBootstrapScript({
  required String ddcModuleLoaderUrl,
  required String mapperUrl,
  required String entrypoint,
  required String bootstrapUrl,
}) {
  return '''
$_baseUrlScript
$_simpleLoaderScript

(function() {
  let appName = "org-dartlang-app:/$entrypoint";

  // Load pre-requisite DDC scripts. We intentionally use invalid names to avoid
  // namespace clashes.
  let prerequisiteScripts = [
    {
      "src": "$ddcModuleLoaderUrl",
      "id": "ddc_module_loader \x00"
    },
    {
      "src": "$mapperUrl",
      "id": "dart_stack_trace_mapper \x00"
    }
  ];

  // Load ddc_module_loader.js to access DDC's module loader API.
  let prerequisiteLoads = [];
  for (let i = 0; i < prerequisiteScripts.length; i++) {
    prerequisiteLoads.push(forceLoadModule(prerequisiteScripts[i].src));
  }
  Promise.all(prerequisiteLoads).then((_) => afterPrerequisiteLogic());

  // Save the current script so we can access it in a closure.
  var _currentScript = document.currentScript;

  // Create a policy if needed to load the files during a hot restart.
  let policy = {
    createScriptURL: function(src) {return src;}
  };
  if (self.trustedTypes && self.trustedTypes.createPolicy) {
    policy = self.trustedTypes.createPolicy('dartDdcModuleUrl', policy);
  }

  var afterPrerequisiteLogic = function() {
    window.\$dartLoader.rootDirectories.push(_currentDirectory);
    let scripts = [
      {
        "src": "dart_sdk.js",
        "id": "dart_sdk"
      },
      {
        "src": "$bootstrapUrl",
        "id": "data-main"
      }
    ];

    let loadConfig = new window.\$dartLoader.LoadConfiguration();
    loadConfig.root = _currentDirectory;

    // TODO(srujzs): Verify this is sufficient for Windows.
    loadConfig.isWindows = ${Platform.isWindows};
    loadConfig.bootstrapScript = scripts[scripts.length - 1];

    loadConfig.loadScriptFn = function(loader) {
      loader.addScriptsToQueue(scripts, null);
      loader.loadEnqueuedModules();
    }
    loadConfig.ddcEventForLoadStart = /* LOAD_ALL_MODULES_START */ 1;
    loadConfig.ddcEventForLoadedOk = /* LOAD_ALL_MODULES_END_OK */ 2;
    loadConfig.ddcEventForLoadedError = /* LOAD_ALL_MODULES_END_ERROR */ 3;

    let loader = new window.\$dartLoader.DDCLoader(loadConfig);

    // Record prerequisite scripts' fully resolved URLs.
    prerequisiteScripts.forEach(script => loader.registerScript(script));

    // Note: these variables should only be used in non-multi-app scenarios
    // since they can be arbitrarily overridden based on multi-app load order.
    window.\$dartLoader.loadConfig = loadConfig;
    window.\$dartLoader.loader = loader;

    // Begin loading libraries
    loader.nextAttempt();

    // Set up stack trace mapper.
    if (window.\$dartStackTraceUtility &&
        !window.\$dartStackTraceUtility.ready) {
      window.\$dartStackTraceUtility.ready = true;
      window.\$dartStackTraceUtility.setSourceMapProvider(function(url) {
        var baseUrl = window.location.protocol + '//' + window.location.host;
        url = url.replace(baseUrl + '/', '');
        if (url == 'dart_sdk.js') {
          return dartDevEmbedder.debugger.getSourceMap('dart_sdk');
        }
        url = url.replace(".lib.js", "").replace(".ddc.js", "");
        return dartDevEmbedder.debugger.getSourceMap(url);
      });
    }

    let currentUri = _currentScript.src;
    // We should have written a file containing all the scripts that need to be
    // reloaded into the page. This is then read when a hot restart is triggered
    // in DDC via the `\$dartReloadModifiedModules` callback.
    // TODO(srujzs): We should avoid using a callback here in the bootstrap once
    // the embedder supports passing a list of files/libraries to `hotRestart`
    // instead. Currently, we're forced to read this file twice.
    let reloadedSources = _currentDirectory + '/reloaded_sources.json';

    if (!window.\$dartReloadModifiedModules) {
      window.\$dartReloadModifiedModules = (function(appName, callback) {
        var xhttp = new XMLHttpRequest();
        xhttp.withCredentials = true;
        xhttp.onreadystatechange = function() {
          // https://developer.mozilla.org/en-US/docs/Web/API/XMLHttpRequest/readyState
          if (this.readyState == 4 && this.status == 200 || this.status == 304) {
            var scripts = JSON.parse(this.responseText);
            var numToLoad = 0;
            var numLoaded = 0;
            for (var i = 0; i < scripts.length; i++) {
              var script = scripts[i];
              var module = script.module;
              if (module == null) continue;
              var src = script.src;
              var oldSrc = window.\$dartLoader.moduleIdToUrl.get(module);

              // We might actually load from a different uri, delete the old one
              // just to be sure.
              window.\$dartLoader.urlToModuleId.delete(oldSrc);

              window.\$dartLoader.moduleIdToUrl.set(module, src);
              window.\$dartLoader.urlToModuleId.set(src, module);

              numToLoad++;

              var el = document.getElementById(module);
              if (el) el.remove();
              el = window.\$dartCreateScript();
              el.src = policy.createScriptURL(src);
              el.async = false;
              el.defer = true;
              el.id = module;
              el.onload = function() {
                numLoaded++;
                if (numToLoad == numLoaded) callback();
              };
              document.head.appendChild(el);
            }
            // Call `callback` right away if we found no updated scripts.
            if (numToLoad == 0) callback();
          }
        };
        xhttp.open("GET", reloadedSources, true);
        xhttp.send();
      });
    }
  };
})();
''';
}

const String _onLoadEndCallback = r'$onLoadEndCallback';

String generateDDCLibraryBundleMainModule({
  required String entrypoint,
  required String onLoadEndBootstrap,
}) {
  // The typo below in "EXTENTION" is load-bearing, package:build depends on it.
  return '''
/* ENTRYPOINT_EXTENTION_MARKER */

(function() {
  let appName = "org-dartlang-app:///$entrypoint";

  dartDevEmbedder.debugger.registerDevtoolsFormatter();

  // Set up a final script that lets us know when all scripts have been loaded.
  // Only then can we call the main method.
  let onLoadEndSrc = '$onLoadEndBootstrap';
  window.\$dartLoader.loadConfig.bootstrapScript = {
    src: onLoadEndSrc,
    id: onLoadEndSrc,
  };
  window.\$dartLoader.loadConfig.tryLoadBootstrapScript = true;
  // Should be called by $onLoadEndBootstrap once all the scripts have been
  // loaded.
  window.$_onLoadEndCallback = function() {
    let child = {};
    child.main = function() {
      dartDevEmbedder.runMain(appName, {});
    }
    /* MAIN_EXTENSION_MARKER */
    child.main();
  }
})();
''';
}

String generateDDCLibraryBundleOnLoadEndBootstrap() {
  return '''window.$_onLoadEndCallback();''';
}
