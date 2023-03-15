// Copyright (c) 2021, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:io';

import 'package:path/path.dart' as path;
import 'package:pub_semver/pub_semver.dart';
import 'package:yaml/yaml.dart' as yaml;

/// Synchronously searches starting from the current working directory
/// for experimental_features.yaml, then caches it in this variable.
final experimentalFeaturesYaml = () {
  var features = path.join('tools', 'experimental_features.yaml');
  var searchDir = '.';
  var root = path.canonicalize(path.separator);

  do {
    var tryPath = path.join(searchDir, features);
    if (File(path.join(searchDir, features)).existsSync()) {
      return tryPath;
    }

    searchDir = path.join(searchDir, '..');
  } while (path.canonicalize(searchDir) != root);

  throw 'experimental_features.yaml not found';
}();

/// The unexpired experiments from `experimental_features.yaml` that have an
/// associated `validation` program.  Can not use async here as that will
/// break test_all.dart.
List<Experiment> experimentsWithValidation() {
  final experiments = yaml.loadYaml(
      File(experimentalFeaturesYaml).readAsStringSync(),
      sourceUrl: path.toUri(experimentalFeaturesYaml));
  return [
    for (final e in experiments['features'].entries)
      if (e.value['expired'] != true && e.value['validation'] != null)
        Experiment(
          e.key,
          e.value['validation'],
          tryParseVersion(e.value['enabledIn']),
          tryParseVersion(e.value['experimentalReleaseVersion']),
        )
  ];
}

Version? tryParseVersion(String? version) =>
    version == null ? null : Version.parse(version);

class Experiment {
  final String name;
  final String validation;
  final Version? enabledIn;
  final Version? experimentalReleaseVersion;
  Experiment(
    this.name,
    this.validation,
    this.enabledIn,
    this.experimentalReleaseVersion,
  );
}
