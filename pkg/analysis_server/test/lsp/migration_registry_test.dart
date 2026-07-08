// Copyright (c) 2026, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/src/lsp/migration_registry.dart';
import 'package:analysis_server/src/services/correction/fix_internal.dart';
import 'package:analysis_server_plugin/edit/dart/correction_producer.dart';
import 'package:analysis_server_plugin/src/correction/fix_generators.dart';
import 'package:analyzer/error/error.dart';
import 'package:test/test.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(MigrationRegistryTest);
  });
}

@reflectiveTest
class MigrationRegistryTest {
  void setUp() {
    registerBuiltInFixGenerators();
  }

  /// Verifies that all lints registered in [migration_registry.dart] have
  /// exactly one bulk-fix producer associated with them.
  ///
  /// A lint rule is considered to have a bulk-fix if it has a registered
  /// [CorrectionProducer] in [registeredFixGenerators.lintProducers] with
  /// `canBeAppliedAcrossFiles` set to `true`.
  void test_migrationRegistryLintsHaveBulkFixes() {
    var lintsWithIncorrectProducerCount = <String, int>{};

    var allRegistryLints = {
      ...postMigrationLintsRegistry.values.expand((e) => e),
      ...preMigrationLintsRegistry.values.expand((e) => e),
    };

    var diagnosticCodes = <DiagnosticCode>[
      ...registeredFixGenerators.lintProducers.keys,
      ...registeredFixGenerators.lintMultiProducers.keys,
    ];

    for (var lintName in allRegistryLints) {
      var codesForLint = diagnosticCodes.where(
        (code) => code.lowerCaseName == lintName,
      );

      var bulkFixableProducerCount = 0;
      for (var code in codesForLint) {
        var producers = registeredFixGenerators.lintProducers[code];
        if (producers == null) continue;

        for (var generator in producers) {
          var producer = generator(
            context: StubCorrectionProducerContext.instance,
          );
          if (producer.canBeAppliedAcrossFiles) {
            bulkFixableProducerCount++;
          }
        }
      }

      if (bulkFixableProducerCount != 1) {
        lintsWithIncorrectProducerCount[lintName] = bulkFixableProducerCount;
      }
    }

    expect(
      lintsWithIncorrectProducerCount,
      isEmpty,
      reason:
          'Lints in the migration registry must have exactly one bulk-fix '
          'producer. The following lints do not satisfy this requirement: '
          '${lintsWithIncorrectProducerCount.keys}',
    );
  }
}
