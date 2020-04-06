// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/src/edit/nnbd_migration/migration_info.dart';
import 'package:test/test.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(UnitInfoTest);
  });
}

@reflectiveTest
class UnitInfoTest {
  void test_hadOriginalContent_different() {
    final unitInfo = UnitInfo('/foo.dart');
    unitInfo.originalContent = 'abcd';
    expect(unitInfo.hadOriginalContent('dcba'), false);
  }

  void test_hadOriginalContent_nullContentMatchesEmptyString() {
    final unitInfo = UnitInfo('/foo.dart');
    unitInfo.originalContent = '';
    expect(unitInfo.hadOriginalContent(null), true);
    expect(unitInfo.hadOriginalContent(''), true);
  }

  void test_hadOriginalContent_nullMatchesEmptyStringContent() {
    final unitInfo = UnitInfo('/foo.dart');
    unitInfo.originalContent = null;
    expect(unitInfo.hadOriginalContent(null), true);
    expect(unitInfo.hadOriginalContent(''), true);
  }

  void test_hadOriginalContent_theSame() {
    final unitInfo = UnitInfo('/foo.dart');
    unitInfo.originalContent = 'abcd';
    expect(unitInfo.hadOriginalContent('abcd'), true);
  }

  void test_hadOriginalContent_usedBeforeSet_assertsDisabled() {
    try {
      assert(false);
    } on AssertionError {
      // Asserts enabled, stop here
      return;
    }
    final unitInfo = UnitInfo('/foo.dart');
    expect(unitInfo.hadOriginalContent(''), false);
  }

  void test_hadOriginalContent_usedBeforeSet_assertsEnabled() {
    try {
      assert(false);
      // asserts not enabled, stop here.
      return;
    } on AssertionError {}
    final unitInfo = UnitInfo('/foo.dart');
    expect(
        () => unitInfo.hadOriginalContent(''), throwsA(isA<AssertionError>()));
  }
}
