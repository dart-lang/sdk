// Copyright (c) 2022, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../rule_test_support.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(AnnotateOverridesTest);
  });
}

@reflectiveTest
class AnnotateOverridesTest extends LintRuleTest {
  @override
  String get lintRule => 'annotate_overrides';

  @FailingTest(
    reason:
        '`augmented.hasOverride` not implemented yet (https://github.com/dart-lang/sdk/issues/55579)',
    issue: 'https://github.com/dart-lang/linter/issues/4925',
  )
  test_augmentationClass_implementsInterface() async {
    var a = newFile('$testPackageLibPath/a.dart', r'''
import augment 'b.dart';

abstract interface class HasLength {
  int get length;
}

class C {
  int get length => 42;
}
''');

    // TODO(pq): update getter to be abstract when supported.
    var b = newFile('$testPackageLibPath/b.dart', r'''
augment library 'a.dart';

augment class C implements HasLength {
  @override
  augment int get length => 42;
}
''');

    result = await resolveFile(a.path);
    await assertNoDiagnosticsIn(errors);

    result = await resolveFile(b.path);
    await assertNoDiagnosticsIn(errors);
  }

  test_augmentationClass_methodWithoutAnnotation() async {
    newFile('$testPackageLibPath/a.dart', r'''
import augment 'test.dart';

class A {
  void a() {}
}

class B extends A { }
''');

    await assertDiagnostics(r'''
augment library 'a.dart';

augment class B {
  void a() {}
}
''', [
      lint(52, 1),
    ]);
  }

  test_augmentationMethodWithAnnotation() async {
    newFile('$testPackageLibPath/a.dart', r'''
import augment 'test.dart';

class A {
  void a() {}
}

class B extends A {
  @override
  void a() {}
}
''');

    await assertNoDiagnostics(r'''
augment library 'a.dart';

augment class B {
  augment void a() {}
}
''');
  }

  test_class_fieldWithAnnotation() async {
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

  // TODO(srawlins): Test subclassing via `implements`, via mixing-in, and via
  // superconstraints.
  // Test that extension methods don't need an annotation.
  // Test setters and operators.

  test_class_fieldWithoutAnnotation() async {
    await assertDiagnostics(r'''
class A {
  int get x => 4;
}

class B extends A {
  int x = 5;
}
''', [
      lint(57, 1),
    ]);
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

  test_class_getterWithoutAnnotation() async {
    await assertDiagnostics(r'''
class A {
  int get x => 4;
}

class B extends A {
  int get x => 5;
}
''', [
      lint(61, 1),
    ]);
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
    await assertDiagnostics(r'''
class A {
  void f() {}
}

class B extends A {
  void f() {}
}
''', [
      lint(54, 1),
    ]);
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
    await assertDiagnostics(r'''
class O {
  int get x => 0;
}

enum A implements O {
  a,b,c;
  int get x => 0;
}
''', [
      lint(72, 1),
    ]);
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
    await assertDiagnostics(r'''
enum A {
  a,b,c;
  String toString() => '';
}
''', [
      lint(27, 8),
    ]);
  }

  test_extensionTypes_field() async {
    await assertDiagnostics(r'''
class A {
  int i = 0;
}

extension type B(A a) implements A {
  int i = 0;
}
''', [
      // No lint.
      error(CompileTimeErrorCode.EXTENSION_TYPE_DECLARES_INSTANCE_FIELD, 69, 1),
    ]);
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
}
