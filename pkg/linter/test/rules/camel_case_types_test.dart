// Copyright (c) 2023, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../rule_test_support.dart';

void main() {
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

  @FailingTest(
    issue: 'https://github.com/dart-lang/sdk/issues/56174',
    reason: 'There are unexpected diagnostics.',
  )
  // TODO(scheglov): implement augmentation
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
    await assertDiagnosticsFromMarkup(r'''
class [!fooBar!] {}
''');
  }

  test_class_primaryConstructor_test_class_lowerCamel() async {
    await assertDiagnosticsFromMarkup(r'''
class [!fooBar!](var int x);
''');
  }

  test_class_primaryConstructor_upperCamel() async {
    await assertNoDiagnostics(r'''
class FooBar(var int x);
''');
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
    await assertDiagnosticsFromMarkup(r'''
class [!Foo_Bar!] {}
''');
  }

  test_enum_lowerCamel() async {
    await assertDiagnosticsFromMarkup(r'''
enum [!foooBar!] { a }
''');
  }

  test_enum_primaryConstructor_lowerCamel() async {
    await assertDiagnosticsFromMarkup(r'''
enum [!fooBar!](final String name) { a('') }
''');
  }

  test_enum_primaryConstructor_upperCamel() async {
    await assertNoDiagnostics(r'''
enum FooBar(final String name) { a('') }
''');
  }

  test_enum_upperCamel() async {
    await assertNoDiagnostics(r'''
enum FoooBar { a }
''');
  }

  test_extensionType_lowerCase() async {
    // No need to test all the variations. Name checking is shared with other
    // declaration types.
    await assertDiagnosticsFromMarkup(r'''
extension type [!fooBar!](int i) {}
''');
  }

  test_extensionType_wellFormed() async {
    await assertNoDiagnostics(r'''
extension type FooBar(int i) {}
''');
  }

  test_mixin_lowerCase() async {
    await assertDiagnosticsFromMarkup(r'''
mixin [!m!] {}
''');
  }

  test_mixinApplication_lower() async {
    await assertDiagnosticsFromMarkup(r'''
mixin M {}
class [!c!] = Object with M;
''');
  }

  test_typedef_newFormat_lower() async {
    await assertDiagnosticsFromMarkup(r'''
typedef [!f!] = void Function();
''');
  }

  test_typedef_newFormat_lowerCamel() async {
    await assertDiagnosticsFromMarkup(r'''
class Foo {}
typedef [!foo!] = Foo;
''');
  }

  test_typedef_newFormat_upperCamel() async {
    await assertNoDiagnostics(r'''
class Foo {}
typedef F = Foo;
''');
  }

  test_typedef_oldFormat_lowerCamel() async {
    await assertDiagnosticsFromMarkup(r'''
typedef bool [!predicate!]();
''');
  }

  test_typedef_oldFormat_upperCamel() async {
    await assertNoDiagnostics(r'''
typedef bool Predicate();
''');
  }
}
