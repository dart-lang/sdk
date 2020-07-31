// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer_plugin/protocol/protocol_common.dart';
import 'package:nnbd_migration/src/front_end/migration_info.dart';
import 'package:nnbd_migration/src/front_end/offset_mapper.dart';
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

  void test_handleSourceEdit() {
    final unitInfo = UnitInfo('/foo.dart');
    unitInfo.content = 'int  x;';
    unitInfo.migrationOffsetMapper =
        OffsetMapper.forEdits([SourceEdit('int'.length, 0, ' ')]);
    unitInfo.handleSourceEdit(SourceEdit('int'.length, 0, '/*?*/'));
    expect(unitInfo.content, 'int/*?*/  x;');
    expect(unitInfo.offsetMapper.map('in'.length), 'in'.length);
    expect(unitInfo.offsetMapper.map('int'.length), 'int/*?*/'.length);
    expect(unitInfo.offsetMapper.map('int x'.length), 'int/*?*/  x'.length);
    expect(unitInfo.diskChangesOffsetMapper.map('in'.length), 'in'.length);
    expect(
        unitInfo.diskChangesOffsetMapper.map('int'.length), 'int/*?*/'.length);
    expect(unitInfo.diskChangesOffsetMapper.map('int x'.length),
        'int/*?*/ x'.length);
  }

  void test_handleSourceEdit_deletion() {
    final unitInfo = UnitInfo('/foo.dart');
    unitInfo.content = 'int/*!*/ x = null!;';
    unitInfo.migrationOffsetMapper =
        OffsetMapper.forEdits([SourceEdit('int/*!*/ x = null'.length, 0, '!')]);
    unitInfo.handleSourceEdit(SourceEdit('int'.length, '/*!*/'.length, ''));
    expect(unitInfo.content, 'int x = null!;');
    expect(unitInfo.offsetMapper.map('in'.length), 'in'.length);
    expect(unitInfo.offsetMapper.map('int/*!*/ x'.length), 'int x'.length);
    expect(unitInfo.offsetMapper.map('int/*!*/ x = null'.length),
        'int x = null'.length);
    expect(unitInfo.offsetMapper.map('int/*!*/ x = null;'.length),
        'int x = null!;'.length);
    expect(unitInfo.diskChangesOffsetMapper.map('in'.length), 'in'.length);
    expect(
        unitInfo.diskChangesOffsetMapper.map('int/*!*/'.length), 'int'.length);
    expect(unitInfo.diskChangesOffsetMapper.map('int/*!*/ x'.length),
        'int x'.length);
  }

  void test_handleSourceEdit_regression_41894() {
    final unitInfo = UnitInfo('/foo.dart');
    unitInfo.content = 'C<C<C<T > > >  x;';
    unitInfo.migrationOffsetMapper = OffsetMapper.forEdits([
      SourceEdit('C<C<C<T'.length, 0, ' '),
      SourceEdit('C<C<C<T>'.length, 0, ' '),
      SourceEdit('C<C<C<T>>'.length, 0, ' '),
      SourceEdit('C<C<C<T>>>'.length, 0, ' ')
    ]);
    unitInfo.handleSourceEdit(SourceEdit('C<C<C<T'.length, 0, '/*?*/'));
    unitInfo.handleSourceEdit(SourceEdit('C<C<C<T>'.length, 0, '/*?*/'));
    unitInfo.handleSourceEdit(SourceEdit('C<C<C<T>>'.length, 0, '/*?*/'));
    unitInfo.handleSourceEdit(SourceEdit('C<C<C<T>>>'.length, 0, '/*?*/'));

    // Before 41894 was fixed, this would produce:
    //
    // `C<C<C<T/*?*/ >/*?*/ >/*/*?*/?*/ >  x;`
    //
    // because the diskChangesOffsetMapper contained an insertion that was
    // mapped on the post-migrated content mapper instead of the disk changes
    // content mapper.
    //
    // This essentially meant that migrationInfo thought that the second to last
    // /*?*/ hint was added 3 characters too late in the file, (that's the
    // *migrated* offset of the third insertion), and so making an edit within
    // those three characters was mapped five characters too early. In this
    // example the fourth edit was presumed, from the offset mapper logic, to
    // be an insertion before the second-to-last insertion when it is in fact
    // insert after it.
    expect(unitInfo.content, 'C<C<C<T/*?*/ >/*?*/ >/*?*/ >/*?*/  x;');

    // Rigorous offset mapper testing.
    expect(unitInfo.offsetMapper.map('C<C<C<'.length), 'C<C<C<'.length);
    expect(unitInfo.offsetMapper.map('C<C<C<T'.length), 'C<C<C<T/*?*/'.length);
    expect(unitInfo.offsetMapper.map('C<C<C<T>'.length),
        'C<C<C<T/*?*/ >/*?*/'.length);
    expect(unitInfo.offsetMapper.map('C<C<C<T>>'.length),
        'C<C<C<T/*?*/ >/*?*/ >/*?*/'.length);
    expect(unitInfo.offsetMapper.map('C<C<C<T>>>'.length),
        'C<C<C<T/*?*/ >/*?*/ >/*?*/ /*?*/>'.length);
    expect(unitInfo.offsetMapper.map('C<C<C<T>>> '.length),
        'C<C<C<T/*?*/ >/*?*/ >/*?*/ /*?*/>  '.length);
    expect(unitInfo.offsetMapper.map('C<C<C<T>>> x'.length),
        'C<C<C<T/*?*/ >/*?*/ >/*?*/ /*?*/>  x'.length);
    expect(
        unitInfo.diskChangesOffsetMapper.map('C<C<C<'.length), 'C<C<C<'.length);
    expect(unitInfo.diskChangesOffsetMapper.map('C<C<C<T'.length),
        'C<C<C<T/*?*/'.length);
    expect(unitInfo.diskChangesOffsetMapper.map('C<C<C<T>'.length),
        'C<C<C<T/*?*/>/*?*/'.length);
    expect(unitInfo.diskChangesOffsetMapper.map('C<C<C<T>>'.length),
        'C<C<C<T/*?*/>/*?*/>/*?*/'.length);
    expect(unitInfo.diskChangesOffsetMapper.map('C<C<C<T>>>'.length),
        'C<C<C<T/*?*/>/*?*/>/*?*//*?*/>'.length);
    expect(unitInfo.diskChangesOffsetMapper.map('C<C<C<T>>> '.length),
        'C<C<C<T/*?*/>/*?*/>/*?*//*?*/> '.length);
    expect(unitInfo.diskChangesOffsetMapper.map('C<C<C<T>>> x'.length),
        'C<C<C<T/*?*/>/*?*/>/*?*//*?*/> x'.length);
  }
}
