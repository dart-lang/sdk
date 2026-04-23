// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

@TestOn('vm')
library;

import 'dart:io';

import 'package:dwds/src/version.dart';
import 'package:pub_semver/pub_semver.dart';
import 'package:test/test.dart';
import 'package:yaml/yaml.dart';

void main() {
  test('dwds lib/src/version.dart matches the pubspec version', () {
    final pubspec = loadYaml(File('pubspec.yaml').readAsStringSync()) as Map;
    expect(
      Version.parse(packageVersion),
      Version.parse(pubspec['version'] as String),
      reason: 'Please run `dart run tool/build.dart` to update the version.',
    );
  });
}
