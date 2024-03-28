// Copyright (c) 2024, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:convert';
import 'dart:ffi';
import 'dart:io';

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

/// Generates the JS bootstrapper for DDC with the DDC module system.
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
  required Map<String, List<String>> modifiedFilesPerGeneration,
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

let sdk = dart_library.import('dart_sdk');
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
self.\$dartReloadModifiedModules = function(subAppName, callback) {
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

  // Increment the hot restart generation before loading files or running main
  // This lets us treat the value in `hotRestartGeneration` as the 'current'
  // generation until local state is updated.
  self.\$dartLoader.loader.hotRestartGeneration += 1;

  let modifiedFilePaths = modifiedFilesPerGeneration[nextGeneration];
  // Stop if the next generation does not exist.
  if (modifiedFilePaths == void 0) {
    return;
  }

  // Load all modified files.
  for (let i = 0; i < modifiedFilePaths.length; i++) {
    self.\$dartLoader.forceLoadScript(modifiedFilePaths[i]);
  }

  // Run main.
  callback();
}

// D8 does not support the core Timer API methods beside `setTimeout` so our
// D8 preambles provide a custom implementation.
//
// Timers in this implementatiom are simulated, so they all complete before
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
  dart_library.start("$entrypointModuleName",
    "$uuid",
    "$entrypointModuleName",
    "$entrypointLibraryExportName",
    false
  );
});
''';
  return d8BootstrapJS;
}
