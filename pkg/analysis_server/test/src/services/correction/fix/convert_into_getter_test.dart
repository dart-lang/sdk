// Copyright (c) 2025, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/src/services/correction/fix.dart';
import 'package:analyzer/src/diagnostic/diagnostic.dart' as diag;
import 'package:analyzer_plugin/utilities/fixes/fixes.dart';
import 'package:linter/src/lint_names.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../fix/fix_processor.dart';

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(ExtensionInstanceFieldFixTest);
    defineReflectiveTests(ExtensionTypeInstanceFieldFixTest);
    defineReflectiveTests(ImplicitThisInInitializerFixTest);
  });
}

@reflectiveTest
class ExtensionInstanceFieldFixTest extends FixProcessorTest {
  @override
  FixKind get kind => DartFixKind.convertIntoGetter;

  Future<void> test_final() async {
    await resolveTestCode('''
extension E on int {
  final int a;
}
''');
    await assertHasFix(
      '''
extension E on int {
  int get a => null;
}
''',
      filter: (error) =>
          error.diagnosticCode == diag.extensionDeclaresInstanceField,
    );
  }

  Future<void> test_late() async {
    await resolveTestCode('''
extension E on int {
  late int a = 0;
}
''');
    await assertHasFix('''
extension E on int {
  int get a => 0;
}
''');
  }

  Future<void> test_late_final() async {
    await resolveTestCode('''
extension E on int {
  late final int a = 0;
}
''');
    await assertHasFix('''
extension E on int {
  int get a => 0;
}
''');
  }

  Future<void> test_nonFinal_nonLate() async {
    await resolveTestCode('''
extension E on int {
  int a = 0;
}
''');
    await assertHasFix('''
extension E on int {
  int get a => 0;
}
''');
  }

  Future<void> test_notSingleField() async {
    await resolveTestCode('''
extension E on int {
  final int foo = 1, bar = 2;
}
''');
    await assertNoFix(
      filter: (error) => error.offset == testCode.indexOf('foo'),
    );
    await assertNoFix(
      filter: (error) => error.offset == testCode.indexOf('bar'),
    );
  }
}

@reflectiveTest
class ExtensionTypeInstanceFieldFixTest extends FixProcessorTest {
  @override
  FixKind get kind => DartFixKind.convertIntoGetter;

  Future<void> test_final() async {
    await resolveTestCode('''
extension type A(int i) {
  final int a;
}
''');
    await assertHasFix('''
extension type A(int i) {
  int get a => null;
}
''');
  }

  Future<void> test_late() async {
    await resolveTestCode('''
extension type A(int i) {
  late int a = 0;
}
''');
    await assertHasFix('''
extension type A(int i) {
  int get a => 0;
}
''');
  }

  Future<void> test_late_final() async {
    await resolveTestCode('''
extension type A(int i) {
  late final int a = 0;
}
''');
    await assertHasFix('''
extension type A(int i) {
  int get a => 0;
}
''');
  }

  Future<void> test_nonFinal_nonLate() async {
    await resolveTestCode('''
extension type A(int i) {
  int a = 0;
}
''');
    await assertHasFix('''
extension type A(int i) {
  int get a => 0;
}
''');
  }

  Future<void> test_notSingleField() async {
    await resolveTestCode('''
extension type A(int i) {
  final int foo = 1, bar = 2;
}
''');
    await assertNoFix(
      filter: (error) => error.offset == testCode.indexOf('foo'),
    );
    await assertNoFix(
      filter: (error) => error.offset == testCode.indexOf('bar'),
    );
  }
}

@reflectiveTest
class ImplicitThisInInitializerFixTest extends FixProcessorTest {
  @override
  FixKind get kind => DartFixKind.convertIntoGetter;

  Future<void> test_final() async {
    await resolveTestCode('''
class A {
  final int v;
  final bool isEven = v.isEven;
  A(this.v);
}
''');
    await assertHasFix('''
class A {
  final int v;
  bool get isEven => v.isEven;
  A(this.v);
}
''');
  }

  Future<void> test_type() async {
    await resolveTestCode('''
class A {
  final int v;
  bool isEven = v.isEven;
  A(this.v);
}
''');
    await assertHasFix('''
class A {
  final int v;
  bool get isEven => v.isEven;
  A(this.v);
}
''');
  }

  Future<void> test_var() async {
    await resolveTestCode('''
class A {
  final int v;
  var isEven = v.isEven;
  A(this.v);
}
''');
    await assertHasFix('''
class A {
  final int v;
  bool get isEven => v.isEven;
  A(this.v);
}
''');
  }

  Future<void> test_var_noStaticType() async {
    await resolveTestCode('''
class A {
  final int v;
  var isEven = v.;
  A(this.v);
}
''');
    await assertHasFix(
      '''
class A {
  final int v;
  get isEven => v.;
  A(this.v);
}
''',
      filter: (error) {
        return error.diagnosticCode == diag.implicitThisReferenceInInitializer;
      },
    );
  }

  Future<void> test_var_noStaticType_lintReturnTypes() async {
    createAnalysisOptionsFile(lints: [LintNames.always_declare_return_types]);
    await resolveTestCode('''
class A {
  final int v;
  var isEven = v.;
  A(this.v);
}
''');
    await assertHasFix(
      '''
class A {
  final int v;
  dynamic get isEven => v.;
  A(this.v);
}
''',
      filter: (error) {
        return error.diagnosticCode == diag.implicitThisReferenceInInitializer;
      },
    );
  }

  Future<void> test_var_noStaticType_lintTypes() async {
    createAnalysisOptionsFile(lints: [LintNames.always_specify_types]);
    await resolveTestCode('''
class A {
  final int v;
  var isEven = v.;
  A(this.v);
}
''');
    await assertHasFix(
      '''
class A {
  final int v;
  dynamic get isEven => v.;
  A(this.v);
}
''',
      filter: (error) {
        return error.diagnosticCode == diag.implicitThisReferenceInInitializer;
      },
    );
  }
}
