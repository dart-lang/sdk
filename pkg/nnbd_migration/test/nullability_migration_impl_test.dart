// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/generated/source.dart';
import 'package:analyzer/src/generated/timestamped_data.dart';
import 'package:mockito/mockito.dart';
import 'package:nnbd_migration/nnbd_migration.dart';
import 'package:nnbd_migration/src/nullability_migration_impl.dart';
import 'package:nnbd_migration/src/variables.dart';
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
