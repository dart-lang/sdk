// Copyright (c) 2021, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../rule_test_support.dart';

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(DeprecatedConsistencyTest);
  });
}

@reflectiveTest
class DeprecatedConsistencyTest extends LintRuleTest {
  @override
  String get lintRule => LintNames.deprecated_consistency;

  test_classDeprecated_factoryConstructor() async {
    await assertDiagnosticsFromMarkup(r'''
@deprecated
class A {
  @deprecated
  A._();

  factory [!A!]() => A._();
}
''');
  }

  test_classDeprecated_factoryConstructor_deprecated() async {
    await assertNoDiagnostics(r'''
@deprecated
class A {
  @deprecated
  A._();

  @deprecated
  factory A() => A._();
}
''');
  }

  test_classDeprecated_generativeConstructor() async {
    await assertDiagnosticsFromMarkup(r'''
@deprecated
class A {
  [!A!]();
}
''');
  }

  test_classDeprecated_generativeConstructor_deprecated() async {
    await assertNoDiagnostics(r'''
@deprecated
class A {
  @deprecated
  A();
}
''');
  }

  test_classDeprecated_newSyntax() async {
    await assertDiagnosticsFromMarkup(r'''
@deprecated
class A {
  [!new!]();
}
''');
  }

  test_classDeprecated_primaryConstructor() async {
    await assertDiagnosticsFromMarkup(r'''
@deprecated
class [!A!]();
''');
  }

  test_classDeprecated_primaryConstructor_deprecated() async {
    await assertNoDiagnostics(r'''
@deprecated
class A() {
  @deprecated
  this;
}
''');
  }

  test_classDeprecated_primaryConstructor_named() async {
    await assertDiagnosticsFromMarkup(r'''
@deprecated
class [!A.named!]();
''');
  }

  test_constructorFieldFormalDeprecated_field() async {
    await assertDiagnosticsFromMarkup(r'''
class A {
  String? [!a!];
  A({@deprecated this.a});
}
''');
  }

  test_constructorFieldFormalDeprecated_fieldDeprecated() async {
    await assertNoDiagnostics(r'''
class A {
  @deprecated
  String? a;
  A({@deprecated this.a});
}
''');
  }

  test_constructorSuperFieldFormalDeprecated_field() async {
    await assertNoDiagnostics(r'''
class A {
  String? a;
  A({this.a});
}

class B extends A {
  B({@deprecated super.a});
}
''');
  }

  test_extensionTypeDeprecated_primaryConstructor() async {
    await assertDiagnosticsFromMarkup(r'''
@deprecated
extension type [!E!](int i) {}
''');
  }

  test_extensionTypeDeprecated_primaryConstructor_deprecated() async {
    await assertNoDiagnostics(r'''
@deprecated
extension type E(int i) {
  @deprecated
  this;
}
''');
  }

  test_fieldDeprecated_fieldFormalParameter() async {
    await assertDiagnosticsFromMarkup(r'''
class A {
  @deprecated
  String? a;
  A({[!this.a!]});
}
''');
  }

  test_fieldDeprecated_fieldFormalParameter_deprecated() async {
    await assertNoDiagnostics(r'''
class A {
  @deprecated
  String? a;
  A({@deprecated this.a});
}
''');
  }

  test_ignorePrivateFields() async {
    // Private fields are not part of the public API, so it doesn't make sense
    // to try to match up their deprecation status with that of the parameters
    // that initialize them.
    await assertNoDiagnostics(r'''
class C {
  @deprecated
  int? _a;

  int? _b;

  C({this._a, @deprecated this._b});
}
''');
  }

  test_primaryConstructor_thisParameter_deprecated() async {
    await assertNoDiagnostics(r'''
class A({@deprecated this.a = 1}) {
  @deprecated
  int a;
}
''');
  }

  test_primaryConstructor_thisParameter_fieldDeprecated() async {
    await assertDiagnosticsFromMarkup(r'''
class A([!this.a!]) {
  @deprecated
  int a;
}
''');
  }

  test_repro_62759() async {
    // Regression test for issue 62759: deprecated_consistency lint swaps
    // parameter and field
    await assertDiagnostics(
      r'''
class C {
  @deprecated
  int? deprecatedField;

  int? deprecatedParameter;

  C({this.deprecatedField, @deprecated this.deprecatedParameter});
}
''',
      [
        lint(
          56,
          19,
          messageContainsAll: [
            // ignore: no_adjacent_strings_in_list
            'Fields that are initialized by a deprecated parameter should be '
                'deprecated',
          ],
        ),
        lint(
          83,
          20,
          messageContainsAll: [
            // ignore: no_adjacent_strings_in_list
            'Parameters that initialize a deprecated field should be '
                'deprecated',
          ],
        ),
      ],
    );
  }
}
