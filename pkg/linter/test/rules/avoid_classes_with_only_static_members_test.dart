// Copyright (c) 2023, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../rule_test_support.dart';

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(AvoidClassesWithOnlyStaticMembers);
  });
}

@reflectiveTest
class AvoidClassesWithOnlyStaticMembers extends LintRuleTest {
  @override
  String get lintRule => LintNames.avoid_classes_with_only_static_members;

  test_augmentationClass_nonStaticField() async {
    // The added field should prevent a lint in 'test.dart'.
    var b = newFile('$testPackageLibPath/b.dart', r'''
part of 'test.dart';

augment class A {
  int a = 1;
}
''');

    await assertNoDiagnostics(r'''
part 'b.dart';

class A {
  static int f = 1;
}
''');
    await assertNoDiagnosticsInFile(b.path);
  }

  test_augmentationClass_staticField() async {
    var b = newFile('$testPackageLibPath/b.dart', r'''
part of 'test.dart';

augment class A {
  static int f = 1;
}
''');

    await assertDiagnosticsFromMarkup(r'''
part 'b.dart';

class [!A!] {}
''');
    await assertNoDiagnosticsInFile(b.path);
  }

  test_augmentationClass_staticMethod() async {
    var b = newFile('$testPackageLibPath/b.dart', r'''
part of 'test.dart';

augment class A {
  static void m() {}
}
''');

    await assertDiagnosticsFromMarkup(r'''
part 'b.dart';

class [!A!] {}
''');
    await assertNoDiagnosticsInFile(b.path);
  }

  test_basicClass() async {
    await assertDiagnosticsFromMarkup(r'''
class [!C!] {
  static void f() {}
}
''');
  }

  test_class_empty() async {
    await assertNoDiagnostics(r'''
class C {}
''');
  }

  test_class_empty_augmentation_empty() async {
    newFile('$testPackageLibPath/b.dart', r'''
part of 'test.dart';

augment class A {}
''');

    await assertNoDiagnostics(r'''
part 'b.dart';

class A {}
''');
  }

  test_class_extendingValidClass() async {
    await assertNoDiagnostics(r'''
class A {
  int f = 1;
}

class C extends A {
  static int i = 0;
  static m() {}
}
''');
  }

  test_class_noPublicConstructor() async {
    await assertNoDiagnostics(r'''
class C {
  C._();
  static int f = 0;
}
''');
  }

  test_class_withConstructor() async {
    await assertNoDiagnostics(r'''
class C {
  C();
}
''');
  }

  test_class_withGenericSuper() async {
    // https://github.com/dart-lang/sdk/issues/57022
    await assertNoDiagnostics(r'''
class A<T> {
  void m() {}
}
class C extends A<Object> { }
''');
  }

  test_class_withInstanceField() async {
    await assertNoDiagnostics(r'''
class C {
  int a = 0;
}
''');
  }

  test_class_withInstanceMethod() async {
    await assertNoDiagnostics(r'''
class C {
  void m() {}
}
''');
  }

  test_class_withStaticConstFields() async {
    await assertNoDiagnostics(r'''
class C {
  static const red = '#f00';
  static const green = '#0f0';
  static const blue = '#00f';
}
''');
  }

  test_finalClass() async {
    await assertDiagnosticsFromMarkup(r'''
final class [!C!] {
  static void f() {}
}
''');
  }

  test_sealedClass() async {
    await assertNoDiagnostics(r'''
sealed class C {
  static void f() {}
}
''');
  }
}
