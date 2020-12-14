// Copyright (c) 2020, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// @dart = 2.9

import 'dart:io' show File, Platform;
import 'package:yaml/yaml.dart' show YamlMap, loadYaml;

void main() {
  YamlMap yaml =
      loadYaml(new File.fromUri(computeYamlFile()).readAsStringSync());
  final currentVersion = getAsVersionNumber(yaml['current-version']);
  final enumNames = new StringBuffer();
  final featureValues = new StringBuffer();
  final featureNames = new StringBuffer();

  YamlMap features = yaml['features'];
  for (var entry in features.entries) {
    final category = (entry.value as YamlMap)['category'];
    if (category == null || category == "vm" || category == "language") {
      final version = getAsVersionNumber((entry.value as YamlMap)['enabledIn']);
      if (version != null) {
        final value = isGreaterOrEqualVersion(currentVersion, version);
        final name = entry.key.replaceAll('-', '_');
        enumNames.write('  $name,\n');
        featureValues.write('    $value,\n');
        featureNames.write('    "${entry.key}",\n');
      }
    }
  }

  final h = '''
// Copyright (c) 2020, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
// NOTE: THIS FILE IS GENERATED. DO NOT EDIT.
//
// Instead modify 'tools/experimental_features.yaml' and run
// 'dart tools/generate_experimental_flags.dart' to update.
//
// Current version: ${currentVersion.join('.')}

#ifndef RUNTIME_VM_EXPERIMENTAL_FEATURES_H_
#define RUNTIME_VM_EXPERIMENTAL_FEATURES_H_

namespace dart {

enum class ExperimentalFeature {
$enumNames};

bool GetExperimentalFeatureDefault(ExperimentalFeature feature);
const char* GetExperimentalFeatureName(ExperimentalFeature feature);

}  // namespace dart

#endif  // RUNTIME_VM_EXPERIMENTAL_FEATURES_H_
''';

  final cc = '''
// Copyright (c) 2020, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
// NOTE: THIS FILE IS GENERATED. DO NOT EDIT.
//
// Instead modify 'tools/experimental_features.yaml' and run
// 'dart tools/generate_experimental_flags.dart' to update.
//
// Current version: ${currentVersion.join('.')}

#include "vm/experimental_features.h"

#include <cstring>
#include "platform/assert.h"
#include "vm/globals.h"

namespace dart {

bool GetExperimentalFeatureDefault(ExperimentalFeature feature) {
  constexpr bool kFeatureValues[] = {
$featureValues  };
  ASSERT(static_cast<size_t>(feature) < ARRAY_SIZE(kFeatureValues));
  return kFeatureValues[static_cast<int>(feature)];
}

const char* GetExperimentalFeatureName(ExperimentalFeature feature) {
  constexpr const char* kFeatureNames[] = {
$featureNames  };
  ASSERT(static_cast<size_t>(feature) < ARRAY_SIZE(kFeatureNames));
  return kFeatureNames[static_cast<int>(feature)];
}

}  // namespace dart
''';

  File.fromUri(computeHFile()).writeAsStringSync(h);
  File.fromUri(computeCcFile()).writeAsStringSync(cc);
}

Uri computeYamlFile() {
  return Platform.script.resolve("experimental_features.yaml");
}

Uri computeCcFile() {
  return Platform.script.resolve("../runtime/vm/experimental_features.cc");
}

Uri computeHFile() {
  return Platform.script.resolve("../runtime/vm/experimental_features.h");
}

List<num> getAsVersionNumber(dynamic value) {
  if (value == null) return null;
  final version = List.of("$value".split(".").map(int.parse));
  while (version.length < 3) version.add(0);
  return version;
}

bool isGreaterOrEqualVersion(List<num> left, List<num> right) {
  assert(left.length == right.length);
  for (var i = 0; i < left.length; ++i) {
    if (left[i] != right[i]) return left[i] > right[i];
  }
  return true;
}
