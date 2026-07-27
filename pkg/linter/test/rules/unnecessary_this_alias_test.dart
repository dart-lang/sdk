// Copyright (c) 2026, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../rule_test_support.dart';

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(UnnecessaryThisAliasTest);
  });
}

@reflectiveTest
class UnnecessaryThisAliasTest extends LintRuleTest {
  @override
  String get lintRule => LintNames.unnecessary_this_alias;

  test_noDiagnostic_differentType() async {
    await assertNoDiagnostics(r'''
class C {
  void m() {
    Object self = this;
    if (self is D) {}
  }
}
class D extends C {}
''');
  }

  test_noDiagnostic_experimentDisabled() async {
    await assertNoDiagnostics(r'''
// @dart=3.13
class C {
  void m() {
    var self = this;
    if (self is D) {}
  }
}
class D extends C {}
''');
  }

  test_noDiagnostic_late() async {
    await assertNoDiagnostics(r'''
class C {
  void m() {
    late var self = this;
    if (self is D) {}
  }
}
class D extends C {}
''');
  }

  test_noDiagnostic_mutated() async {
    await assertNoDiagnostics(r'''
class C {
  void m() {
    var self = this;
    if (self is D) {}
    self = C();
  }
}
class D extends C {}
''');
  }

  test_noDiagnostic_noPromotionUsage() async {
    await assertNoDiagnostics(r'''
class C {
  void m() {
    var self = this;
    print(self);
  }
}
''');
  }

  test_noDiagnostic_notThis() async {
    await assertNoDiagnostics(r'''
class C {
  void m(C other) {
    var self = other;
    if (self is D) {}
  }
}
class D extends C {}
''');
  }

  test_thisPromotion_as() async {
    await assertDiagnosticsFromMarkup(r'''
class C {
  void m() {
    var [!self!] = this;
    (self as D).foo();
  }
}
class D extends C {
  void foo() {}
}
''');
  }

  test_thisPromotion_bang() async {
    await assertDiagnosticsFromMarkup(r'''
class C {}
extension on C? {
  void m() {
    var [!self!] = this;
    self!;
  }
}
''');
  }

  test_thisPromotion_bangEqNull() async {
    await assertDiagnosticsFromMarkup(r'''
class C {}
extension on C? {
  void m() {
    var [!self!] = this;
    if (self != null) {}
  }
}
''');
  }

  test_thisPromotion_eqEqNull() async {
    await assertDiagnosticsFromMarkup(r'''
class C {}
extension on C? {
  void m() {
    var [!self!] = this;
    if (self == null) {}
  }
}
''');
  }

  test_thisPromotion_ifCase() async {
    await assertDiagnosticsFromMarkup(r'''
class C {
  void m() {
    var [!self!] = this;
    if (self case D _) {}
  }
}
class D extends C {}
''');
  }

  test_thisPromotion_is() async {
    await assertDiagnosticsFromMarkup(r'''
class C {
  void m() {
    var [!self!] = this;
    if (self is D) {}
  }
}
class D extends C {}
''');
  }

  test_thisPromotion_isNot() async {
    await assertDiagnosticsFromMarkup(r'''
class C {
  void m() {
    var [!self!] = this;
    if (self is! D) {}
  }
}
class D extends C {}
''');
  }

  test_thisPromotion_nullBangEq() async {
    await assertDiagnosticsFromMarkup(r'''
class C {}
extension on C? {
  void m() {
    var [!self!] = this;
    if (null != self) {}
  }
}
''');
  }

  test_thisPromotion_nullEqEq() async {
    await assertDiagnosticsFromMarkup(r'''
class C {}
extension on C? {
  void m() {
    var [!self!] = this;
    if (null == self) {}
  }
}
''');
  }

  test_thisPromotion_parenthesized() async {
    await assertDiagnosticsFromMarkup(r'''
class C {
  void m() {
    var [!self!] = (this);
    if (self is D) {}
  }
}
class D extends C {}
''');
  }

  test_thisPromotion_parenthesizedUsage() async {
    await assertDiagnosticsFromMarkup(r'''
class C {}
extension on C? {
  void m() {
    var [!self!] = this;
    if ((self) == null) {}
  }
}
''');
  }

  test_thisPromotion_switch() async {
    await assertDiagnosticsFromMarkup(r'''
class C {
  void m() {
    var [!self!] = this;
    switch (self) {
      case D _:
    }
  }
}
class D extends C {}
''');
  }

  test_thisPromotion_switchExpr() async {
    await assertDiagnosticsFromMarkup(r'''
class C {
  void m(C self) {
    var [!x!] = this;
    var y = switch (x) {
      D _ => 1,
      _ => 2,
    };
  }
}
class D extends C {}
''');
  }
}
