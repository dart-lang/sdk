// Copyright (c) 2023, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// ignore_for_file: file_names
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../rule_test_support.dart';

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(NoRuntimeTypeToStringTest);
  });
}

@reflectiveTest
class NoRuntimeTypeToStringTest extends LintRuleTest {
  @override
  String get lintRule => LintNames.no_runtimetype_tostring;

  test_extension_onAbstractClass() async {
    await assertNoDiagnostics(r'''
abstract class C {}
extension E on C {
  String f() => '$runtimeType';
}
''');
  }

  test_extension_onClass() async {
    await assertDiagnosticsFromMarkup(r'''
class C {}
extension E on C {
  String f() => '$[!runtimeType!]';
}
''');
  }

  test_inAbstractClass() async {
    await assertNoDiagnostics(r'''
abstract class C {
  void f() {
    '$runtimeType';
  }
}
''');
  }

  test_inCatchClause() async {
    await assertNoDiagnostics(r'''
class C {
  void f() {
    try {} catch (e) {
      '${runtimeType}';
    }
  }
}
''');
  }

  test_inMixin() async {
    await assertNoDiagnostics(r'''
mixin M {
  void f() {
    '$runtimeType';
  }
}
''');
  }

  test_interpolation_expression() async {
    await assertNoDiagnostics(r'''
int x = 1;
class C {
  void f() {
    '${x.runtimeType}';
  }
}
''');
  }

  test_interpolation_implicitThis() async {
    await assertDiagnosticsFromMarkup(r'''
class C {
  void f() {
    '$[!runtimeType!]';
  }
}
''');
  }

  test_interpolation_withBraces() async {
    await assertDiagnosticsFromMarkup(r'''
class C {
  void f() {
    '${[!runtimeType!]}';
  }
}
''');
  }

  test_inThrowExpression() async {
    await assertNoDiagnostics(r'''
class C {
  void f() {
    throw '${runtimeType}';
  }
}
''');
  }

  test_localVariableNamedRuntimeType() async {
    await assertNoDiagnostics(r'''
class C {
  void f() {
    var runtimeType = 'C';
    print('$runtimeType');
  }
}
''');
  }

  test_noToString() async {
    await assertNoDiagnostics(r'''
class C {
  void f() {
    runtimeType == runtimeType;
  }
}
''');
  }

  test_toString_explicitThis() async {
    await assertDiagnosticsFromMarkup(r'''
class C {
  void f() {
    this.runtimeType.[!toString!]();
  }
}
''');
  }

  test_toString_expression() async {
    await assertNoDiagnostics(r'''
int x = 1;
class C {
  void f() {
    x.runtimeType.toString();
  }
}
''');
  }

  test_toString_expression_nullAware() async {
    await assertNoDiagnostics(r'''
class C {
  void f(int? p) {
    p?.runtimeType.toString();
  }
}
''');
  }

  test_toString_super() async {
    await assertDiagnosticsFromMarkup(r'''
class C {
  void f() {
    super.runtimeType.[!toString!]();
  }
}
''');
  }
}
