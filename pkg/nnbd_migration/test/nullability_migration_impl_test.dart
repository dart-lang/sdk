// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/generated/source.dart';
import 'package:analyzer/src/generated/timestamped_data.dart';
import 'package:analyzer_plugin/protocol/protocol_common.dart';
import 'package:mockito/mockito.dart';
import 'package:nnbd_migration/nnbd_migration.dart';
import 'package:nnbd_migration/src/nullability_migration_impl.dart';
import 'package:nnbd_migration/src/potential_modification.dart';
import 'package:nnbd_migration/src/variables.dart';
import 'package:test/test.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(NullabilityMigrationImplTest);
  });
}

@reflectiveTest
class NullabilityMigrationImplTest {
  VariablesMock variables;

  void setUp() {
    variables = VariablesMock();
  }

  void test_modification_columnLineInfo() {
    final innerModification = PotentialModificationMock();
    final potentialModification =
        PotentiallyAddImport.forOffset(10, 'foo', innerModification);
    final listener = NullabilityMigrationListenerMock();
    final source = SourceMock('0123456\n8910');
    when(variables.getPotentialModifications()).thenReturn({
      source: [potentialModification]
    });

    when(innerModification.isEmpty).thenReturn(false);

    NullabilityMigrationImpl.broadcast(variables, listener);

    final fix = verify(listener.addFix(captureAny)).captured.single
        as SingleNullabilityFix;
    expect(fix.description.appliedMessage, 'Add import foo');
    expect(fix.source, source);
    expect(fix.location.offset, 10);
    expect(fix.location.length, 0);
    expect(fix.location.file, '/test.dart');
    expect(fix.location.startLine, 2);
    expect(fix.location.startColumn, 3);
    verifyNever(listener.reportException(any, any, any, any));
    final edit =
        verify(listener.addEdit(fix, captureAny)).captured.single as SourceEdit;
    expect(edit.offset, 10);
    expect(edit.length, 0);
    expect(edit.replacement, "import 'foo';\n");
  }

  void test_noModifications_notReported() {
    final potentialModification = PotentialModificationMock();
    final listener = NullabilityMigrationListenerMock();
    final source = SourceMock('');
    when(variables.getPotentialModifications()).thenReturn({
      source: [potentialModification]
    });

    when(potentialModification.modifications).thenReturn([]);

    NullabilityMigrationImpl.broadcast(variables, listener);

    verifyNever(listener.addFix(any));
    verifyNever(listener.reportException(any, any, any, any));
    verifyNever(listener.addEdit(any, any));
  }

  void test_noPotentialChanges_notReported() {
    final listener = NullabilityMigrationListenerMock();
    final source = SourceMock('');
    when(variables.getPotentialModifications()).thenReturn({source: []});

    NullabilityMigrationImpl.broadcast(variables, listener);

    verifyNever(listener.addFix(any));
    verifyNever(listener.reportException(any, any, any, any));
    verifyNever(listener.addEdit(any, any));
  }
}

class NullabilityMigrationListenerMock extends Mock
    implements NullabilityMigrationListener {}

class PotentialModificationMock extends Mock implements PotentialModification {}

class SourceMock extends Mock implements Source {
  final String _contents;

  SourceMock(this._contents);
  TimestampedData<String> get contents => TimestampedData<String>(0, _contents);
  String get fullName => '/test.dart';
}

class VariablesMock extends Mock implements Variables {}
