// Copyright (c) 2020, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:io' show Platform;

const String enableIncrementalCompilerBenchmarking =
    "DART_CFE_ENABLE_INCREMENTAL_COMPILER_BENCHMARKING";

const String enableIncrementalCompilerDepsScanAndLoad =
    "DART_CFE_ENABLE_INCREMENTAL_COMPILER_DEPS_SCAN_AND_LOAD";

const String pathIncrementalCompilerDepsScanAndLoad =
    "DART_CFE_PATH_INCREMENTAL_COMPILER_DEPS_SCAN_AND_LOAD";

const Set<String> _known = {
  enableIncrementalCompilerBenchmarking,
  enableIncrementalCompilerDepsScanAndLoad,
};

Set<String> getExperimentEnvironment() {
  if (const bool.fromEnvironment('dart.library.js_interop')) {
    return const <String>{};
  }
  Set<String> enabled = {};
  Map<String, String> environment = Platform.environment;
  for (String experiment in _known) {
    if (environment[experiment] == "true") {
      // Coverage-ignore-block(suite): Not run.
      enabled.add(experiment);
    }
  }
  return enabled;
}

// Coverage-ignore(suite): Not run.
String? getEnvironmentValue(String key) {
  if (const bool.fromEnvironment('dart.library.js_interop')) {
    return null;
  }

  Map<String, String> environment = Platform.environment;
  return environment[key];
}
