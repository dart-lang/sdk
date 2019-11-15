// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/generated/source.dart';
import 'package:analyzer/src/generated/timestamped_data.dart';
import 'package:analyzer_plugin/protocol/protocol_common.dart';
import 'package:mockito/mockito.dart';
import 'package:nnbd_migration/instrumentation.dart';
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
    final text = 'void f() {}\nint g() => null;';
    final offset = text.indexOf('int') + 3;
    final potentialModification = _PotentialModificationMock(
        _NullabilityFixDescriptionMock(
            'Add ?', NullabilityFixKind.makeTypeNullable),
        false,
        [SourceEdit(offset, 0, '?')]);
    final listener = NullabilityMigrationListenerMock();
    final source = SourceMock(text);
    when(variables.getPotentialModifications()).thenReturn({
      source: [potentialModification]
    });

    NullabilityMigrationImpl.broadcast(variables, listener, null);

    final fix = verify(listener.addFix(captureAny)).captured.single
        as SingleNullabilityFix;
    expect(fix.description.appliedMessage, 'Add ?');
    expect(fix.source, source);
    expect(fix.location.offset, offset);
    expect(fix.location.length, 0);
    expect(fix.location.file, '/test.dart');
    expect(fix.location.startLine, 2);
    expect(fix.location.startColumn, 4);
    verifyNever(listener.reportException(any, any, any, any));
    final edit =
        verify(listener.addEdit(fix, captureAny)).captured.single as SourceEdit;
    expect(edit.offset, offset);
    expect(edit.length, 0);
    expect(edit.replacement, '?');
  }

  void test_noModifications_notReported() {
    final potentialModification = _PotentialModificationMock.empty(
        _NullabilityFixDescriptionMock(
            'foo', NullabilityFixKind.noModification));
    final listener = NullabilityMigrationListenerMock();
    final source = SourceMock('');
    when(variables.getPotentialModifications()).thenReturn({
      source: [potentialModification]
    });

    NullabilityMigrationImpl.broadcast(variables, listener, null);

    verifyNever(listener.addFix(any));
    verifyNever(listener.reportException(any, any, any, any));
    verifyNever(listener.addEdit(any, any));
  }

  void test_noPotentialChanges_notReported() {
    final listener = NullabilityMigrationListenerMock();
    final source = SourceMock('');
    when(variables.getPotentialModifications()).thenReturn({source: []});

    NullabilityMigrationImpl.broadcast(variables, listener, null);

    verifyNever(listener.addFix(any));
    verifyNever(listener.reportException(any, any, any, any));
    verifyNever(listener.addEdit(any, any));
  }
}

class NullabilityMigrationListenerMock extends Mock
    implements NullabilityMigrationListener {}

class SourceMock extends Mock implements Source {
  final String _contents;

  SourceMock(this._contents);
  TimestampedData<String> get contents => TimestampedData<String>(0, _contents);
  String get fullName => '/test.dart';
}

class VariablesMock extends Mock implements Variables {}

class _NullabilityFixDescriptionMock implements NullabilityFixDescription {
  @override
  final String appliedMessage;
  @override
  final NullabilityFixKind kind;

  _NullabilityFixDescriptionMock(this.appliedMessage, this.kind);
}

class _PotentialModificationMock extends PotentialModification {
  @override
  final NullabilityFixDescription description;

  @override
  final bool isEmpty;

  @override
  final Iterable<SourceEdit> modifications;

  _PotentialModificationMock(
      this.description, this.isEmpty, this.modifications);

  _PotentialModificationMock.empty(this.description)
      : isEmpty = false,
        modifications = [];

  @override
  Iterable<FixReasonInfo> get reasons => throw UnimplementedError();
}
