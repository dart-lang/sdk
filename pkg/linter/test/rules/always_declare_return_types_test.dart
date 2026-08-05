// Copyright (c) 2024, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../rule_test_support.dart';

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(AlwaysDeclareReturnTypesTest);
  });
}

@reflectiveTest
class AlwaysDeclareReturnTypesTest extends LintRuleTest {
  @override
  String get lintRule => LintNames.always_declare_return_types;

  test_augmentationClass() async {
    var a = newFile('$testPackageLibPath/a.dart', r'''
part 'test.dart';

class A { }
''');

    await assertDiagnosticsFromMarkup(r'''
part of 'a.dart';

augment class A {
  [!f!]() { }
}
''');
    await assertNoDiagnosticsInFile(a.path);
  }

  test_augmentationTopLevelFunction() async {
    var a = newFile('$testPackageLibPath/a.dart', r'''
part 'test.dart';
''');

    await assertDiagnosticsFromMarkup(r'''
part of 'a.dart';

[!f!]() { }
''');
    await assertNoDiagnosticsInFile(a.path);
  }

  /// Augmentation target chain variations tested in
  /// `augmentedTopLevelFunction{*}`.
  test_augmentedMethod() async {
    var b = newFile('$testPackageLibPath/b.dart', r'''
part of 'test.dart';

augment class A {
  augment f();
}
''');

    await assertDiagnosticsFromMarkup(r'''
part 'b.dart';

class A {
  [!f!]() { }
}
''');
    await assertNoDiagnosticsInFile(b.path);
  }

  test_augmentedTopLevelFunction() async {
    var b = newFile('$testPackageLibPath/b.dart', r'''
part of 'test.dart';

augment f();
''');

    await assertDiagnosticsFromMarkup(r'''
part 'b.dart';

[!f!]() { }
''');
    await assertNoDiagnosticsInFile(b.path);
  }

  test_augmentedTopLevelFunction_chain() async {
    var b = newFile('$testPackageLibPath/b.dart', r'''
part of 'test.dart';

augment dynamic f();
augment f();
''');

    await assertDiagnosticsFromMarkup(r'''
part 'b.dart';

[!f!]() { }
''');
    await assertNoDiagnosticsInFile(b.path);
  }

  test_extensionMethod() async {
    await assertDiagnosticsFromMarkup(r'''
extension E on int {
  [!f!]() {}
}
''');
  }

  test_instanceSetter() async {
    await assertNoDiagnostics(r'''
class C {
  set f(int p) {}
}
''');
  }

  test_method_expressionBody() async {
    await assertDiagnosticsFromMarkup(r'''
class C {
  [!f!]() => 42;
}
''');
  }

  test_method_testUnderscore_notInPubPackageTest_hasReturnType() async {
    await assertNoDiagnostics(r'''
class A {
  void test_foo() {}
}
''');
  }

  test_method_testUnderscore_notInPubPackageTest_noReturnType() async {
    await assertDiagnosticsFromMarkup(r'''
class A {
  [!test_foo!]() {}
}
''');
  }

  test_method_withReturnType() async {
    await assertNoDiagnostics(r'''
class C {
  int f() => 42;
}
''');
  }

  test_operator_binary() async {
    await assertDiagnosticsFromMarkup(r'''
class C {
  operator [!+!](C c) => c;
}
''');
  }

  test_operator_binary_withReturnType() async {
    await assertNoDiagnostics(r'''
class C {
  C operator +(C c) => c;
}
''');
  }

  test_operator_indexAssignment() async {
    await assertNoDiagnostics(r'''
class C {
  operator []=(int index, int value) {}
}
''');
  }

  test_pubPackageTest_method_notTest_hasReturnType() async {
    await assertNoDiagnosticsInTestDir(r'''
class MyTest {
  void foo() {}
}
''');
  }

  test_pubPackageTest_method_notTest_noReturnType() async {
    await assertDiagnosticsInTestDirFromMarkup(r'''
class MyTest {
  [!foo!]() {}
}
''');
  }

  test_pubPackageTest_method_soloTest_noReturnType() async {
    await assertNoDiagnosticsInTestDir(r'''
class MyTest {
  solo_test_foo() {}
}
''');
  }

  test_pubPackageTest_method_test_hasReturnType() async {
    await assertNoDiagnosticsInTestDir(r'''
class MyTest {
  void test_foo() {}
}
''');
  }

  test_pubPackageTest_method_test_noReturnType() async {
    await assertNoDiagnosticsInTestDir(r'''
class MyTest {
  test_foo() {}
}
''');
  }

  test_staticSetter() async {
    await assertNoDiagnostics(r'''
class C {
  static set f(int p) {}
}
''');
  }

  test_topLevelFunction_blockBody_withReturnType() async {
    await assertNoDiagnostics(r'''
int f() => 7;
''');
  }

  test_topLevelFunction_expressionBody() async {
    await assertDiagnosticsFromMarkup(r'''
[!f!]() => 7;
''');
  }

  test_topLevelFunction_expressionBody_withReturnType() async {
    await assertNoDiagnostics(r'''
void f() { }
''');
  }

  test_topLevelFunction_noReturn() async {
    await assertDiagnosticsFromMarkup(r'''
[!f!]() {}
''');
  }

  test_topLevelSetter() async {
    await assertNoDiagnostics(r'''
set f(int p) {}
''');
  }

  test_typedef_oldStyle() async {
    await assertDiagnosticsFromMarkup(r'''
typedef [!t!](int x);
''');
  }

  test_typedef_oldStyle_withReturnType() async {
    await assertNoDiagnostics(r'''
typedef bool t(int x);
''');
  }
}
