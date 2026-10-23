// Copyright (c) 2026, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:io' show Platform;

/// Used to load prerequisite scripts such as ddc_module_loader.js
const _simpleLoaderScript = r'''
window.$dartCreateScript = (function() {
  // Find the nonce value. (Note, this is only computed once.)
  const scripts = Array.from(document.getElementsByTagName("script"));
  let nonce;
  scripts.some(
      script => (nonce = script.nonce || script.getAttribute("nonce")));
  // If present, return a closure that automatically appends the nonce.
  if (nonce) {
    return function() {
      const script = document.createElement("script");
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
const forceLoadModule = function (relativeUrl, root) {
  const actualRoot = root ?? _currentDirectory;
  return new Promise(function(resolve, reject) {
    const script = self.$dartCreateScript();
    let policy = {
      createScriptURL: function(src) {return src;}
    };
    if (self.trustedTypes && self.trustedTypes.createPolicy) {
      policy = self.trustedTypes.createPolicy('dartDdcModuleUrl', policy);
    }
    script.onload = resolve;
    script.onerror = reject;
    script.src = policy.createScriptURL(actualRoot + relativeUrl);
    document.head.appendChild(script);
  });
};
''';

/// The JavaScript bootstrap script to support in-browser hot restart/reload.
///
/// The [ddcModuleLoaderUrl] defines the custom module loader.
/// The [mapperUrl] loads the special Dart stack trace mapper.
/// The [sdkUrl] points to DDC's Dart SDK.
/// The [mainModuleUrl] points to the script that's called to start a DDC app.
///
/// URLs are relative to the directory serving this script.
String generateDdcLibraryBundleBootstrapScript({
  required String ddcModuleLoaderUrl,
  required String mapperUrl,
  required String sdkUrl,
  required String mainModuleUrl,
}) =>
    '''
// Save the current directory so we can access it in a closure.
const _currentDirectory = (function () {
  const _url = document.currentScript.src;
  const lastSlash = _url.lastIndexOf('/');
  if (lastSlash == -1) return _url;
  const currentDirectory = _url.substring(0, lastSlash + 1);
  return currentDirectory;
})();

$_simpleLoaderScript

(function() {
  // Load pre-requisite DDC scripts. We intentionally use invalid names to avoid
  // namespace clashes.
  let prerequisiteScripts = [
    {
      "src": "$ddcModuleLoaderUrl",
      "id": "ddc_module_loader \\x00"
    },
    {
      "src": "$mapperUrl",
      "id": "dart_stack_trace_mapper \\x00"
    }
  ];

  // Load ddc_module_loader.js to access DDC's module loader API.
  let prerequisiteLoads = [];
  for (let i = 0; i < prerequisiteScripts.length; i++) {
    prerequisiteLoads.push(forceLoadModule(prerequisiteScripts[i].src));
  }
  Promise.all(prerequisiteLoads).then((_) => afterPrerequisiteLogic());

  // Create a policy if needed to load the files during a hot restart.
  let policy = {
    createScriptURL: function(src) {return src;}
  };
  if (self.trustedTypes && self.trustedTypes.createPolicy) {
    policy = self.trustedTypes.createPolicy('dartDdcModuleUrl', policy);
  }

  const afterPrerequisiteLogic = function() {
    window.\$dartLoader.rootDirectories.push(_currentDirectory);
    let scripts = [
      {
        "src": "$sdkUrl",
        "id": "dart_sdk"
      },
      {
        "src": "$mainModuleUrl",
        "id": "data-main"
      }
    ];

    let loadConfig = new window.\$dartLoader.LoadConfiguration();
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
        const baseUrl = window.location.protocol + '//' + window.location.host;
        url = url.replace(baseUrl + '/', '');
        if (url == '$sdkUrl') {
          return dartDevEmbedder.debugger.getSourceMap('dart_sdk');
        }
        url = url.replace(".lib.js", "");
        return dartDevEmbedder.debugger.getSourceMap(url);
      });
    }

    if (!window.\$dartReloadModifiedModules) {
      window.\$dartReloadModifiedModules = (function(filesToReload, appName) {
        return new Promise(function(resolve) {
          function callback() {
            resolve(filesToReload);
          }
          let numToLoad = 0;
          let numLoaded = 0;
          for (let i = 0; i < filesToReload.length; i++) {
            const file = filesToReload[i];
            const module = file.module;
            if (module == null) continue;
            const src = file.src;
            const oldSrc = window.\$dartLoader.moduleIdToUrl.get(module);

            // We might actually load from a different uri, delete the old one
            // just to be sure.
            window.\$dartLoader.urlToModuleId.delete(oldSrc);

            window.\$dartLoader.moduleIdToUrl.set(module, src);
            window.\$dartLoader.urlToModuleId.set(src, module);

            numToLoad++;

            let el = document.getElementById(module);
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
        });
      });
    }
  };
})();
''';

/// Generate a synthetic main module which captures the application's main
/// method defined in the filename [entrypoint] (such as
/// org-dartlang-app:///web/main.dart).
///
/// The [onLoadEndBootstrap] names the script file to be loaded last which will
/// trigger the callback to start the application.
String generateDdcLibraryBundleMainModule({
  required String entrypoint,
  required String onLoadEndBootstrap,
}) =>
    // The "EXTENTION" typo is load-bearing, package:dwds depends on it.
    '''
/* ENTRYPOINT_EXTENTION_MARKER */

(function() {
  const appName = "$entrypoint";

  dartDevEmbedder.debugger.registerDevtoolsFormatter();

  // Set up a final script that lets us know when all scripts have been loaded.
  // Only then can we call the main method.
  const onLoadEndSrc = '$onLoadEndBootstrap';
  window.\$dartLoader.loadConfig.bootstrapScript = {
    src: onLoadEndSrc,
    id: onLoadEndSrc,
  };
  window.\$dartLoader.loadConfig.tryLoadBootstrapScript = true;
  // Should be called by $onLoadEndBootstrap once all the scripts have been
  // loaded.
  window.\$onLoadEndCallback = function() {
    const child = {};
    child.main = function() {
      dartDevEmbedder.runMain(appName, {});
    }
    /* MAIN_EXTENSION_MARKER */
    child.main();
  }
})();
''';

String generateDdcLibraryBundleOnLoadEndBootstrap() =>
    r'window.$onLoadEndCallback();';
