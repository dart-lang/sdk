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
  static bool get _areAssertsEnabled {
    try {
      assert(false);
      return false;
    } on AssertionError {
      return true;
    }
  }

  void test_hadDiskContent_different() {
    final unitInfo = UnitInfo('/foo.dart');
    unitInfo.diskContent = 'abcd';
    expect(unitInfo.hadDiskContent('dcba'), false);
  }

  void test_hadDiskContent_nullContentMatchesEmptyString() {
    final unitInfo = UnitInfo('/foo.dart');
    unitInfo.diskContent = '';
    expect(unitInfo.hadDiskContent(null), true);
    expect(unitInfo.hadDiskContent(''), true);
  }

  void test_hadDiskContent_nullMatchesEmptyStringContent() {
    final unitInfo = UnitInfo('/foo.dart');
    unitInfo.diskContent = null;
    expect(unitInfo.hadDiskContent(null), true);
    expect(unitInfo.hadDiskContent(''), true);
  }

  void test_hadDiskContent_theSame() {
    final unitInfo = UnitInfo('/foo.dart');
    unitInfo.diskContent = 'abcd';
    expect(unitInfo.hadDiskContent('abcd'), true);
  }

  void test_hadDiskContent_usedBeforeSet_assertsDisabled() {
    if (_areAssertsEnabled) return;

    final unitInfo = UnitInfo('/foo.dart');
    expect(unitInfo.hadDiskContent(''), false);
  }

  void test_hadDiskContent_usedBeforeSet_assertsEnabled() {
    if (!_areAssertsEnabled) return;

    final unitInfo = UnitInfo('/foo.dart');
    expect(() => unitInfo.hadDiskContent(''), throwsA(isA<AssertionError>()));
  }
}
