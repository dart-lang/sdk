// Copyright (c) 2026, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/src/utilities/pubspec.dart';
import 'package:analyzer_testing/resource_provider_mixin.dart';
import 'package:pub_semver/pub_semver.dart';
import 'package:test/test.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(PubspecTest);
  });
}

@reflectiveTest
class PubspecTest with ResourceProviderMixin {
  String get testPubspecPath => convertPath('/test/pubspec.yaml');

  void test_any() {
    _assertEdit('any', '^2.13.0');
  }

  void test_caret() {
    _assertEdit('^2.12.0', '^2.13.0');
  }

  void test_compound() {
    _assertEdit("'>=2.12.0 <3.0.0'", '>=2.13.0 <3.0.0');
  }

  void test_gt() {
    _assertEdit("'>2.12.0'", '>=2.13.0');
  }

  void test_gte() {
    _assertEdit("'>=2.12.0'", '>=2.13.0');
  }

  void test_invalid() {
    _assertEdit('not a version', null);
  }

  void test_specificVersion() {
    _assertEdit('2.12.0', null);
  }

  /// Raising only the lower bound here would produce the empty range
  /// `>=2.13.0 <2.13.0`, so the ceiling that excludes 2.13.0 is dropped.
  void test_tightUpperBound() {
    _assertEdit("'>=2.12.0 <2.13.0'", '^2.13.0');
  }

  /// A ceiling well above the new minimum is neither raised nor widened.
  void test_unrelatedUpperBound() {
    _assertEdit("'>=2.12.0 <2.20.0'", '>=2.13.0 <2.20.0');
  }

  void _assertEdit(String from, String? expectedConstraint) {
    newFile(testPubspecPath, '''
environment:
  sdk: $from
''');
    var file = getFile(testPubspecPath);
    var edit = computeEdit(file, Version(2, 13, 0));
    if (expectedConstraint == null) {
      expect(edit, isNull);
    } else {
      expect(edit, isNotNull);
      expect(edit!.newConstraint, expectedConstraint);
    }
  }
}
