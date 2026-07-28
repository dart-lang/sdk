// Copyright (c) 2022, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/diagnostic/diagnostic.dart' as diag;
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../rule_test_support.dart';

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(AnnotateOverridesTest);
  });
}

@reflectiveTest
class AnnotateOverridesTest extends LintRuleTest {
  @override
  String get lintRule => LintNames.annotate_overrides;

  test_augmentationClass_implementsInterface() async {
    var a = newFile('$testPackageLibPath/a.dart', r'''
part 'b.dart';

abstract interface class HasLength {
  int get length;
}

abstract interface class C {
  int get length;
}
''');

    // TODO(pq): update getter to be abstract when supported.
    var b = newFile('$testPackageLibPath/b.dart', r'''
part of 'a.dart';

augment abstract interface class C implements HasLength {
  @override
  augment int get length => 42;
}
''');

    await assertNoDiagnosticsInFile(a.path);
    await assertNoDiagnosticsInFile(b.path);
  }

  test_augmentationClass_methodWithoutAnnotation() async {
    newFile('$testPackageLibPath/a.dart', r'''
part 'test.dart';

class A {
  void a() {}
}

class B extends A { }
''');

    await assertDiagnosticsFromMarkup(r'''
part of 'a.dart';

augment class B {
  void [!a!]() {}
}
''');
  }

  test_augmentationMethodWithAnnotation() async {
    newFile('$testPackageLibPath/a.dart', r'''
part 'test.dart';

class A {
  void a() {}
}

class B extends A {
  @override
  void a() {}
}
''');

    await assertNoDiagnostics(r'''
part of 'a.dart';

augment class B {
  augment void a();
}
''');
  }

  test_class_declaringParameter_withAnnotation() async {
    await assertNoDiagnostics(r'''
class A {
  int get x => 4;
}

class B(@override var int x) extends A {}
''');
  }

  test_class_declaringParameter_withoutAnnotation() async {
    await assertDiagnosticsFromMarkup(r'''
class A {
  int get x => 4;
}

class B(var int [!x!]) extends A {}
''');
  }

  test_class_field_withAnnotation() async {
    await assertNoDiagnostics(r'''
class A {
  int get x => 4;
}

class B extends A {
  @override
  int x = 5;
}
''');
  }

  test_class_field_withoutAnnotation() async {
    await assertDiagnosticsFromMarkup(r'''
class A {
  int get x => 4;
}

class B extends A {
  int [!x!] = 5;
}
''');
  }

  test_class_getterWithAnnotation() async {
    await assertNoDiagnostics(r'''
class A {
  int get x => 4;
}

class B extends A {
  @override
  int get x => 5;
}
''');
  }

  test_class_getterWithAnnotation_setter_doesNotOverride() async {
    await assertNoDiagnostics(r'''
class A {
  int get x => 4;
}

class B extends A {
  @override
  int get x => 5;

  set x(int _) {}
}
''');
  }

  test_class_getterWithoutAnnotation() async {
    await assertDiagnosticsFromMarkup(r'''
class A {
  int get x => 4;
}

class B extends A {
  int get [!x!] => 5;
}
''');
  }

  test_class_implementsClass_withoutAnnotation() async {
    await assertDiagnosticsFromMarkup(r'''
abstract class C {
  void m();
}

class D implements C {
  void [!m!]() {}
}
''');
  }

  test_class_methodWithAnnotation() async {
    await assertNoDiagnostics(r'''
class A {
  void f() {}
}

class B extends A {
  @override
  f() {}
}
''');
  }

  test_class_methodWithoutAnnotation() async {
    await assertDiagnosticsFromMarkup(r'''
class A {
  void f() {}
}

class B extends A {
  void [!f!]() {}
}
''');
  }

  test_class_withMixin_withoutAnnotation() async {
    await assertDiagnosticsFromMarkup(r'''
mixin M {
  void m() {}
}

class C with M {
  void [!m!]() {}
}
''');
  }

  test_enum_declaringParameter_withAnnotation() async {
    await assertNoDiagnostics(r'''
enum E(@override final int x) implements I {
  e(0)
}

class I {
  int get x => 4;
}
''');
  }

  test_enum_declaringParameter_withoutAnnotation() async {
    await assertDiagnosticsFromMarkup(r'''
enum E(final int [!x!]) implements I {
  e(0)
}

class I {
  int get x => 4;
}
''');
  }

  test_enum_fieldWithAnnotation() async {
    await assertNoDiagnostics(r'''
class O {
  int get x => 0;
}

enum A implements O {
  a,b,c;
  @override
  int get x => 0;
}
''');
  }

  test_enum_fieldWithoutAnnotation() async {
    await assertDiagnosticsFromMarkup(r'''
class O {
  int get x => 0;
}

enum A implements O {
  a,b,c;
  int get [!x!] => 0;
}
''');
  }

  test_enum_methodWithAnnotation() async {
    await assertNoDiagnostics(r'''
class O {
  int m() => 0;
}

enum A implements O {
  a,b,c;
  @override
  int m() => 0;
}
''');
  }

  test_enum_methodWithoutAnnotation() async {
    await assertDiagnosticsFromMarkup(r'''
enum A {
  a,b,c;
  String [!toString!]() => '';
}
''');
  }

  test_extension_method_withoutAnnotation() async {
    await assertNoDiagnostics(r'''
extension E on Object {
  void extensionMethod() {}
}
''');
  }

  test_extensionTypes_field() async {
    await assertDiagnostics(
      r'''
class A {
  int i = 0;
}

extension type B(A a) implements A {
  int i = 0;
}
''',
      [
        // No lint.
        error(diag.extensionTypeDeclaresInstanceField, 69, 1),
      ],
    );
  }

  test_extensionTypes_getter() async {
    await assertNoDiagnostics(r'''
class A {
  int i = 0;
}

extension type E(A a) implements A {
  int get i => 1;
}
''');
  }

  test_extensionTypes_method() async {
    await assertNoDiagnostics(r'''
class A {
  void m() { }
}

extension type E(A a) implements A {
  void m() { }
}
''');
  }

  test_extensionTypes_setter() async {
    await assertNoDiagnostics(r'''
class A {
  int i = 0;
}

extension type E(A a) implements A {
  set i(int i) {}
}
''');
  }

  test_mixin_superConstraint_withoutAnnotation() async {
    await assertDiagnosticsFromMarkup(r'''
class A {
  void m() {}
}

mixin M on A {
  void [!m!]() {}
}
''');
  }

  test_operator_withoutAnnotation() async {
    await assertDiagnosticsFromMarkup(r'''
class A {
  @override
  bool operator ==(Object other) => false;
}

class B extends A {
  bool operator [!==!](Object other) => true;
}
''');
  }

  test_setter_withoutAnnotation() async {
    await assertDiagnosticsFromMarkup(r'''
class A {
  set x(int value) {}
}

class B extends A {
  set [!x!](int value) {}
}
''');
  }
}
