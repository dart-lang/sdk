// Copyright (c) 2026, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:convert';

import 'package:analysis_server/src/utilities/package_config.dart';
import 'package:pub_semver/pub_semver.dart';
import 'package:test/test.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(PackageConfigTest);
  });
}

@reflectiveTest
class PackageConfigTest {
  void test_error_invalidJson() {
    var result = updatePackageLanguageVersion(
      'not valid json',
      packageName: 'foo',
      languageVersion: Version(3, 0, 0),
    );
    expect(result, isNull);
  }

  void test_error_invalidPackagesField() {
    var json = jsonEncode({'configVersion': 2, 'packages': 'invalid'});
    var result = updatePackageLanguageVersion(
      json,
      packageName: 'foo',
      languageVersion: Version(3, 0, 0),
    );
    expect(result, isNull);
  }

  void test_error_missingPackage() {
    var json = jsonEncode({
      'configVersion': 2,
      'packages': [
        {
          'name': 'bar',
          'rootUri': '../bar',
          'packageUri': 'lib/',
          'languageVersion': '2.19',
        },
      ],
    });
    var result = updatePackageLanguageVersion(
      json,
      packageName: 'foo',
      languageVersion: Version(3, 0, 0),
    );
    expect(result, isNull);
  }

  void test_updateLanguageVersion() {
    var json = jsonEncode({
      'configVersion': 2,
      'packages': [
        {
          'name': 'foo',
          'rootUri': '../foo',
          'packageUri': 'lib/',
          'languageVersion': '2.19',
        },
        {
          'name': 'bar',
          'rootUri': '../bar',
          'packageUri': 'lib/',
          'languageVersion': '2.12',
        },
      ],
    });

    var result = updatePackageLanguageVersion(
      json,
      packageName: 'foo',
      languageVersion: Version(3, 0, 0),
    );
    expect(result, isNotNull);
    expect(jsonDecode(result!), {
      'configVersion': 2,
      'packages': [
        {
          'name': 'foo',
          'rootUri': '../foo',
          'packageUri': 'lib/',
          'languageVersion': '3.0',
        },
        {
          'name': 'bar',
          'rootUri': '../bar',
          'packageUri': 'lib/',
          'languageVersion': '2.12',
        },
      ],
    });
  }
}
