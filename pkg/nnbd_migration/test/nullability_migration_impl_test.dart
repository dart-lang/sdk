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
  NullabilityMigrationImpl nullabilityMigrationImpl =
      NullabilityMigrationImpl(null);

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

    nullabilityMigrationImpl.broadcast(variables, listener, null);

    final capturedSuggestions =
        verify(listener.addSuggestion(captureAny, captureAny)).captured;
    expect(capturedSuggestions, hasLength(2));
    var descriptions = capturedSuggestions[0];
    var location = capturedSuggestions[1] as Location;
    expect(descriptions, 'Add ?');
    expect(location.offset, offset);
    expect(location.length, 0);
    expect(location.file, '/test.dart');
    expect(location.startLine, 2);
    expect(location.startColumn, 4);
    verifyNever(listener.reportException(any, any, any, any));
    final edit =
        verify(listener.addEdit(any, captureAny)).captured.single as SourceEdit;
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

    nullabilityMigrationImpl.broadcast(variables, listener, null);

    verifyNever(listener.addSuggestion(any, any));
    verifyNever(listener.reportException(any, any, any, any));
    verifyNever(listener.addEdit(any, any));
  }

  void test_noPotentialChanges_notReported() {
    final listener = NullabilityMigrationListenerMock();
    final source = SourceMock('');
    when(variables.getPotentialModifications()).thenReturn({source: []});

    nullabilityMigrationImpl.broadcast(variables, listener, null);

    verifyNever(listener.addSuggestion(any, any));
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
  Iterable<FixReasonInfo> get reasons => const [];
}
