// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/error/codes.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../dart/resolution/context_collection_resolution.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(UnusedImportTest);
  });
}

@reflectiveTest
class UnusedImportTest extends PubPackageResolutionTest {
  test_library_annotationOnDirective() async {
    newFile('$testPackageLibPath/lib1.dart', r'''
class A {
  const A() {}
}
''');
    await assertNoErrorsInCode(r'''
@A()
import 'lib1.dart';
''');
  }

  test_library_core_library() async {
    await assertNoErrorsInCode(r'''
import 'dart:core';
''');
  }

  test_library_export() async {
    newFile('$testPackageLibPath/lib1.dart', r'''
export 'lib2.dart';
class One {}
''');
    newFile('$testPackageLibPath/lib2.dart', r'''
class Two {}
''');
    await assertNoErrorsInCode(r'''
import 'lib1.dart';
Two two = Two();
''');
  }

  test_library_export2() async {
    newFile('$testPackageLibPath/lib1.dart', r'''
export 'lib2.dart';
class One {}
''');
    newFile('$testPackageLibPath/lib2.dart', r'''
export 'lib3.dart';
class Two {}
''');
    newFile('$testPackageLibPath/lib3.dart', r'''
class Three {}
''');
    await assertNoErrorsInCode(r'''
import 'lib1.dart';
Three? three;
''');
  }

  test_library_export_infiniteLoop() async {
    newFile('$testPackageLibPath/lib1.dart', r'''
export 'lib2.dart';
class One {}
''');
    newFile('$testPackageLibPath/lib2.dart', r'''
export 'lib3.dart';
class Two {}
''');
    newFile('$testPackageLibPath/lib3.dart', r'''
export 'lib2.dart';
class Three {}
''');
    await assertNoErrorsInCode(r'''
import 'lib1.dart';
Two? two;
''');
  }

  test_library_extension_instance_call() async {
    newFile('$testPackageLibPath/lib1.dart', r'''
extension E on int {
  int call(int x) => 0;
}
''');
    await assertNoErrorsInCode('''
import 'lib1.dart';

f() {
  7(9);
}
''');
  }

  test_library_extension_instance_getter() async {
    newFile('$testPackageLibPath/lib1.dart', r'''
extension E on String {
  String get empty => '';
}
''');
    await assertNoErrorsInCode('''
import 'lib1.dart';

f() {
  ''.empty;
}
''');
  }

  test_library_extension_instance_getter_fromObjectPattern() async {
    newFile('$testPackageLibPath/a.dart', r'''
extension E on int {
  bool get foo => true;
}
''');

    await assertNoErrorsInCode('''
import 'a.dart';

void f(Object? x) {
  if (x case int(foo: true)) {}
}
''');
  }

  test_library_extension_instance_indexRead() async {
    newFile('$testPackageLibPath/a.dart', r'''
extension E on int {
  int operator[](_) => 0;
}
''');
    await assertNoErrorsInCode('''
import 'a.dart';

void f() {
  0[1];
}
''');
  }

  test_library_extension_instance_indexReadWrite() async {
    newFile('$testPackageLibPath/a.dart', r'''
extension E on int {
  int operator[](_) => 0;
  void operator[]=(_, __) {}
}
''');
    await assertNoErrorsInCode('''
import 'a.dart';

void f() {
  0[1] += 2;
}
''');
  }

  test_library_extension_instance_indexWrite() async {
    newFile('$testPackageLibPath/a.dart', r'''
extension E on int {
  void operator[]=(_, __) {}
}
''');
    await assertNoErrorsInCode('''
import 'a.dart';

void f() {
  0[1] = 2;
}
''');
  }

  test_library_extension_instance_method() async {
    newFile('$testPackageLibPath/lib1.dart', r'''
extension E on String {
  String empty() => '';
}
''');
    await assertNoErrorsInCode('''
import 'lib1.dart';

f() {
  ''.empty();
}
''');
  }

  test_library_extension_instance_method_inPart() async {
    newFile('$testPackageLibPath/a.dart', r'''
extension E on int {
  void foo() {}
}
''');

    var b = newFile('$testPackageLibPath/b.dart', r'''
import 'a.dart';
part 'c.dart';
''');

    var c = newFile('$testPackageLibPath/c.dart', r'''
part of 'b.dart';

void f() {
  0.foo();
}
''');

    await assertErrorsInFile2(b, []);
    await assertErrorsInFile2(c, []);
  }

  test_library_extension_instance_operator_binary() async {
    newFile('$testPackageLibPath/lib1.dart', r'''
extension E on String {
  String operator -(String s) => this;
}
''');
    await assertNoErrorsInCode('''
import 'lib1.dart';

f() {
  'abc' - 'c';
}
''');
  }

  test_library_extension_instance_operator_unary() async {
    newFile('$testPackageLibPath/lib1.dart', r'''
extension E on String {
  void operator -() {}
}
''');
    await assertNoErrorsInCode('''
import 'lib1.dart';

f() {
  -'abc';
}
''');
  }

  test_library_extension_instance_setter() async {
    newFile('$testPackageLibPath/lib1.dart', r'''
extension E on String {
  void set foo(int i) {}
}
''');
    await assertNoErrorsInCode('''
import 'lib1.dart';

f() {
  'abc'.foo = 2;
}
''');
  }

  test_library_extension_override_getter() async {
    newFile('$testPackageLibPath/lib1.dart', r'''
extension E on String {
  String get empty => '';
}
''');
    await assertNoErrorsInCode('''
import 'lib1.dart';

f() {
  E('').empty;
}
''');
  }

  test_library_extension_prefixed_isUsed() async {
    newFile('$testPackageLibPath/lib1.dart', r'''
extension E on String {
  String empty() => '';
}
''');
    await assertNoErrorsInCode('''
import 'lib1.dart' as lib1;

f() {
  ''.empty();
}
''');
  }

  test_library_extension_prefixed_notUsed() async {
    newFile('$testPackageLibPath/lib1.dart', r'''
extension E on String {
  String empty() => '';
}
''');
    await assertErrorsInCode('''
import 'lib1.dart' as lib1;
''', [
      error(WarningCode.UNUSED_IMPORT, 7, 11),
    ]);
  }

  test_library_extension_static_field() async {
    newFile('$testPackageLibPath/lib1.dart', r'''
extension E on String {
  static const String empty = '';
}
''');
    await assertNoErrorsInCode('''
import 'lib1.dart';

f() {
  E.empty;
}
''');
  }

  test_library_hide() async {
    newFile('$testPackageLibPath/lib1.dart', r'''
class A {}
''');
    await assertErrorsInCode(r'''
import 'lib1.dart';
import 'lib1.dart' hide A;
A? a;
''', [
      error(WarningCode.UNUSED_IMPORT, 27, 11),
    ]);
  }

  test_library_inComment_libraryDirective() async {
    await assertNoErrorsInCode(r'''
/// Use [Future] class.
import 'dart:async';
''');
  }

  test_library_metadata() async {
    newFile('$testPackageLibPath/lib1.dart', r'''
const x = 0;
''');
    await assertNoErrorsInCode(r'''
@A(x)
import 'lib1.dart';
class A {
  final int value;
  const A(this.value);
}
''');
  }

  test_library_multipleExtensions() async {
    newFile('$testPackageLibPath/lib1.dart', r'''
extension E on String {
  String a() => '';
}
''');
    newFile('$testPackageLibPath/lib2.dart', r'''
extension E on String {
  String b() => '';
}
''');
    await assertErrorsInCode('''
import 'lib1.dart';
import 'lib2.dart';

f() {
  ''.b();
}
''', [
      error(WarningCode.UNUSED_IMPORT, 7, 11),
    ]);
  }

  test_library_noPrefix_constructorName_name() async {
    await assertErrorsInCode(r'''
import 'dart:async';

class A {
  A.foo();
}

void f() {
  A.foo();
}
''', [
      error(WarningCode.UNUSED_IMPORT, 7, 12),
    ]);
  }

  test_library_noPrefix_named_argument() async {
    await assertErrorsInCode(r'''
import 'dart:math';

void f() {
  Duration(seconds: 0);
}
''', [
      error(WarningCode.UNUSED_IMPORT, 7, 11),
    ]);
  }

  test_library_prefixed() async {
    newFile('$testPackageLibPath/lib1.dart', r'''
class A {}
''');
    await assertErrorsInCode(r'''
import 'lib1.dart';
import 'lib1.dart' as one;
one.A a = one.A();
''', [
      error(WarningCode.UNUSED_IMPORT, 7, 11),
    ]);
  }

  test_library_prefixed_commentReference_prefix() async {
    await assertNoErrorsInCode(r'''
import 'dart:math' as math;

/// [math]
void f() {}
''');
  }

  test_library_prefixed_commentReference_prefixClass() async {
    await assertNoErrorsInCode(r'''
import 'dart:math' as math;

/// [math.Random]
void f() {}
''');
  }

  test_library_prefixed_samePrefix_notUsed() async {
    newFile('$testPackageLibPath/lib1.dart', r'''
class A {}
''');
    newFile('$testPackageLibPath/lib2.dart', r'''
class B {}
''');
    await assertErrorsInCode(r'''
import 'lib1.dart' as one;
import 'lib2.dart' as one;
one.A a = one.A();
''', [
      error(WarningCode.UNUSED_IMPORT, 34, 11),
    ]);
  }

  test_library_prefixed_samePrefix_referenced() async {
    newFile('$testPackageLibPath/lib1.dart', r'''
class A {}
''');
    newFile('$testPackageLibPath/lib2.dart', r'''
class B {}
''');
    await assertNoErrorsInCode(r'''
import 'lib1.dart' as one;
import 'lib2.dart' as one;
one.A a = one.A();
one.B b = one.B();
''');
  }

  test_library_prefixed_samePrefix_referenced_via_export() async {
    newFile('$testPackageLibPath/lib1.dart', r'''
class A {}
''');
    newFile('$testPackageLibPath/lib2.dart', r'''
class B {}
''');
    newFile('$testPackageLibPath/lib3.dart', r'''
export 'lib2.dart';
''');
    await assertNoErrorsInCode(r'''
import 'lib1.dart' as one;
import 'lib3.dart' as one;
one.A a = one.A();
one.B b = one.B();
''');
  }

  test_library_prefixed_show_multipleElements() async {
    newFile('$testPackageLibPath/lib1.dart', r'''
class A {}
class B {}
''');
    await assertNoErrorsInCode(r'''
import 'lib1.dart' as one show A, B;
one.A a = one.A();
one.B b = one.B();
''');
  }

  test_library_prefixed_showTopLevelFunction() async {
    newFile('$testPackageLibPath/lib1.dart', r'''
class One {}
topLevelFunction() {}
''');
    await assertErrorsInCode(r'''
import 'lib1.dart' hide topLevelFunction;
import 'lib1.dart' as one show topLevelFunction;
class A {
  static void x() {
    One o;
    one.topLevelFunction();
  }
}
''', [
      error(WarningCode.UNUSED_LOCAL_VARIABLE, 129, 1),
    ]);
  }

  test_library_prefixed_showTopLevelFunction_multipleDirectives() async {
    newFile('$testPackageLibPath/lib1.dart', r'''
class One {}
topLevelFunction() {}
''');
    await assertNoErrorsInCode(r'''
import 'lib1.dart' hide topLevelFunction;
import 'lib1.dart' as one show topLevelFunction;
import 'lib1.dart' as two show topLevelFunction;
class A {
  static void x(One o) {
    one.topLevelFunction();
    two.topLevelFunction();
  }
}
''');
  }

  test_library_prefixed_systemLibrary() async {
    newFile('$testPackageLibPath/a.dart', '''
class File {}
''');
    await assertErrorsInCode(r'''
import 'dart:io' as prefix;
import 'a.dart' as prefix;
prefix.File? f;
''', [
      error(WarningCode.UNUSED_IMPORT, 7, 9),
    ]);
  }

  test_library_show() async {
    newFile('$testPackageLibPath/lib1.dart', r'''
class A {}
class B {}
''');
    await assertErrorsInCode(r'''
import 'lib1.dart' show A;
import 'lib1.dart' show B;
A a = A();
''', [
      error(WarningCode.UNUSED_IMPORT, 34, 11),
    ]);
  }

  test_library_systemLibrary() async {
    newFile('$testPackageLibPath/lib1.dart', '''
class File {}
''');
    await assertErrorsInCode(r'''
import 'dart:io';
import 'lib1.dart';
File? f;
''', [
      error(WarningCode.UNUSED_IMPORT, 7, 9),
    ]);
  }

  test_library_unusedImport() async {
    newFile('$testPackageLibPath/lib1.dart', '');
    await assertErrorsInCode(r'''
import 'lib1.dart';
''', [
      error(WarningCode.UNUSED_IMPORT, 7, 11),
    ]);
  }

  test_part_extension_usedLibraryImport() async {
    newFile('$testPackageLibPath/x.dart', r'''
extension E on int {
  void foo() {}
}
''');

    var a = newFile('$testPackageLibPath/a.dart', r'''
import 'x.dart';
part 'b.dart';
''');

    var b = newFile('$testPackageLibPath/b.dart', r'''
part of 'a.dart';
void f() {
  0.foo();
}
''');

    await assertErrorsInFile2(a, []);
    await assertErrorsInFile2(b, []);
  }

  test_part_extension_usedPartImport() async {
    newFile('$testPackageLibPath/x.dart', r'''
extension E on int {
  void foo() {}
}
''');

    var a = newFile('$testPackageLibPath/a.dart', r'''
part 'b.dart';
''');

    var b = newFile('$testPackageLibPath/b.dart', r'''
part of 'a.dart';
import 'x.dart';
void f() {
  0.foo();
}
''');

    await assertErrorsInFile2(a, []);
    await assertErrorsInFile2(b, []);
  }

  test_part_extension_usedPartImport_inNestedPart() async {
    newFile('$testPackageLibPath/x.dart', r'''
extension E on int {
  void foo() {}
}
''');

    var a = newFile('$testPackageLibPath/a.dart', r'''
part 'b.dart';
''');

    var b = newFile('$testPackageLibPath/b.dart', r'''
part of 'a.dart';
import 'x.dart';
part 'c.dart';
''');

    var c = newFile('$testPackageLibPath/c.dart', r'''
part of 'b.dart';
void f() {
  0.foo();
}
''');

    await assertErrorsInFile2(a, []);
    await assertErrorsInFile2(b, []);
    await assertErrorsInFile2(c, []);
  }

  test_part_notUsedPartImport() async {
    var a = newFile('$testPackageLibPath/a.dart', r'''
part 'b.dart';
''');

    var b = newFile('$testPackageLibPath/b.dart', r'''
part of 'a.dart';
import 'dart:math';
''');

    await assertErrorsInFile2(a, []);

    await assertErrorsInFile2(b, [
      error(WarningCode.UNUSED_IMPORT, 25, 11),
    ]);
  }

  test_part_usedLibraryImport() async {
    var a = newFile('$testPackageLibPath/a.dart', r'''
import 'dart:math';
part 'b.dart';
''');

    var b = newFile('$testPackageLibPath/b.dart', r'''
part of 'a.dart';
void f(Random _) {}
''');

    await assertErrorsInFile2(a, []);
    await assertErrorsInFile2(b, []);
  }

  test_part_usedLibraryImport_usedPartImport() async {
    var a = newFile('$testPackageLibPath/a.dart', r'''
import 'dart:math';
part 'b.dart';
''');

    var b = newFile('$testPackageLibPath/b.dart', r'''
part of 'a.dart';
import 'dart:async';
void f(Random _, Future<int> _) {}
''');

    await assertErrorsInFile2(a, []);
    await assertErrorsInFile2(b, []);
  }

  test_part_usedPartImport() async {
    var a = newFile('$testPackageLibPath/a.dart', r'''
part 'b.dart';
''');

    var b = newFile('$testPackageLibPath/b.dart', r'''
part of 'a.dart';
import 'dart:math';
void f(Random _) {}
''');

    await assertErrorsInFile2(a, []);
    await assertErrorsInFile2(b, []);
  }

  test_part_usedPartImport_inNestedPart() async {
    var a = newFile('$testPackageLibPath/a.dart', r'''
part 'b.dart';
''');

    var b = newFile('$testPackageLibPath/b.dart', r'''
part of 'a.dart';
import 'dart:math';
part 'c.dart';
''');

    var c = newFile('$testPackageLibPath/c.dart', r'''
part of 'b.dart';
void f(Random _) {}
''');

    await assertErrorsInFile2(a, []);
    await assertErrorsInFile2(b, []);
    await assertErrorsInFile2(c, []);
  }

  test_part_usedPartImport_notUsedLibraryImport() async {
    var a = newFile('$testPackageLibPath/a.dart', r'''
import 'dart:math';
part 'b.dart';
''');

    var b = newFile('$testPackageLibPath/b.dart', r'''
part of 'a.dart';
import 'dart:math';
void f(Random _) {}
''');

    await assertErrorsInFile2(a, [
      error(WarningCode.UNUSED_IMPORT, 7, 11),
    ]);

    await assertErrorsInFile2(b, []);
  }
}
