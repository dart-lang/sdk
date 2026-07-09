// Copyright (c) 2024, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../dart/resolution/context_collection_resolution.dart';
import '../dart/resolution/node_text_expectations.dart';

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(InvalidDoNotSubmitMemberTest);
    defineReflectiveTests(UpdateNodeTextExpectations);
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
    var a = getFile('$testPackageLibPath/a.dart');
    var b = getFile('$testPackageLibPath/b.dart');
    await resolveFileWithDiagnostics(a, r'''
import 'package:meta/meta.dart';

class A {
  @doNotSubmit
  A();
}
''');

    await resolveFileWithDiagnostics(b, r'''
import 'a.dart';

void b() {
  A();
//^
// [diag.invalidUseOfDoNotSubmitMember] Uses of 'A' should not be submitted to source control.
}
''');
  }

  test_constructor_primary() async {
    var a = getFile('$testPackageLibPath/a.dart');
    var b = getFile('$testPackageLibPath/b.dart');
    await resolveFileWithDiagnostics(a, r'''
import 'package:meta/meta.dart';

class A() {
  @doNotSubmit
  this;
}
''');

    await resolveFileWithDiagnostics(b, r'''
import 'a.dart';

var a = A();
//      ^
// [diag.invalidUseOfDoNotSubmitMember] Uses of 'A' should not be submitted to source control.
''');
  }

  test_constructorFactory() async {
    var a = getFile('$testPackageLibPath/a.dart');
    var b = getFile('$testPackageLibPath/b.dart');
    await resolveFileWithDiagnostics(a, r'''
import 'package:meta/meta.dart';

class A {
  @doNotSubmit
  factory A() => A._();
  A._();
}
''');

    await resolveFileWithDiagnostics(b, r'''
import 'a.dart';

void b() {
  A();
//^
// [diag.invalidUseOfDoNotSubmitMember] Uses of 'A' should not be submitted to source control.
}
''');
  }

  test_exceptionDoNotSubmitMethodReferencingAnotherDoNotSubmitMethod() async {
    var a = getFile('$testPackageLibPath/a.dart');
    var b = getFile('$testPackageLibPath/b.dart');
    await resolveFileWithDiagnostics(a, r'''
import 'package:meta/meta.dart';

@doNotSubmit
void a() {}
''');

    await resolveFileWithDiagnostics(b, r'''
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
  }

  test_exceptionParameterFromParentFunction() async {
    var a = getFile('$testPackageLibPath/a.dart');
    await resolveFileWithDiagnostics(a, r'''
import 'package:meta/meta.dart';

void a({@doNotSubmit int? a}) {
  var c = () {
    print(a);
  };
  c();
}
''');
  }

  test_exceptionParameterFromSameFunction() async {
    var a = getFile('$testPackageLibPath/a.dart');
    await resolveFileWithDiagnostics(a, r'''
import 'package:meta/meta.dart';

void a({@doNotSubmit int? a}) {
  print(a);
}
''');
  }

  test_exceptionParameterFromSameMethod() async {
    var a = getFile('$testPackageLibPath/a.dart');
    await resolveFileWithDiagnostics(a, r'''
import 'package:meta/meta.dart';

class A {
  @doNotSubmit
  void a({int? a}) {
    print(a);
  }
}
''');
  }

  test_extensionGetter() async {
    var a = getFile('$testPackageLibPath/a.dart');
    var b = getFile('$testPackageLibPath/b.dart');
    await resolveFileWithDiagnostics(a, r'''
import 'package:meta/meta.dart';

extension A on int {
  @doNotSubmit
  int get a => 0;
}
''');

    await resolveFileWithDiagnostics(b, r'''
import 'a.dart';

void b() {
  print(0.a);
//        ^
// [diag.invalidUseOfDoNotSubmitMember] Uses of 'a' should not be submitted to source control.
}
''');
  }

  test_extensionMethod() async {
    var a = getFile('$testPackageLibPath/a.dart');
    var b = getFile('$testPackageLibPath/b.dart');
    await resolveFileWithDiagnostics(a, r'''
import 'package:meta/meta.dart';

extension A on int {
  @doNotSubmit
  void a() {}
}
''');

    await resolveFileWithDiagnostics(b, r'''
import 'a.dart';

void b() {
  0.a();
//  ^
// [diag.invalidUseOfDoNotSubmitMember] Uses of 'a' should not be submitted to source control.
}
''');
  }

  test_extensionSetter() async {
    var a = getFile('$testPackageLibPath/a.dart');
    var b = getFile('$testPackageLibPath/b.dart');
    await resolveFileWithDiagnostics(a, r'''
import 'package:meta/meta.dart';

extension A on int {
  @doNotSubmit
  set a(int value) {}
}
''');

    await resolveFileWithDiagnostics(b, r'''
import 'a.dart';

void b() {
  0.a = 0;
//  ^
// [diag.invalidUseOfDoNotSubmitMember] Uses of 'a' should not be submitted to source control.
}
''');
  }

  test_function() async {
    var a = getFile('$testPackageLibPath/a.dart');
    var b = getFile('$testPackageLibPath/b.dart');
    await resolveFileWithDiagnostics(a, r'''
import 'package:meta/meta.dart';

@doNotSubmit
void a() {}
''');

    await resolveFileWithDiagnostics(b, r'''
import 'a.dart';

void b() => a();
//          ^
// [diag.invalidUseOfDoNotSubmitMember] Uses of 'a' should not be submitted to source control.
''');
  }

  test_getter() async {
    var a = getFile('$testPackageLibPath/a.dart');
    var b = getFile('$testPackageLibPath/b.dart');
    await resolveFileWithDiagnostics(a, r'''
import 'package:meta/meta.dart';

class A {
  @doNotSubmit
  int get a => 0;
}
''');

    await resolveFileWithDiagnostics(b, r'''
import 'a.dart';

void b() {
  var a = A();
  print(a.a);
//        ^
// [diag.invalidUseOfDoNotSubmitMember] Uses of 'a' should not be submitted to source control.
}
''');
  }

  test_invalidTargetOfClass() async {
    var a = getFile('$testPackageLibPath/a.dart');
    var b = getFile('$testPackageLibPath/b.dart');
    await resolveFileWithDiagnostics(a, r'''
import 'package:meta/meta.dart';

@doNotSubmit
// [diag.invalidAnnotationTarget][column 2][length 11] The annotation 'doNotSubmit' can only be used on constructors, getters, methods, optional parameters, setters, top-level functions, or top-level variables.
class A {}
''');

    await resolveFileWithDiagnostics(b, r'''
import 'a.dart';

void b() {
  A();
//^
// [diag.invalidUseOfDoNotSubmitMember] Uses of 'A' should not be submitted to source control.
}
''');
  }

  test_method() async {
    var a = getFile('$testPackageLibPath/a.dart');
    var b = getFile('$testPackageLibPath/b.dart');
    await resolveFileWithDiagnostics(a, r'''
import 'package:meta/meta.dart';

class A {
  @doNotSubmit
  void a() {}
}
''');

    await resolveFileWithDiagnostics(b, r'''
import 'a.dart';

void b() {
  var a = A();
  a.a();
//  ^
// [diag.invalidUseOfDoNotSubmitMember] Uses of 'a' should not be submitted to source control.
}
''');
  }

  test_namedParameter() async {
    var a = getFile('$testPackageLibPath/a.dart');
    var b = getFile('$testPackageLibPath/b.dart');
    await resolveFileWithDiagnostics(a, r'''
import 'package:meta/meta.dart';

void a({@doNotSubmit int? p}) {}
''');

    await resolveFileWithDiagnostics(b, r'''
import 'a.dart';

void b() {
  a(p: 0);
//  ^
// [diag.invalidUseOfDoNotSubmitMember] Uses of 'p' should not be submitted to source control.
}
''');
  }

  test_parameter_inPrimaryConstructor() async {
    var a = getFile('$testPackageLibPath/a.dart');
    var b = getFile('$testPackageLibPath/b.dart');
    await resolveFileWithDiagnostics(a, r'''
import 'package:meta/meta.dart';

class A([@doNotSubmit int x = 0]);
''');

    await resolveFileWithDiagnostics(b, r'''
import 'a.dart';

var a = A(1);
//        ^
// [diag.invalidUseOfDoNotSubmitMember] Uses of 'x' should not be submitted to source control.
''');
  }

  test_positionalParameter() async {
    var a = getFile('$testPackageLibPath/a.dart');
    var b = getFile('$testPackageLibPath/b.dart');
    await resolveFileWithDiagnostics(a, r'''
import 'package:meta/meta.dart';

void a([@doNotSubmit int? p]) {}
''');

    await resolveFileWithDiagnostics(b, r'''
import 'a.dart';

void b() {
  a(0);
//  ^
// [diag.invalidUseOfDoNotSubmitMember] Uses of 'p' should not be submitted to source control.
}
''');
  }

  test_sameLibrary() async {
    var a = getFile('$testPackageLibPath/a.dart');
    await resolveFileWithDiagnostics(a, r'''
import 'package:meta/meta.dart';

@doNotSubmit
void a() {}

void b() => a();
//          ^
// [diag.invalidUseOfDoNotSubmitMember] Uses of 'a' should not be submitted to source control.
''');
  }

  test_setter() async {
    var a = getFile('$testPackageLibPath/a.dart');
    var b = getFile('$testPackageLibPath/b.dart');
    await resolveFileWithDiagnostics(a, r'''
import 'package:meta/meta.dart';

class A {
  @doNotSubmit
  set a(int value) {}
}
''');

    await resolveFileWithDiagnostics(b, r'''
import 'a.dart';

void b() {
  var a = A();
  a.a = 0;
//  ^
// [diag.invalidUseOfDoNotSubmitMember] Uses of 'a' should not be submitted to source control.
}
''');
  }

  test_topLevelVariable() async {
    var a = getFile('$testPackageLibPath/a.dart');
    var b = getFile('$testPackageLibPath/b.dart');
    await resolveFileWithDiagnostics(a, r'''
import 'package:meta/meta.dart';

@doNotSubmit
int a = 0;
''');

    await resolveFileWithDiagnostics(b, r'''
import 'a.dart';

void b() => print(a);
//                ^
// [diag.invalidUseOfDoNotSubmitMember] Uses of 'a' should not be submitted to source control.
''');
  }
}
