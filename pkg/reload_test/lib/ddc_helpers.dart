// Copyright (c) 2024, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:convert';
import 'dart:ffi';
import 'dart:io';

/// Maps a generation to its modified libraries' ID and JS URL.
///
/// Example:
/// {
///   0: [['main', '/some/path/main.0.js']],
///   1: [['main', '/some/path/main.1.js'], ['lib', '/some/path/lib.1.js']]
/// }
typedef FileDataPerGeneration = Map<String, List<List<String>>>;

final _encoder = JsonEncoder.withIndent('  ');

class D8Configuration {
  final Uri sdkRoot;
  final Uri binary;
  final Uri preamblesScript;
  final Uri sealNativeObjectScript;

  D8Configuration._(this.sdkRoot, this.binary, this.preamblesScript,
      this.sealNativeObjectScript);

  factory D8Configuration(Uri sdkRoot) {
    final preamblesScript = sdkRoot
        .resolve('sdk/lib/_internal/js_dev_runtime/private/preambles/d8.js');
    final sealNativeObjectScript = sdkRoot.resolve(
        'sdk/lib/_internal/js_runtime/lib/preambles/seal_native_object.js');
    final arch = Abi.current().toString().split('_')[1];
    final Uri binaryFromRoot;
    if (Platform.isWindows) {
      binaryFromRoot = Uri.file('third_party/d8/windows/$arch/d8.exe');
    } else if (Platform.isLinux) {
      binaryFromRoot = Uri.file('third_party/d8/linux/$arch/d8');
    } else if (Platform.isMacOS) {
      binaryFromRoot = Uri.file('third_party/d8/macos/$arch/d8');
    } else {
      throw UnsupportedError('Unsupported platform for running d8: '
          '${Platform.operatingSystem}');
    }
    final binary = sdkRoot.resolveUri(binaryFromRoot);
    return D8Configuration._(
        sdkRoot, binary, preamblesScript, sealNativeObjectScript);
  }
}

/// Generates the JS bootstrapper for DDC with the DDC module system
/// (executed on D8).
///
/// `scriptDescriptors` maps module IDs to their JS script paths.
/// It has the form:
/// [
///   {
///     "id": "some__module__id.dart"
///     "src": "/path/to/file.js"
///   },
///   ...
/// ]
///
/// `modifiedFilesPerGeneration` maps generation ids to JS files modified in
/// that generation. It has the form:
/// {
///   "0": ["/path/to/file.js", "/path/to/file2.js", ...],
///   "1": ...
/// }
///
/// Note: All JS paths above are relative to `jsFileRoot`.
String generateD8Bootstrapper({
  required String ddcModuleLoaderJsPath,
  required String dartSdkJsPath,
  required String entrypointModuleName,
  String jsFileRoot = '',
  String uuid = '00000000-0000-0000-0000-000000000000',
  required String entrypointLibraryExportName,
  required List<Map<String, String?>> scriptDescriptors,
  required FileDataPerGeneration modifiedFilesPerGeneration,
}) {
  final d8BootstrapJS = '''
load("$ddcModuleLoaderJsPath");
load("$dartSdkJsPath");

var prerequisiteScripts = [
  {
    "id": "ddc_module_loader \\0",
    "src": "$ddcModuleLoaderJsPath"
  },
  {
    "id": "dart_sdk \\0",
    "src": "$dartSdkJsPath"
  }
];

let scripts = ${_encoder.convert(scriptDescriptors)};

let loadConfig = new self.\$dartLoader.LoadConfiguration();
loadConfig.isWindows = ${Platform.isWindows};
loadConfig.root = '$jsFileRoot';
// Loading the entrypoint late is only necessary in Chrome.
loadConfig.bootstrapScript = '';
loadConfig.loadScriptFn = function(loader) {
  loader.addScriptsToQueue(scripts, null);
  loader.loadEnqueuedModulesForD8();
}
loadConfig.ddcEventForLoadStart = /* LOAD_ALL_MODULES_START */ 1;
loadConfig.ddcEventForLoadedOk = /* LOAD_ALL_MODULES_END_OK */ 2;
loadConfig.ddcEventForLoadedError = /* LOAD_ALL_MODULES_END_ERROR */ 3;
let loader = new self.\$dartLoader.DDCLoader(loadConfig);

// Record prerequisite scripts' fully resolved URLs.
prerequisiteScripts.forEach(script => loader.registerScript(script));

// Note: these variables should only be used in non-multi-app scenarios since
// they can be arbitrarily overridden based on multi-app load order.
self.\$dartLoader.loadConfig = loadConfig;
self.\$dartLoader.loader = loader;

// Append hot reload runner-specific logic.
let modifiedFilesPerGeneration = ${_encoder.convert(modifiedFilesPerGeneration)};
let previousGenerations = new Set();

// Append a helper function for hot restart.
self.\$dartReloadModifiedModules = async function(subAppName, callback) {
  let expectedName = "$entrypointModuleName";
  if (subAppName !== expectedName) {
    throw Error("Unexpected app name " + subAppName
        + " (expected: " + expectedName + "). "
        + "Hot Reload Runner does not support multiple subapps, so only "
        + "one app name should be provided across reloads/restarts.");
  }

  // Resolve the next generation's directory and load all modified files.
  let nextGeneration = self.\$dartLoader.loader.intendedHotRestartGeneration;
  if (previousGenerations.has(nextGeneration)) {
    throw Error('Fatal error: Previous generations are being re-run.');
  }
  previousGenerations.add(nextGeneration);

  let modifiedFilePaths = modifiedFilesPerGeneration[nextGeneration];
  // Stop if the next generation does not exist.
  if (modifiedFilePaths == void 0) {
    return;
  }

  // Load all modified files.
  for (let i = 0; i < modifiedFilePaths.length; i++) {
    let modifiedFilePath = modifiedFilePaths[i][1];
    self.\$dartLoader.forceLoadScript(modifiedFilePath);
  }

  // Run main in an async callback. D8 performs synchronous loads, so we need
  // to insert an async task to match its semantics to that of Chrome.
  await Promise.resolve().then(() => { callback(); });
}

// Append a helper function for hot reload.
self.\$injectedFilesAndLibrariesToReload = function(fileGeneration) {
  modifiedFilePaths = modifiedFilesPerGeneration[fileGeneration];
  if (modifiedFilePaths == null) return null;
  // Collect reload generation resources.
  let fileUrls = [];
  let libraryIds = [];
  for (let i = 0; i < modifiedFilePaths.length; i++) {
    let modifiedFileId =  modifiedFilePaths[i][0];
    let modifiedFilePath = modifiedFilePaths[i][1];
    libraryIds.push(modifiedFileId);
    fileUrls.push(modifiedFilePath);
  }
  return [fileUrls, libraryIds];
}

// D8 does not support the core Timer API methods beside `setTimeout` so our
// D8 preambles provide a custom implementation.
//
// Timers in this implementation are simulated, so they all complete before
// native JS `await` boundaries. If this boundary occurs before our runtime's
// `hotRestartIteration` counter increments, we can observe Futures not being
// cancelled in D8 when they might otherwise have been in Chrome.
//
// To resolve this, we record and increment hot restart generations early
// and wrap timer functions with custom cancellation logic.
self.setTimeout = function(setTimeout) {
  let currentHotRestartIteration =
    self.\$dartLoader.loader.intendedHotRestartGeneration;
  return function(f, ms) {
    var internalCallback = function() {
      if (currentHotRestartIteration ==
            self.\$dartLoader.loader.intendedHotRestartGeneration) {
        f();
      }
    }
    setTimeout(internalCallback, ms);
  };
}(self.setTimeout);

// DDC also has a runtime implementation of microtasks' `scheduleImmediate`
// that more closely matches Chrome's behavior. We enable this implementation
// by deleting the our custom implementation in D8's preamble.
self.scheduleImmediate = void 0;

// Begin loading libraries
loader.nextAttempt();

// Invoke main through the d8 preamble to ensure the code is running
// within the fake event loop.
self.dartMainRunner(function () {
  dartDevEmbedder.runMain("$entrypointModuleName", {});
});
''';
  return d8BootstrapJS;
}

/// Generates the two files required to bootstrap a chrome app: a main
/// entrypoint file and an app bootstrapper - respectively.
(String, String) generateChromeBootstrapperFiles({
  required String ddcModuleLoaderJsPath,
  required String dartSdkJsPath,
  required String entrypointModuleName,
  required String mainModuleEntrypointJsPath,
  String jsFileRoot = '',
  String uuid = '00000000-0000-0000-0000-000000000000',
  required String entrypointLibraryExportName,
  required List<Map<String, String?>> scriptDescriptors,
  required FileDataPerGeneration modifiedFilesPerGeneration,
}) {
  var mainModuleText = generateChromeMainEntrypoint(
    entrypointModuleName: entrypointModuleName,
    entrypointLibraryExportName: entrypointLibraryExportName,
  );
  var chromeBootstrapper = generateChromeBootstrapper(
    ddcModuleLoaderJsPath: ddcModuleLoaderJsPath,
    dartSdkJsPath: dartSdkJsPath,
    entrypointModuleName: entrypointModuleName,
    mainModuleEntrypointJsPath: mainModuleEntrypointJsPath,
    jsFileRoot: jsFileRoot,
    uuid: uuid,
    scriptDescriptors: scriptDescriptors,
    modifiedFilesPerGeneration: modifiedFilesPerGeneration,
  );
  return (mainModuleText, chromeBootstrapper);
}

/// Generates a bootstrap entrypoint script for calling 'main'.
///
/// Only used for the DDC module system when run in Chrome.
String generateChromeMainEntrypoint({
  required String entrypointModuleName,
  bool nullAssertions = true,
  bool nativeNullAssertions = true,
  String uuid = '00000000-0000-0000-0000-000000000000',
  required String entrypointLibraryExportName,
}) {
  return '''
(function() {
  // Flutter Web uses a generated main entrypoint, which shares app and module names.
  // We adopt their convention in this framework to make comparisons more direct.
  let appName = "$entrypointModuleName";
  let moduleName = "$entrypointModuleName";

  // Multi-apps are not supported in this framework, so uuids are irrelevant.
  let uuid = "$uuid";

  let child = {};
  child.main = function() {
    dartDevEmbedder.runMain("$entrypointModuleName", {});
  }

  child.main();
})();
''';
}

/// Generates the JS bootstrapper for DDC with the DDC module system
/// (executed on Chrome).
///
/// `scriptDescriptors` maps module IDs to their JS script paths.
/// It has the form:
/// [
///   {
///     "id": "some__module__id.dart"
///     "src": "/path/to/file.js"
///   },
///   ...
/// ]
///
/// `modifiedFilesPerGeneration` maps generation ids to JS files modified in
/// that generation. It has the form:
/// {
///   "0": ["/path/to/file.js", "/path/to/file2.js", ...],
///   "1": ...
/// }
///
/// Note: All JS paths above are relative to `jsFileRoot`.
String generateChromeBootstrapper({
  required String ddcModuleLoaderJsPath,
  required String dartSdkJsPath,
  required String entrypointModuleName,
  required String mainModuleEntrypointJsPath,
  String jsFileRoot = '',
  String uuid = '00000000-0000-0000-0000-000000000000',
  required List<Map<String, String?>> scriptDescriptors,
  required FileDataPerGeneration modifiedFilesPerGeneration,
}) {
  final bootstrapJS = '''
var _currentDirectory = "$jsFileRoot";

window.\$dartCreateScript = (function() {
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

// Creates and loads a script during hot restart.
var loadHotRestartScript = function(id, src, callback) {
  var script = self.\$dartCreateScript();
  let policy = {
    createScriptURL: function(src) {return src;}
  };
  if (self.trustedTypes && self.trustedTypes.createPolicy) {
    policy = self.trustedTypes.createPolicy('dartDdcModuleUrl', policy);
  }
  script.src = policy.createScriptURL(src);
  script.async = false
  script.defer = true;
  script.id = id;
  script.onload = callback;
  document.head.appendChild(script);
}

// Loads a module [relativeUrl] relative to [root].
//
// If not specified, [root] defaults to the directory serving the main app.
//
// Used for appending pre-requisite modules to the page.
var forceLoadModule = function (relativeUrl, root) {
  var actualRoot = root ?? _currentDirectory;
  return new Promise(function(resolve, reject) {
    var script = self.\$dartCreateScript();
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

// A map containing the URLs for the bootstrap scripts in debug.
let _scriptUrls = {
  "moduleLoader": "$ddcModuleLoaderJsPath"
};

(function() {
  let appName = "$entrypointModuleName";

  // A uuid that identifies a subapp. Unused for this framework.
  let uuid = $uuid;

  // Load pre-requisite DDC scripts.
  // We intentionally use invalid names to avoid namespace clashes.
  let prerequisiteScripts = [
    {
      "src": "$ddcModuleLoaderJsPath",
      "id": "ddc_module_loader \x00"
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
        "src": "$dartSdkJsPath",
        "id": "dart_sdk \\0"
      },
    ].concat(${_encoder.convert(scriptDescriptors)});

    let loadConfig = new window.\$dartLoader.LoadConfiguration();
    loadConfig.isWindows = ${Platform.isWindows};
    loadConfig.root = '$jsFileRoot';
    loadConfig.bootstrapScript = {
      "src": "$mainModuleEntrypointJsPath",
      "id": "data-main"
    };
    scripts.push(loadConfig.bootstrapScript);

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

    // Note: these variables should only be used in non-multi-app scenarios since
    // they can be arbitrarily overridden based on multi-app load order.
    window.\$dartLoader.loadConfig = loadConfig;
    window.\$dartLoader.loader = loader;

    // Append hot reload runner-specific logic.
    let modifiedFilesPerGeneration = ${_encoder.convert(modifiedFilesPerGeneration)};

    // Append a helper function for hot reload.
    self.\$injectedFilesAndLibrariesToReload = function(fileGeneration) {
      modifiedFilePaths = modifiedFilesPerGeneration[fileGeneration];
      if (modifiedFilePaths == null) return null;
      // Collect reload generation resources.
      let fileUrls = [];
      let libraryIds = [];
      for (let i = 0; i < modifiedFilePaths.length; i++) {
        let modifiedFileId =  modifiedFilePaths[i][0];
        let modifiedFilePath = modifiedFilePaths[i][1];
        libraryIds.push(modifiedFileId);
        fileUrls.push(modifiedFilePath);
      }
      return [fileUrls, libraryIds];
    }

    let previousGenerations = new Set();
    self.\$dartReloadModifiedModules = async function(subAppName, callback) {
      let expectedName = "$entrypointModuleName";
      if (subAppName !== expectedName) {
        throw Error("Unexpected app name " + subAppName
            + " (expected: " + expectedName + "). "
            + "Hot Reload Runner does not support multiple subapps, so only "
            + "one app name should be provided across reloads/restarts.");
      }

      // Resolve the next generation's directory and load all modified files.
      let nextGeneration = self.\$dartLoader.loader.intendedHotRestartGeneration;
      if (previousGenerations.has(nextGeneration)) {
        throw Error('Fatal error: Previous generations are being re-run.');
      }
      previousGenerations.add(nextGeneration);

      let modifiedFilePaths = modifiedFilesPerGeneration[nextGeneration];
      // Stop if the next generation does not exist.
      if (modifiedFilePaths == void 0) {
        return;
      }

      // Load all modified files.
      var numToLoad = 0;
      var numLoaded = 0;
      for (let i = 0; i < modifiedFilePaths.length; i++) {
        numToLoad++
        let modifiedFileId =  modifiedFilePaths[i][0];
        let modifiedFilePath = modifiedFilePaths[i][1];

        // Invalidate DDC state for hot restart.
        self.\$dartLoader.moduleIdToUrl.set(modifiedFileId, modifiedFilePath);
        self.\$dartLoader.urlToModuleId.set(modifiedFilePath, modifiedFileId);

        // Remove the old script.
        var el = document.getElementById(modifiedFileId);
        if (el) el.remove();

        loadHotRestartScript(modifiedFileId, modifiedFilePath, function() {
          numLoaded++;
          if (numToLoad == numLoaded) callback();
        });
      }

      // Call the callback immediately if we found no updated scripts.
      if (numToLoad == 0) callback();
    }

    // Begin loading libraries
    loader.nextAttempt();
  }
})();
''';
  return bootstrapJS;
}

class ChromeConfiguration {
  final Uri sdkRoot;
  final Uri binary;

  ChromeConfiguration._(this.sdkRoot, this.binary);

  factory ChromeConfiguration(Uri sdkRoot) {
    String chromeBinary;
    if (Platform.isWindows) {
      chromeBinary =
          'C:\\Program Files (x86)\\Google\\Chrome\\Application\\chrome.exe';
    } else if (Platform.isMacOS) {
      chromeBinary =
          '/Applications/Google Chrome.app/Contents/MacOS/Google Chrome';
    } else {
      // Assume Linux
      chromeBinary = 'google-chrome';
    }

    final binary = Uri.file(chromeBinary);
    return ChromeConfiguration._(sdkRoot, binary);
  }
}
