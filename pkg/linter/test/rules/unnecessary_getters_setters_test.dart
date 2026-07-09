// Copyright (c) 2023, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../rule_test_support.dart';

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(UnnecessaryGettersSettersTest);
  });
}

@reflectiveTest
class UnnecessaryGettersSettersTest extends LintRuleTest {
  @override
  String get lintRule => LintNames.unnecessary_getters_setters;

  test_necessary_differentType() async {
    await assertNoDiagnostics(r'''
class C {
  String? _x;

  dynamic get x {
    return _x;
  }
  set x(dynamic value) {
    _x = value;
  }
}
''');
  }

  test_necessary_hasAnnotation() async {
    await assertNoDiagnostics(r'''
class C {
  String? _x;

  @Annotation()
  String? get x => _x;
  set x(String? value) {
    _x = value;
  }
}

class Annotation {
  const Annotation();
}
''');
  }

  test_necessary_nonTrivialSetter() async {
    await assertNoDiagnostics(r'''
class C {
  String? _x;

  String? get x => _x;
  set x(String? value) {
    _x = value?.toLowerCase();
  }
}
''');
  }

  test_necessary_nullAwareAssignment() async {
    await assertNoDiagnostics(r'''
class C {
  String? _x;

  String? get x => _x;
  set x(String? value) {
    _x ??= value;
  }
}
''');
  }

  @FailingTest(issue: 'https://github.com/dart-lang/linter/issues/4935')
  // TODO(scheglov): implement augmentation
  test_unnecessary_augmentationAddedGetterAndSetter() async {
    var b = newFile('$testPackageLibPath/b.dart', r'''
part of 'test.dart';

augment class A {
  String? _x;

  String? get x => _x;
  set x(String? value) {
    _x = value;
  }
}
''');
    // TODO(pq): in the absence of accessors in the augmented class, report on
    //  the class decl?
    await assertDiagnosticsFromMarkup(r'''
part 'b.dart';

class [!A!] {}
''');
    await assertNoDiagnosticsInFile(b.path);
  }

  @FailingTest(issue: 'https://github.com/dart-lang/linter/issues/4935')
  // TODO(scheglov): implement augmentation
  test_unnecessary_augmentationAddedSetter() async {
    var b = newFile('$testPackageLibPath/b.dart', r'''
part of 'test.dart';

augment class A {
  set x(String? value) {
    _x = value;
  }
}
''');

    await assertDiagnosticsFromMarkup(r'''
part 'b.dart';

class A {
  String? _x;

  String? get [!x!] => _x;
}
''');
    await assertNoDiagnosticsInFile(b.path);
  }

  test_unnecessary_getterAndSetter_extensionType() async {
    await assertDiagnosticsFromMarkup(r'''
extension type E(int i) {
  static int? _x;
  static int? get [!x!] => _x;
  static set x(int? value) {
    _x = value;
  }
}
''');
  }

  test_unnecessary_getterAndSetterHaveBlockBody() async {
    await assertDiagnosticsFromMarkup(r'''
class C {
  String? _x;

  String? get [!x!] {
    return _x;
  }
  set x(String? value) {
    _x = value;
  }
}
''');
  }

  test_unnecessary_getterHasExpressionBody() async {
    await assertDiagnosticsFromMarkup(r'''
class C {
  String? _x;

  String? get [!x!] => _x;
  set x(String? value)
  {
    _x = value;
  }
}
''');
  }

  test_unnecessary_setterHasExpressionBody() async {
    await assertDiagnosticsFromMarkup(r'''
class C {
  String? _x;

  String? get [!x!] {
    return _x;
  }
  set x(String? value) => _x = value;
}
''');
  }
}
