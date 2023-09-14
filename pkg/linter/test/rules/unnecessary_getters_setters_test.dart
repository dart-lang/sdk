// Copyright (c) 2023, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../rule_test_support.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(UnnecessaryGettersSettersTest);
  });
}

@reflectiveTest
class UnnecessaryGettersSettersTest extends LintRuleTest {
  @override
  List<String> get experiments => ['inline-class'];

  @override
  String get lintRule => 'unnecessary_getters_setters';

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

  test_unnecessary_getterAndSetter_extensionType() async {
    await assertDiagnostics(r'''
extension type E(int i) {
  static int? _x;
  static int? get x => _x;
  static set x(int? value) {
    _x = value;
  }
}
''', [
      lint(62, 1),
    ]);
  }

  test_unnecessary_getterAndSetterHaveBlockBody() async {
    await assertDiagnostics(r'''
class C {
  String? _x;

  String? get x {
    return _x;
  }
  set x(String? value) {
    _x = value;
  }
}
''', [
      lint(39, 1),
    ]);
  }

  test_unnecessary_getterHasExpressionBody() async {
    await assertDiagnostics(r'''
class C {
  String? _x;

  String? get x => _x;
  set x(String? value)
  {
    _x = value;
  }
}
''', [
      lint(39, 1),
    ]);
  }

  test_unnecessary_setterHasExpressionBody() async {
    await assertDiagnostics(r'''
class C {
  String? _x;

  String? get x {
    return _x;
  }
  set x(String? value) => _x = value;
}
''', [
      lint(39, 1),
    ]);
  }
}
