// Copyright (c) 2026, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/src/utilities/pubspec.dart';
import 'package:analyzer_testing/resource_provider_mixin.dart';
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
    _assertBump('any', null);
  }

  void test_caret() {
    _assertBump('^2.12.0', '^2.13.0');
  }

  void test_compound() {
    _assertBump("'>=2.12.0 <3.0.0'", '>=2.13.0');
  }

  void test_gt() {
    _assertBump("'>2.12.0'", '>=2.13.0');
  }

  void test_invalid() {
    _assertBump('not a version', null);
  }

  void test_specificVersion() {
    _assertBump('2.12.0', null);
  }

  void _assertBump(String from, String? expectedReplacement) {
    newFile(testPubspecPath, '''
environment:
  sdk: $from
''');
    var file = getFile(testPubspecPath);
    var edit = computeVersionBumpEdit(file);
    if (expectedReplacement == null) {
      expect(edit, isNull);
    } else {
      expect(edit, isNotNull);
      expect(edit!.replacement, expectedReplacement);
    }
  }
}
