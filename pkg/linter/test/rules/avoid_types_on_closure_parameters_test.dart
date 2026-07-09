// Copyright (c) 2023, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../rule_test_support.dart';

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(AvoidTypesOnClosureParametersTest);
  });
}

@reflectiveTest
class AvoidTypesOnClosureParametersTest extends LintRuleTest {
  @override
  String get lintRule => LintNames.avoid_types_on_closure_parameters;

  test_argument() async {
    await assertNoDiagnostics(r'''
void f(List<int> list) {
  list.map((e) => e.isEven);
}
''');
  }

  test_argument_typedParameter() async {
    await assertDiagnosticsFromMarkup(r'''
void f(List<int> list) {
  list.map(([!int!] e) => e.isEven);
}
''');
  }

  test_assignedToFunctionTypedTarget() async {
    await assertDiagnosticsFromMarkup(r'''
void f(C c) {
  c.onFoo = ([!int!] p) {};
}
class C {
  void Function(int p)? onFoo;
}
''');
  }

  test_assignedToNonFunctionTypedTarget() async {
    await assertNoDiagnostics(r'''
var onFoo = (int p) {};
''');
  }

  test_closureIsArgument_dartCoreFunctionType() async {
    await assertNoDiagnostics(r'''
void f(Future<void> future) {
  future.then((_) {}, onError: (e, st) {});
}
''');
  }

  test_closureIsArgument_namedOptional() async {
    await assertNoDiagnostics(r'''
void f(C c) {
  c.map(({e}) => e?.isEven);
}
class C {
  void map(void Function({int? e})) {}
}
''');
  }

  test_closureIsArgument_optionalNullable() async {
    await assertNoDiagnostics(r'''
void f(C c) {
  c.map(([e]) => e?.isEven);
}
class C {
  void map(void Function([int? e])) {}
}
''');
  }

  test_closureIsArgument_optionalWithDefault() async {
    await assertNoDiagnostics(r'''
void f(C c) {
  c.map(({e = 7}) => e?.isEven);
}
class C {
  void map(void Function({int? e})) {}
}
''');
  }

  test_closureIsArgument_parameterIsTyped_dynamic() async {
    await assertNoDiagnostics(r'''
void f(C c) {
  c.map((dynamic p) => p);
}
class C {
  void map(int Function(dynamic p)) {}
}
''');
  }

  test_closureIsArgument_parameterIsTyped_functionType() async {
    await assertDiagnosticsFromMarkup(r'''
void f(List<int Function(int)> list) {
  list.map(([!int p(int x)!]) => p(0));
}
''');
  }

  test_closureIsArgument_parameterIsTyped_namedRequired() async {
    await assertDiagnosticsFromMarkup(r'''
void f(C c) {
  c.map(({required [!int!] p}) => p);
}
class C {
  void map(int Function({required int p})) {}
}
''');
  }

  test_closureIsArgument_parameterIsTyped_optionalNullable() async {
    await assertDiagnosticsFromMarkup(r'''
void f(C c) {
  c.map(([[!int?!] p]) => p);
}
class C {
  void map(int? Function([int? p])) {}
}
''');
  }

  test_closureIsArgument_parameterIsTyped_optionalWithDefault() async {
    await assertDiagnosticsFromMarkup(r'''
void f(C c) {
  c.map(([[!int!] p = 0]) => p);
}
class C {
  void map(int? Function([int p])) {}
}
''');
  }

  test_parameterIsNotInClosure_inFunction() async {
    await assertNoDiagnostics(r'''
void f(int p) {}
''');
  }

  test_parameterIsNotInClosure_inLocalFunction() async {
    await assertNoDiagnostics(r'''
void f(List<int> list) {
  list.map((e) {
    void g(int p) {}
    return g(e);
  });
}
''');
  }

  test_parameterIsNotInClosure_inMethod() async {
    await assertNoDiagnostics(r'''
class C {
  void f(int p) {}
}
''');
  }
}
