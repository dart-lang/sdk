// Copyright (c) 2018, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/file_system/file_system.dart';
import 'package:pub_semver/pub_semver.dart';
import 'package:yaml/yaml.dart';

/// A utility class used to extract the SDK version constraint from a
/// `pubspec.yaml` file.
class SdkConstraintExtractor {
  /// The file from which the constraint is to be extracted.
  final File pubspecFile;

  /// The version range that was
  VersionConstraint _constraint;

  /// Initialize a newly created extractor to extract the SDK version constraint
  /// from the given `pubspec.yaml` file.
  SdkConstraintExtractor(this.pubspecFile);

  /// Return the range of supported versions.
  VersionConstraint constraint() {
    if (_constraint == null) {
      try {
        String constraintText = _getConstraintText();
        if (constraintText != null) {
          _constraint = new VersionConstraint.parse(constraintText);
        }
      } catch (e) {
        // Return `null` by falling through without setting `_versionRange`.
      }
    }
    return _constraint;
  }

  /// Return the constraint text following "sdk:".
  String _getConstraintText() {
    String fileContent = pubspecFile.readAsStringSync();
    YamlDocument document = loadYamlDocument(fileContent);
    YamlNode contents = document.contents;
    if (contents is YamlMap) {
      var environment = contents['environment'];
      if (environment is YamlMap) {
        var sdk = environment['sdk'];
        if (sdk is String) {
          return sdk;
        } else if (sdk is YamlScalar) {
          return sdk.toString();
        }
      }
    }
    return null;
  }
}
