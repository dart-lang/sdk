// Copyright (c) 2025, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/src/services/correction/fix.dart';
import 'package:analyzer_plugin/utilities/fixes/fixes.dart';
import 'package:linter/src/lint_names.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'fix_processor.dart';

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(RemoveAwaitBulkTest);
    defineReflectiveTests(RemoveAwaitTest);
  });
}

@reflectiveTest
class RemoveAwaitBulkTest extends BulkFixProcessorTest {
  @override
  String get lintCode => LintNames.unnecessary_unawaited;

  @override
  void setUp() {
    super.setUp();
    writeTestPackageConfig(meta: true);
  }

  Future<void> test_nested() async {
    await resolveTestCode(r'''
import 'dart:async';
import 'package:meta/meta.dart';
void f() async {
  unawaited(g('${unawaited(g())}'));
}

@awaitNotRequired
Future<int> g(String s) async => 7;
''');
    await assertHasFix(r'''
import 'dart:async';
import 'package:meta/meta.dart';
void f() async {
  g('${g()}');
}

@awaitNotRequired
Future<int> g(String s) async => 7;
''');
  }

  Future<void> test_singleFile() async {
    await resolveTestCode(r'''
import 'dart:async';
import 'package:meta/meta.dart';
void f() async {
  unawaited(g());
  unawaited(g());
}

@awaitNotRequired
Future<int> g() async => 7;
''');
    await assertHasFix(r'''
import 'dart:async';
import 'package:meta/meta.dart';
void f() async {
  g();
  g();
}

@awaitNotRequired
Future<int> g() async => 7;
''');
  }
}

@reflectiveTest
class RemoveAwaitTest extends FixProcessorLintTest {
  @override
  FixKind get kind => DartFixKind.removeUnawaited;

  @override
  String get lintCode => LintNames.unnecessary_unawaited;

  @override
  void setUp() {
    super.setUp();
    writeTestPackageConfig(meta: true);
  }

  Future<void> test_unawaited() async {
    await resolveTestCode('''
import 'dart:async';
import 'package:meta/meta.dart';
void f() async {
  unawaited(g());
}

@awaitNotRequired
Future<int> g() async => 7;
''');
    await assertHasFix('''
import 'dart:async';
import 'package:meta/meta.dart';
void f() async {
  g();
}

@awaitNotRequired
Future<int> g() async => 7;
''');
  }
}
