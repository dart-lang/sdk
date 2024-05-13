// Copyright (c) 2023, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/pubspec/pubspec_validator.dart';
import 'package:analyzer/src/pubspec/pubspec_warning_code.dart';
import 'package:analyzer/src/util/yaml.dart';
import 'package:yaml/yaml.dart';

/// List of supported platforms.
const _knownPlatforms = <String>{
  'android',
  'ios',
  'linux',
  'macos',
  'web',
  'windows',
};

/// Validate platforms.
void platformsValidator(PubspecValidationContext ctx) {
  var contents = ctx.contents;
  if (contents is! YamlMap) return;
  var platforms = contents.nodes[PubspecField.PLATFORMS_FIELD];
  if (platforms == null) {
    return;
  }
  // The 'platforms' field must be a map
  if (platforms is! YamlMap) {
    ctx.reportErrorForNode(
      platforms,
      PubspecWarningCode.INVALID_PLATFORMS_FIELD,
    );
    return;
  }
  // Each key under 'platforms' must be a supported platform.
  for (var platform in platforms.nodeMap.keys) {
    if (platform is! YamlScalar || !_knownPlatforms.contains(platform.value)) {
      ctx.reportErrorForNode(
        platform,
        PubspecWarningCode.UNKNOWN_PLATFORM,
        [
          switch (platform.value) {
            (String s) => s,
            (num n) => n,
            _ => platform.toString(),
          },
        ],
      );
    }
  }
  // Values under the platforms keys are not allowed.
  for (var v in platforms.nodeMap.values) {
    if (v is! YamlScalar || v.value != null) {
      ctx.reportErrorForNode(
        v,
        PubspecWarningCode.PLATFORM_VALUE_DISALLOWED,
      );
    }
  }
}
