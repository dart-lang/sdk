// Copyright (c) 2024, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../rule_test_support.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(AvoidFieldInitializersInConstClassesTest);
  });
}

@reflectiveTest
class AvoidFieldInitializersInConstClassesTest extends LintRuleTest {
  @override
  String get lintRule => LintNames.avoid_field_initializers_in_const_classes;

  test_augmentationClass_nonConstConstructor() async {
    var a = newFile('$testPackageLibPath/a.dart', r'''
part 'b.dart';

class A {
  final a;
  const A() : a = 1;
}
''');

    var b = newFile('$testPackageLibPath/b.dart', r'''
part of 'a.dart';

augment class A {
  A.aa() : a = 1;
}
''');

    await assertNoDiagnosticsInFile(a.path);
    await assertNoDiagnosticsInFile(b.path);
  }

  test_augmentedClass_augmentedConstructor() async {
    newFile('$testPackageLibPath/a.dart', r'''
part 'test.dart';

class A {
  const A();
  late final s;
}
''');

    await assertDiagnostics(r'''
part of 'a.dart';

augment class A {
  augment const A() : s = '';
}
''', [
      lint(59, 6),
    ]);
  }

  test_augmentedClass_augmentedField() async {
    newFile('$testPackageLibPath/a.dart', r'''
part 'test.dart';

class A {
  const A();
  final s = '';
}
''');

    await assertNoDiagnostics(r'''
part of 'a.dart';

augment class A {
  augment final s = '';
}
''');
  }

  test_augmentedClass_constructorInitializer() async {
    newFile('$testPackageLibPath/a.dart', r'''
part 'test.dart';

class A { }
''');

    await assertDiagnostics(r'''
part of 'a.dart';

augment class A {
  final a;
  const A() : a = '';
}
''', [
      lint(62, 6),
    ]);
  }

  test_augmentedClass_constructorInitializer_multipleConstructors() async {
    newFile('$testPackageLibPath/a.dart', r'''
part 'test.dart';

class A {
  A.aa();
}
''');

    await assertNoDiagnostics(r'''
part of 'a.dart';

augment class A {
  final a;
  const A() : a = '';
}
''');
  }

  test_augmentedClass_field() async {
    newFile('$testPackageLibPath/a.dart', r'''
part 'test.dart';

class A {
  const A();
}
''');

    await assertDiagnostics(r'''
part of 'a.dart';

augment class A {
  final s = '';
}
''', [
      lint(45, 6),
    ]);
  }
}
