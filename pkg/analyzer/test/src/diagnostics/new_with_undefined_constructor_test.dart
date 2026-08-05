// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../dart/resolution/context_collection_resolution.dart';
import '../dart/resolution/node_text_expectations.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(NewWithUndefinedConstructorTest);
    defineReflectiveTests(
      NewWithUndefinedConstructorWithoutConstructorTearoffsTest,
    );
    defineReflectiveTests(UpdateNodeTextExpectations);
  });
}

@reflectiveTest
class NewWithUndefinedConstructorTest extends PubPackageResolutionTest
    with NewWithUndefinedConstructorTestCases {}

mixin NewWithUndefinedConstructorTestCases on PubPackageResolutionTest {
  test_default() async {
    await resolveTestCodeWithDiagnostics('''
class A {
  A.name() {}
}
f() {
  new A();
//    ^
// [diag.newWithUndefinedConstructorDefault] The class 'A' doesn't have an unnamed constructor.
}
''');
  }

  test_default_noKeyword() async {
    await resolveTestCodeWithDiagnostics('''
class A {
  A.name() {}
}
f() {
  A();
//^
// [diag.newWithUndefinedConstructorDefault] The class 'A' doesn't have an unnamed constructor.
}
''');
  }

  test_default_prefixed() async {
    newFile('$testPackageLibPath/lib1.dart', '''
class A {
  A.name() {}
}
''');
    await resolveTestCodeWithDiagnostics('''
import 'lib1.dart' as lib1;

f() {
  new lib1.A();
//    ^^^^^^
// [diag.newWithUndefinedConstructorDefault] The class 'lib1.A' doesn't have an unnamed constructor.
}
''');
  }

  test_default_unnamedViaNew() async {
    await resolveTestCodeWithDiagnostics('''
class A {
  A.name() {}
}
f() {
  A.new();
//  ^^^
// [diag.newWithUndefinedConstructorDefault] The class 'A' doesn't have an unnamed constructor.
}
''');
  }

  test_defaultViaNew() async {
    await resolveTestCodeWithDiagnostics('''
class A {
  A.new() {}
}
f() {
  A();
}
''');
  }

  test_defined_named() async {
    await resolveTestCodeWithDiagnostics(r'''
class A {
  A.name() {}
}
f() {
  new A.name();
}
''');
  }

  test_defined_unnamed() async {
    await resolveTestCodeWithDiagnostics(r'''
class A {
  A() {}
}
f() {
  new A();
}
''');
  }

  test_named() async {
    await resolveTestCodeWithDiagnostics('''
class A {
  A() {}
}
f() {
  new A.name();
//      ^^^^
// [diag.newWithUndefinedConstructor] The class 'A' doesn't have a constructor named 'name'.
}
''');
  }

  test_named_prefixed() async {
    newFile('$testPackageLibPath/lib1.dart', '''
class A {
  A() {}
}
''');
    await resolveTestCodeWithDiagnostics('''
import 'lib1.dart' as lib1;
f() {
  new lib1.A.name();
//           ^^^^
// [diag.newWithUndefinedConstructor] The class 'lib1.A' doesn't have a constructor named 'name'.
}
''');
  }

  test_private_named() async {
    newFile('$testPackageLibPath/a.dart', r'''
class A {
  A._named() {}
}
''');
    await resolveTestCodeWithDiagnostics(r'''
import 'a.dart';
void f() {
  new A._named();
//      ^^^^^^
// [diag.newWithUndefinedConstructor] The class 'A' doesn't have a constructor named '_named'.
}
''');
  }

  test_private_named_genericClass_noTypeArguments() async {
    newFile('$testPackageLibPath/a.dart', r'''
class A<T> {
  A._named() {}
}
''');
    await resolveTestCodeWithDiagnostics(r'''
import 'a.dart';
void f() {
  new A._named();
//      ^^^^^^
// [diag.newWithUndefinedConstructor] The class 'A' doesn't have a constructor named '_named'.
}
''');
  }

  test_private_named_genericClass_withTypeArguments() async {
    newFile('$testPackageLibPath/a.dart', r'''
class A<T> {
  A._named() {}
}
''');
    await resolveTestCodeWithDiagnostics(r'''
import 'a.dart';
void f() {
  new A<int>._named();
//           ^^^^^^
// [diag.newWithUndefinedConstructor] The class 'A' doesn't have a constructor named '_named'.
}
''');
  }
}

@reflectiveTest
class NewWithUndefinedConstructorWithoutConstructorTearoffsTest
    extends PubPackageResolutionTest
    with WithoutConstructorTearoffsMixin {
  test_defaultViaNew() async {
    await resolveTestCodeWithDiagnostics('''
class A {
  A.new() {}
//  ^^^
// [diag.experimentNotEnabled] This requires the 'constructor-tearoffs' language feature to be enabled.
}
f() {
  A();
}
''');
  }

  test_unnamedViaNew() async {
    await resolveTestCodeWithDiagnostics('''
class A {
  A.named() {}
}
f() {
  A.new();
//  ^^^
// [diag.experimentNotEnabled] This requires the 'constructor-tearoffs' language feature to be enabled.
}
''');
  }
}
