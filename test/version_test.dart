// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:io';

import 'package:linter/src/version.dart';
import 'package:test/test.dart';
import 'package:yaml/yaml.dart' as yaml;

void main() {
  group('package version', () {
    test('version file up to date', () {
      expect(readPackageVersion(), version,
          reason: 'lib/src/version.dart should match pubspec.yaml');
    });
  });
}

String readPackageVersion() {
  var pubspec = File('pubspec.yaml');
  var yamlDoc = yaml.loadYaml(pubspec.readAsStringSync());
  if (yamlDoc == null) {
    fail('Cannot find pubspec.yaml in ${Directory.current}');
  }
  var version = yamlDoc['version'];
  return version as String;
}
