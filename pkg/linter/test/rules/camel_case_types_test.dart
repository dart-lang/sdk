// Copyright (c) 2023, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../rule_test_support.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(CamelCaseTypesTest);
  });
}

@reflectiveTest
class CamelCaseTypesTest extends LintRuleTest {
  @override
  String get lintRule => LintNames.camel_case_types;

  test_augmentationClass_lowerCase() async {
    newFile('$testPackageLibPath/a.dart', r'''
part 'test.dart';

class a {}
''');

    await assertNoDiagnostics(r'''
part of 'a.dart';

augment class a {}
''');
  }

  test_augmentationEnum_lowerCase() async {
    newFile('$testPackageLibPath/a.dart', r'''
part 'test.dart';

enum e {
  a;
}
''');

    await assertNoDiagnostics(r'''
part of 'a.dart';

augment enum e {
  b;
}
''');
  }

  test_augmentationExtensionType_lowerCase() async {
    newFile('$testPackageLibPath/a.dart', r'''
part 'test.dart';

extension type et(int i) {}
''');

    await assertNoDiagnostics(r'''
part of 'a.dart';

augment extension type et(int i) {}
''');
  }

  test_augmentationMixin_lowerCase() async {
    newFile('$testPackageLibPath/a.dart', r'''
part 'test.dart';

mixin m {}
''');

    await assertNoDiagnostics(r'''
part of 'a.dart';

augment mixin m {}
''');
  }

  test_class_dollar_thenUpperCamel() async {
    await assertNoDiagnostics(r'''
class $FooBar
{}
''');
  }

  test_class_lowerCamel() async {
    await assertDiagnostics(r'''
class fooBar {}
''', [
      lint(6, 6),
    ]);
  }

  test_class_upperCamel() async {
    await assertNoDiagnostics(r'''
class FooBar {}
''');
  }

  test_class_upperCamel_private() async {
    await assertNoDiagnostics(r'''
class _Foo {} // ignore: unused_element
''');
  }

  test_class_upperCamel_withDollar() async {
    await assertNoDiagnostics(r'''
class Foo$Bar {}
''');
  }

  test_class_upperCase1() async {
    await assertNoDiagnostics(r'''
class A {}
''');
  }

  test_class_upperCase2() async {
    await assertNoDiagnostics(r'''
class AA {}
''');
  }

  test_class_upperSnake() async {
    await assertDiagnostics(r'''
class Foo_Bar {}
''', [
      lint(6, 7),
    ]);
  }

  test_enum_lowerCamel() async {
    await assertDiagnostics(r'''
enum foooBar { a }
''', [
      lint(5, 7),
    ]);
  }

  test_enum_upperCamel() async {
    await assertNoDiagnostics(r'''
enum FoooBar { a }
''');
  }

  test_extensionType_lowerCase() async {
    // No need to test all the variations. Name checking is shared with other
    // declaration types.
    await assertDiagnostics(r'''
extension type fooBar(int i) {}
''', [
      lint(15, 6),
    ]);
  }

  test_extensionType_wellFormed() async {
    await assertNoDiagnostics(r'''
extension type FooBar(int i) {}
''');
  }

  test_macroClass_lowerCase() async {
    await assertDiagnostics(r'''
macro class a {}
''', [
      lint(12, 1),
    ]);
  }

  test_mixin_lowerCase() async {
    await assertDiagnostics(r'''
mixin m {}
''', [
      lint(6, 1),
    ]);
  }

  test_mixinApplication_lower() async {
    await assertDiagnostics(r'''
mixin M {}
class c = Object with M;
''', [
      lint(17, 1),
    ]);
  }

  test_typedef_newFormat_lower() async {
    await assertDiagnostics(r'''
typedef f = void Function();
''', [
      lint(8, 1),
    ]);
  }

  test_typedef_newFormat_lowerCamel() async {
    await assertDiagnostics(r'''
class Foo {}
typedef foo = Foo;
''', [
      lint(21, 3),
    ]);
  }

  test_typedef_newFormat_upperCamel() async {
    await assertNoDiagnostics(r'''
class Foo {}
typedef F = Foo;
''');
  }

  test_typedef_oldFormat_lowerCamel() async {
    await assertDiagnostics(r'''
typedef bool predicate();
''', [
      lint(13, 9),
    ]);
  }

  test_typedef_oldFormat_upperCamel() async {
    await assertNoDiagnostics(r'''
typedef bool Predicate();
''');
  }
}
