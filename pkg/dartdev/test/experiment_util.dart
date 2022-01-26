// Copyright (c) 2021, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:io';
import 'dart:isolate';

import 'package:pub_semver/pub_semver.dart';
import 'package:yaml/yaml.dart' as yaml;

/// The unexpired experiments from `experimental_features.yaml` that have an
/// associated `validation` program.
Future<List<Experiment>> experimentsWithValidation() async {
  final url = (await Isolate.resolvePackageUri(
          Uri.parse('package:dartdev/dartdev.dart')))!
      .resolve('../../../tools/experimental_features.yaml');
  final experiments =
      yaml.loadYaml(File.fromUri(url).readAsStringSync(), sourceUrl: url);
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
