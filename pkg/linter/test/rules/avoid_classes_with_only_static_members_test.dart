// Copyright (c) 2023, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../rule_test_support.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(AvoidClassesWithOnlyStaticMembers);
  });
}

@reflectiveTest
class AvoidClassesWithOnlyStaticMembers extends LintRuleTest {
  @override
  String get lintRule => LintNames.avoid_classes_with_only_static_members;

  test_augmentationClass_nonStaticField() async {
    var a = newFile('$testPackageLibPath/a.dart', r'''
part 'b.dart';

class A {
  static int f = 1;
}
''');

    // The added field should prevent a lint above.
    var b = newFile('$testPackageLibPath/b.dart', r'''
part of 'a.dart';

augment class A {
  int a = 1;
}
''');

    result = await resolveFile(a.path);
    await assertNoDiagnosticsIn(errors);

    result = await resolveFile(b.path);
    await assertNoDiagnosticsIn(errors);
  }

  test_augmentationClass_staticField() async {
    var a = newFile('$testPackageLibPath/a.dart', r'''
part 'b.dart';

class A {}
''');

    var b = newFile('$testPackageLibPath/b.dart', r'''
part of 'a.dart';

augment class A {
  static int f = 1;
}
''');

    result = await resolveFile(a.path);
    await assertDiagnosticsIn(errors, [
      lint(16, 10),
    ]);

    result = await resolveFile(b.path);
    await assertNoDiagnosticsIn(errors);
  }

  test_augmentationClass_staticMethod() async {
    var a = newFile('$testPackageLibPath/a.dart', r'''
part 'b.dart';

class A {}
''');

    var b = newFile('$testPackageLibPath/b.dart', r'''
part of 'a.dart';

augment class A {
  static void m() {}
}
''');

    result = await resolveFile(a.path);
    await assertDiagnosticsIn(errors, [
      lint(16, 10),
    ]);

    result = await resolveFile(b.path);
    await assertNoDiagnosticsIn(errors);
  }

  test_basicClass() async {
    await assertDiagnostics(r'''
class C {
  static void f() {}
}
''', [
      lint(0, 32),
    ]);
  }

  test_class_empty() async {
    await assertNoDiagnostics(r'''
class C {}
''');
  }

  test_class_empty_augmentation_empty() async {
    var a = newFile('$testPackageLibPath/a.dart', r'''
part 'b.dart';

class A {}
''');

    var b = newFile('$testPackageLibPath/b.dart', r'''
part of 'a.dart';

augment class A {}
''');

    result = await resolveFile(a.path);
    await assertNoDiagnosticsIn(errors);

    result = await resolveFile(b.path);
    await assertNoDiagnosticsIn(errors);
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
    await assertDiagnostics(r'''
final class C {
  static void f() {}
}
''', [
      lint(0, 38),
    ]);
  }

  test_sealedClass() async {
    await assertNoDiagnostics(r'''
sealed class C {
  static void f() {}
}
''');
  }
}
