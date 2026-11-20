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

  test_export_cupertino_withCombinators() async {
    await assertDiagnosticsFromMarkup(r'''
library;

export [!'package:flutter/cupertino.dart'!] hide CupertinoButton;
''');
  }

  test_export_material() async {
    await assertDiagnosticsFromMarkup(r'''
export [!'package:flutter/material.dart'!];
''');
  }

  test_export_noMigration() async {
    await assertNoDiagnostics(r'''
export 'package:flutter/widgets.dart';
''');
  }

  test_import_and_export() async {
    await assertDiagnosticsFromMarkup(r'''
import /*[0*/'package:flutter/material.dart'/*0]*/;
export /*[1*/'package:flutter/material.dart'/*1]*/;
''');
  }

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
