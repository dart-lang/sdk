// Copyright (c) 2023, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/error/listener.dart';
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

final class PlatformsValidator extends BasePubspecValidator {
  PlatformsValidator(super.provider, super.source);

  /// Validate platforms.
  void validate(ErrorReporter reporter, Map<dynamic, YamlNode> contents) {
    var platforms = contents[PubspecField.PLATFORMS_FIELD];
    if (platforms == null) {
      return;
    }
    // The 'platforms' field must be a map
    if (platforms is! YamlMap) {
      reportErrorForNode(
        reporter,
        platforms,
        PubspecWarningCode.INVALID_PLATFORMS_FIELD,
      );
      return;
    }
    // Each key under 'platforms' must be a supported platform.
    for (final platform in platforms.nodeMap.keys) {
      if (platform is! YamlScalar ||
          !_knownPlatforms.contains(platform.value)) {
        reportErrorForNode(
          reporter,
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
    for (final v in platforms.nodeMap.values) {
      if (v is! YamlScalar || v.value != null) {
        reportErrorForNode(
          reporter,
          v,
          PubspecWarningCode.PLATFORM_VALUE_DISALLOWED,
        );
      }
    }
  }
}
