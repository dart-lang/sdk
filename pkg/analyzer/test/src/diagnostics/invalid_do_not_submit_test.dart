// Copyright (c) 2024, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/error/codes.g.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../dart/resolution/context_collection_resolution.dart';

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(InvalidDoNotSubmitMemberTest);
  });
}

@reflectiveTest
class InvalidDoNotSubmitMemberTest extends PubPackageResolutionTest {
  @override
  String get testPackageRootPath => '/home/my';

  @override
  void setUp() {
    super.setUp();
    writeTestPackageConfigWithMeta();
  }

  test_constructor() async {
    var a = newFile('$testPackageLibPath/a.dart', r'''
import 'package:meta/meta.dart';

class A {
  @doNotSubmit
  A();
}
''');

    var b = newFile('$testPackageLibPath/b.dart', r'''
import 'a.dart';

void b() {
  A();
}
''');

    await assertErrorsInFile2(a, []);
    await assertErrorsInFile2(b, [
      error(WarningCode.invalid_use_of_do_not_submit_member, 31, 1),
    ]);
  }

  test_constructorFactory() async {
    var a = newFile('$testPackageLibPath/a.dart', r'''
import 'package:meta/meta.dart';

class A {
  @doNotSubmit
  factory A() => A._();
  A._();
}
''');

    var b = newFile('$testPackageLibPath/b.dart', r'''
import 'a.dart';

void b() {
  A();
}
''');

    await assertErrorsInFile2(a, []);
    await assertErrorsInFile2(b, [
      error(WarningCode.invalid_use_of_do_not_submit_member, 31, 1),
    ]);
  }

  test_exceptionDoNotSubmitMethodReferencingAnotherDoNotSubmitMethod() async {
    var a = newFile('$testPackageLibPath/a.dart', r'''
import 'package:meta/meta.dart';

@doNotSubmit
void a() {}
''');

    var b = newFile('$testPackageLibPath/b.dart', r'''
import 'package:meta/meta.dart';

import 'a.dart';

@doNotSubmit
void b() {
  // OK.
  a();

  // Also OK in a closure.
  () {
    a();
  };

  // Also OK in a block.
  if (true) {
    a();
  }
}
''');

    await assertErrorsInFile2(a, []);
    await assertErrorsInFile2(b, []);
  }

  test_exceptionParameterFromParentFunction() async {
    var a = newFile('$testPackageLibPath/a.dart', r'''
import 'package:meta/meta.dart';

void a({@doNotSubmit int? a}) {
  var c = () {
    print(a);
  };
  c();
}
''');

    await assertErrorsInFile2(a, []);
  }

  test_exceptionParameterFromSameFunction() async {
    var a = newFile('$testPackageLibPath/a.dart', r'''
import 'package:meta/meta.dart';

void a({@doNotSubmit int? a}) {
  print(a);
}
''');

    await assertErrorsInFile2(a, []);
  }

  test_exceptionParameterFromSameMethod() async {
    var a = newFile('$testPackageLibPath/a.dart', r'''
import 'package:meta/meta.dart';

class A {
  @doNotSubmit
  void a({int? a}) {
    print(a);
  }
}
''');

    await assertErrorsInFile2(a, []);
  }

  test_extensionGetter() async {
    var a = newFile('$testPackageLibPath/a.dart', r'''
import 'package:meta/meta.dart';

extension A on int {
  @doNotSubmit
  int get a => 0;
}
''');

    var b = newFile('$testPackageLibPath/b.dart', r'''
import 'a.dart';

void b() {
  print(0.a);
}
''');

    await assertErrorsInFile2(a, []);
    await assertErrorsInFile2(b, [
      error(WarningCode.invalid_use_of_do_not_submit_member, 39, 1),
    ]);
  }

  test_extensionMethod() async {
    var a = newFile('$testPackageLibPath/a.dart', r'''
import 'package:meta/meta.dart';

extension A on int {
  @doNotSubmit
  void a() {}
}
''');

    var b = newFile('$testPackageLibPath/b.dart', r'''
import 'a.dart';

void b() {
  0.a();
}
''');

    await assertErrorsInFile2(a, []);
    await assertErrorsInFile2(b, [
      error(WarningCode.invalid_use_of_do_not_submit_member, 33, 1),
    ]);
  }

  test_extensionSetter() async {
    var a = newFile('$testPackageLibPath/a.dart', r'''
import 'package:meta/meta.dart';

extension A on int {
  @doNotSubmit
  set a(int value) {}
}
''');

    var b = newFile('$testPackageLibPath/b.dart', r'''
import 'a.dart';

void b() {
  0.a = 0;
}
''');

    await assertErrorsInFile2(a, []);
    await assertErrorsInFile2(b, [
      error(WarningCode.invalid_use_of_do_not_submit_member, 33, 1),
    ]);
  }

  test_function() async {
    var a = newFile('$testPackageLibPath/a.dart', r'''
import 'package:meta/meta.dart';

@doNotSubmit
void a() {}
''');

    var b = newFile('$testPackageLibPath/b.dart', r'''
import 'a.dart';

void b() => a();
''');

    await assertErrorsInFile2(a, []);
    await assertErrorsInFile2(b, [
      error(WarningCode.invalid_use_of_do_not_submit_member, 30, 1),
    ]);
  }

  test_getter() async {
    var a = newFile('$testPackageLibPath/a.dart', r'''
import 'package:meta/meta.dart';

class A {
  @doNotSubmit
  int get a => 0;
}
''');

    var b = newFile('$testPackageLibPath/b.dart', r'''
import 'a.dart';

void b() {
  var a = A();
  print(a.a);
}
''');

    await assertErrorsInFile2(a, []);
    await assertErrorsInFile2(b, [
      error(WarningCode.invalid_use_of_do_not_submit_member, 54, 1),
    ]);
  }

  test_invalidTargetOfClass() async {
    var a = newFile('$testPackageLibPath/a.dart', r'''
import 'package:meta/meta.dart';

@doNotSubmit
class A {}
''');

    var b = newFile('$testPackageLibPath/b.dart', r'''
import 'a.dart';

void b() {
  A();
}
''');

    await assertErrorsInFile2(a, [
      error(WarningCode.INVALID_ANNOTATION_TARGET, 35, 11),
    ]);
    await assertErrorsInFile2(b, []);
  }

  test_method() async {
    var a = newFile('$testPackageLibPath/a.dart', r'''
import 'package:meta/meta.dart';

class A {
  @doNotSubmit
  void a() {}
}
''');

    var b = newFile('$testPackageLibPath/b.dart', r'''
import 'a.dart';

void b() {
  var a = A();
  a.a();
}
''');

    await assertErrorsInFile2(a, []);
    await assertErrorsInFile2(b, [
      error(WarningCode.invalid_use_of_do_not_submit_member, 48, 1),
    ]);
  }

  test_namedParameter() async {
    var a = newFile('$testPackageLibPath/a.dart', r'''
import 'package:meta/meta.dart';

void a({@doNotSubmit int? a}) {}
''');

    var b = newFile('$testPackageLibPath/b.dart', r'''
import 'a.dart';

void b() {
  a(a: 0);
}
''');

    await assertErrorsInFile2(a, []);
    await assertErrorsInFile2(b, [
      error(WarningCode.invalid_use_of_do_not_submit_member, 33, 1),
    ]);
  }

  test_positionalParameter() async {
    var a = newFile('$testPackageLibPath/a.dart', r'''
import 'package:meta/meta.dart';

void a([@doNotSubmit int? a]) {}
''');

    var b = newFile('$testPackageLibPath/b.dart', r'''
import 'a.dart';

void b() {
  a(0);
}
''');

    await assertErrorsInFile2(a, []);
    await assertErrorsInFile2(b, [
      error(WarningCode.invalid_use_of_do_not_submit_member, 33, 1),
    ]);
  }

  test_sameLibrary() async {
    var a = newFile('$testPackageLibPath/a.dart', r'''
import 'package:meta/meta.dart';

@doNotSubmit
void a() {}

void b() => a();
''');

    await assertErrorsInFile2(a, [
      error(WarningCode.invalid_use_of_do_not_submit_member, 72, 1),
    ]);
  }

  test_setter() async {
    var a = newFile('$testPackageLibPath/a.dart', r'''
import 'package:meta/meta.dart';

class A {
  @doNotSubmit
  set a(int value) {}
}
''');

    var b = newFile('$testPackageLibPath/b.dart', r'''
import 'a.dart';

void b() {
  var a = A();
  a.a = 0;
}
''');

    await assertErrorsInFile2(a, []);
    await assertErrorsInFile2(b, [
      error(WarningCode.invalid_use_of_do_not_submit_member, 48, 1),
    ]);
  }

  test_topLevelVarable() async {
    var a = newFile('$testPackageLibPath/a.dart', r'''
import 'package:meta/meta.dart';

@doNotSubmit
int a = 0;
''');

    var b = newFile('$testPackageLibPath/b.dart', r'''
import 'a.dart';

void b() => print(a);
''');

    await assertErrorsInFile2(a, []);
    await assertErrorsInFile2(b, [
      error(WarningCode.invalid_use_of_do_not_submit_member, 36, 1),
    ]);
  }
}
