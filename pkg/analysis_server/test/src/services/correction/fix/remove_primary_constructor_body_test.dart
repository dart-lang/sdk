// Copyright (c) 2026, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/src/services/correction/fix.dart';
import 'package:analyzer_plugin/utilities/fixes/fixes.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'fix_processor.dart';

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(RemovePrimaryConstructorBodyBulkTest);
    defineReflectiveTests(RemovePrimaryConstructorBodyTest);
  });
}

@reflectiveTest
class RemovePrimaryConstructorBodyBulkTest extends BulkFixProcessorTest {
  @override
  String get lintCode => LintNames.unnecessary_primary_constructor_body;

  Future<void> test_multiple() async {
    await resolveTestCode(r'''
class A(final int i) {
  this;
}
class B(final int i) {
  this {}
}
''');
    await assertHasFix(r'''
class A(final int i) {
}
class B(final int i) {
}
''');
  }
}

@reflectiveTest
class RemovePrimaryConstructorBodyTest extends FixProcessorLintTest {
  @override
  FixKind get kind => DartFixKind.removePrimaryConstructorBody;

  @override
  String get lintCode => LintNames.unnecessary_primary_constructor_body;

  Future<void> test_block() async {
    await resolveTestCode(r'''
class C(final int i) {
  this {}
}
''');
    await assertHasFix(r'''
class C(final int i) {
}
''');
  }

  Future<void> test_semicolon() async {
    await resolveTestCode(r'''
class C(final int i) {
  this;
}
''');
    await assertHasFix(r'''
class C(final int i) {
}
''');
  }
}
