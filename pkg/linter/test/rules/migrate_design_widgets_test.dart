// Copyright (c) 2026, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/error/error.dart';
import 'package:analyzer/src/diagnostic/diagnostic.dart' as diag;
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../rule_test_support.dart';

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(MigrateDesignWidgetsTest);
  });
}

@reflectiveTest
class MigrateDesignWidgetsTest extends LintRuleTest {
  @override
  List<DiagnosticCode> get ignoredDiagnosticCodes => [diag.uriDoesNotExist];

  @override
  String get lintRule => LintNames.migrate_design_widgets;

  test_migrateCupertino() async {
    await assertDiagnosticsFromMarkup(r'''
import [!'package:flutter/cupertino.dart'!];
''');
  }

  test_migrateMaterial() async {
    await assertDiagnosticsFromMarkup(r'''
import [!'package:flutter/material.dart'!];
''');
  }

  test_noMigration() async {
    await assertNoDiagnostics(r'''
import 'package:flutter/widgets.dart';
''');
  }
}
