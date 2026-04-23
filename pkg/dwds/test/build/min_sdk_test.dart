// Copyright (c) 2021, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

@TestOn('vm')
@Skip('Intended to run in analyze stage on stable SDK only, see mono_pkg.yaml')
library;

import 'dart:io';

import 'package:pub_semver/pub_semver.dart';
import 'package:test/test.dart';
import 'package:yaml/yaml.dart';

void main() {
  test('dwds pubspec has the stable as min SDK constraint', () {
    final pubspec = loadYaml(File('pubspec.yaml').readAsStringSync()) as Map;
    var sdkVersion = Version.parse(Platform.version.split(' ')[0]);
    sdkVersion = Version(sdkVersion.major, sdkVersion.minor, 0);

    final sdkConstraint = VersionConstraint.compatibleWith(sdkVersion);
    final environment = pubspec['environment'] as Map? ?? {};
    final pubspecSdkConstraint = environment['sdk'];
    expect(pubspecSdkConstraint, isNotNull);
    final parsedConstraint = VersionConstraint.parse(
      pubspecSdkConstraint as String,
    );
    expect(
      sdkConstraint.allowsAll(parsedConstraint),
      true,
      reason:
          'Min sdk constraint is outdated. Please update SDK constraint in '
          'pubspec to allow latest stable and backwards compatible versions.'
          '\n  Current stable: $sdkVersion,'
          '\n  Dwds pubspec constraint: $pubspecSdkConstraint',
    );
  });
}
