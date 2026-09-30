// Copyright (c) 2026, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/src/services/correction/fix.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/src/diagnostic/diagnostic.dart' as diag;
import 'package:analyzer_plugin/utilities/fixes/fixes.dart';
import 'package:analyzer_testing/utilities/utilities.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'fix_processor.dart';

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(AddMissingClosureExpressionTest);
    defineReflectiveTests(AddMissingClosureNamedTest);
    defineReflectiveTests(AddMissingClosureParametersTest);
    defineReflectiveTests(AddMissingClosurePositionalTest);
  });
}

/// Tests for [DartFixKind.addClosure], produced when filling in a
/// missing closure expression that isn't a call argument: a variable's
/// initializer, a switch expression case's result, an arrow function's
/// body, or a `return` statement's value.
@reflectiveTest
class AddMissingClosureExpressionTest extends FixProcessorTest {
  @override
  FixKind get kind => DartFixKind.addClosure;

  Future<void> test_arrowFunction() async {
    await resolveTestCode('''
Function foo() => ;
''');
    await assertHasFix('''
Function foo() => () {};
''');
  }

  Future<void> test_arrowFunction_fixMessage() async {
    await resolveTestCode('''
Function foo() => ;
''');
    await assertHasFix('''
Function foo() => () {};
''', fixMessageContains: 'Add closure');
  }

  Future<void> test_arrowFunction_parameterType() async {
    await resolveTestCode('''
void Function(int a) foo() => ;
''');
    await assertHasFix('''
void Function(int a) foo() => (a) {};
''');
  }

  Future<void> test_assignment() async {
    await resolveTestCode('''
void g() {
  void Function(int a) f;
  f = ;
  f(0);
}
''');
    await assertHasFix('''
void g() {
  void Function(int a) f;
  f = (a) {};
  f(0);
}
''');
  }

  Future<void> test_returnStatement() async {
    await resolveTestCode('''
Function foo() {
  return;
}
''');
    await assertHasFix('''
Function foo() {
  return () {};
}
''');
  }

  Future<void> test_returnStatement_invalidReturnType() async {
    await resolveTestCode('''
int foo() {
  return;
}
''');
    await assertNoFix();
  }

  Future<void> test_returnStatement_parameterType() async {
    await resolveTestCode('''
void Function(int a) foo() {
  return;
}
''');
    await assertHasFix('''
void Function(int a) foo() {
  return (a) {};
}
''');
  }

  Future<void> test_switchExpressionCase() async {
    await resolveTestCode('''
void g(Object? foo) {
  Function _ = switch (foo) {
    null => ,
    _ => () {},
  };
}
''');
    await assertHasFix('''
void g(Object? foo) {
  Function _ = switch (foo) {
    null => () {},
    _ => () {},
  };
}
''');
  }

  Future<void> test_ternaryOperator_else() async {
    await resolveTestCode('''
void g() {
  void Function(int a) f;
  f = 1 == 1? (a) {} : ;
  f(0);
}
''');
    await assertHasFix('''
void g() {
  void Function(int a) f;
  f = 1 == 1? (a) {} : (a) {};
  f(0);
}
''');
  }

  Future<void> test_ternaryOperator_then() async {
    await resolveTestCode('''
void g() {
  void Function(int a) f;
  f = 1 == 1? : (a) {};
  f(0);
}
''');
    await assertHasFix('''
void g() {
  void Function(int a) f;
  f = 1 == 1? (a) {} : (a) {};
  f(0);
}
''');
  }

  Future<void> test_variableDeclaration() async {
    await resolveTestCode('''
void g() {
  Function _ = ;
}
''');
    await assertHasFix('''
void g() {
  Function _ = () {};
}
''');
  }

  Future<void> test_variableDeclaration_invalidParameterType() async {
    await resolveTestCode('''
void g() {
  int _ = ;
}
''');
    await assertNoFix();
  }

  Future<void> test_variableDeclaration_noExplicitType() async {
    await resolveTestCode('''
void g() {
  var _ = ;
}
''');
    await assertNoFix();
  }

  Future<void> test_variableDeclaration_parameterType() async {
    await resolveTestCode('''
void g() {
  void Function(int a) _ = ;
}
''');
    await assertHasFix('''
void g() {
  void Function(int a) _ = (a) {};
}
''');
  }

  Future<void> test_variableDeclaration_requiredNamedParameter() async {
    await resolveTestCode('''
void g() {
  void Function(int a, {required bool b}) _ = ;
}
''');
    await assertHasFix('''
void g() {
  void Function(int a, {required bool b}) _ = (a, {required b}) {};
}
''');
  }

  /// With `always_put_required_named_parameters_first` enabled, a brand new
  /// closure's named parameters are written with the required ones first,
  /// regardless of the order they appear in in the expected function type,
  /// just as for the named parameters merged into an already-written
  /// closure (see
  /// `AddMissingClosureParametersTest.test_existingClosure_missingRequiredNamed_requiredFirst`).
  Future<void>
  test_variableDeclaration_requiredNamedParameter_requiredFirst() async {
    newAnalysisOptionsYamlFile(
      testPackageRootPath,
      analysisOptionsContent(
        rules: [LintNames.always_put_required_named_parameters_first],
      ),
    );
    await resolveTestCode('''
void g() {
  // ignore: always_put_required_named_parameters_first
  void Function({bool? a, required bool b}) _ = ;
}
''');
    await assertHasFix('''
void g() {
  // ignore: always_put_required_named_parameters_first
  void Function({bool? a, required bool b}) _ = ({required b, a}) {};
}
''');
  }
}

/// Tests for [DartFixKind.addClosureNamed], produced when filling in
/// a missing expression for a named argument whose corresponding parameter
/// is a function type, e.g. `f(callback: );`.
@reflectiveTest
class AddMissingClosureNamedTest extends FixProcessorTest {
  @override
  FixKind get kind => DartFixKind.addClosureNamed;

  Future<void> test_bareFunctionType() async {
    await resolveTestCode('''
void f({required Function callback}) {}

void g() {
  f(callback: );
}
''');
    await assertHasFix('''
void f({required Function callback}) {}

void g() {
  f(callback: () {});
}
''');
  }

  Future<void> test_invalidParameterType() async {
    await resolveTestCode('''
void f({required int i}) {}

void g() {
  f(i: );
}
''');
    await assertNoFix();
  }

  Future<void> test_missingIdentifier_namedArgument() async {
    await resolveTestCode('''
void f({void Function(int)? callback}) {}

void g() {
  f(callback: );
}
''');
    await assertHasFix('''
void f({void Function(int)? callback}) {}

void g() {
  f(callback: (p0) {});
}
''');
  }

  /// A missing named argument's closure doesn't depend on how the enclosing
  /// invocation's target was resolved, so this also covers a dot-shorthand
  /// constructor invocation.
  Future<void>
  test_missingIdentifier_namedArgument_dotShorthandConstructorInvocation() async {
    await resolveTestCode('''
class C {
  C.named({void Function(int)? callback});
}

void g() {
  C _ = .named(callback: );
}
''');
    await assertHasFix('''
class C {
  C.named({void Function(int)? callback});
}

void g() {
  C _ = .named(callback: (p0) {});
}
''');
  }

  Future<void> test_missingIdentifier_namedArgument_fixMessage() async {
    await resolveTestCode('''
void f({void Function(int)? callback}) {}

void g() {
  f(callback: );
}
''');
    await assertHasFix('''
void f({void Function(int)? callback}) {}

void g() {
  f(callback: (p0) {});
}
''', fixMessageContains: "Add closure to 'callback'");
  }

  Future<void> test_missingIdentifier_namedArgument_folowingParameters() async {
    await resolveTestCode('''
void f({void Function(int)? callback, int? p}) {}

void g() {
  f(callback: , p: 0);
}
''');
    await assertHasFix('''
void f({void Function(int)? callback, int? p}) {}

void g() {
  f(callback: (p0) {}, p: 0);
}
''');
  }

  Future<void> test_requiredNamedParameter() async {
    await resolveTestCode('''
void f({required void Function(int a, {required bool b}) callback}) {}

void g() {
  f(callback: );
}
''');
    await assertHasFix('''
void f({required void Function(int a, {required bool b}) callback}) {}

void g() {
  f(callback: (a, {required b}) {});
}
''');
  }
}

/// Tests for [DartFixKind.addClosureParameters], produced when adding
/// missing parameters to an already-written closure argument.
@reflectiveTest
class AddMissingClosureParametersTest extends FixProcessorTest {
  @override
  FixKind get kind => DartFixKind.addClosureParameters;

  Future<void> test_arrowClosure() async {
    await resolveTestCode('''
void f(void Function(int a, int b) callback) {}

void g() {
  f((a) => a);
}
''');
    await assertHasFix('''
void f(void Function(int a, int b) callback) {}

void g() {
  f((a, b) => a);
}
''');
  }

  Future<void> test_arrowFunction() async {
    await resolveTestCode('''
void Function(int a, int b) foo() => (a) => a;
''');
    await assertHasFix('''
void Function(int a, int b) foo() => (a, b) => a;
''');
  }

  Future<void> test_assignment() async {
    await resolveTestCode('''
void g() {
  void Function(int a, int b) f;
  f = (a) => a;
  f(0, 0);
}
''');
    await assertHasFix('''
void g() {
  void Function(int a, int b) f;
  f = (a, b) => a;
  f(0, 0);
}
''');
  }

  /// Adding parameters to an already-written closure doesn't depend on how
  /// the enclosing invocation's target was resolved, so this also covers a
  /// dot-shorthand invocation.
  Future<void> test_dotShorthandInvocation() async {
    await resolveTestCode('''
class C {
  static C build(void Function(int, int) callback) => throw '';
}

void g() {
  C _ = .build((p0) {});
}
''');
    await assertHasFix('''
class C {
  static C build(void Function(int, int) callback) => throw '';
}

void g() {
  C _ = .build((p0, p1) {});
}
''');
  }

  Future<void> test_empty_positionalAndNamed() async {
    await resolveTestCode('''
void f(void Function(int, int, {bool name}) callback) {}

void g() {
  f(() {});
}
''');
    await assertHasFix('''
void f(void Function(int, int, {bool name}) callback) {}

void g() {
  f((p0, p1, {name}) {});
}
''');
  }

  Future<void> test_empty_positionalAndNamed_fixMessage() async {
    await resolveTestCode('''
void f(void Function(int, int, {bool name}) callback) {}

void g() {
  f(() {});
}
''');
    await assertHasFix('''
void f(void Function(int, int, {bool name}) callback) {}

void g() {
  f((p0, p1, {name}) {});
}
''', fixMessageContains: 'Add 3 missing closure parameters');
  }

  Future<void> test_empty_requiredNamed() async {
    await resolveTestCode('''
void f(void Function(int, {required bool name}) callback) {}

void g() {
  f(() {});
}
''');
    await assertHasFix('''
void f(void Function(int, {required bool name}) callback) {}

void g() {
  f((p0, {required name}) {});
}
''');
  }

  Future<void> test_existingClosure_missingNamed() async {
    await resolveTestCode('''
void f(void Function(int, {bool name}) callback) {}

void g() {
  f((p0,) {});
}
''');
    await assertHasFix('''
void f(void Function(int, {bool name}) callback) {}

void g() {
  f((p0, {name}) {});
}
''');
  }

  Future<void> test_existingClosure_missingNamed_partial() async {
    await resolveTestCode('''
void f(void Function(int, {String name, bool active}) callback) {}

void g() {
  f((p0, {name}) {});
}
''');
    await assertHasFix(
      '''
void f(void Function(int, {String name, bool active}) callback) {}

void g() {
  f((p0, {name, active}) {});
}
''',
      filter: (diagnostic) =>
          diagnostic.diagnosticCode == diag.argumentTypeNotAssignable,
    );
  }

  Future<void> test_existingClosure_missingOptionalPositional() async {
    // This also tests for trailing commas
    await resolveTestCode('''
void f(void Function(int, [int]) callback) {}

void g() {
  f((
    p0,
  ) {});
}
''');
    await assertHasFix('''
void f(void Function(int, [int]) callback) {}

void g() {
  f((
    p0, [p1]
  ) {});
}
''');
  }

  Future<void> test_existingClosure_missingOptionalPositional_partial() async {
    await resolveTestCode('''
void f(void Function(int, [int, int]) callback) {}

void g() {
  f((p0, [p1]) {});
}
''');
    await assertHasFix(
      '''
void f(void Function(int, [int, int]) callback) {}

void g() {
  f((p0, [p1, p2]) {});
}
''',
      filter: (diagnostic) =>
          diagnostic.diagnosticCode == diag.argumentTypeNotAssignable,
    );
  }

  /// If a generated parameter name (`p$index`) would collide with an
  /// existing parameter's name, a different name is generated instead.
  Future<void> test_existingClosure_missingPositional_nameCollision() async {
    await resolveTestCode('''
void f(void Function(int, int) callback) {}

void g() {
  f((p1) {});
}
''');
    await assertHasFix('''
void f(void Function(int, int) callback) {}

void g() {
  f((p1, p2) {});
}
''');
  }

  Future<void> test_existingClosure_missingRequiredNamed() async {
    await resolveTestCode('''
void f(void Function(int, {bool? alpha, required bool zeta}) callback) {}

void g() {
  f((p0) {});
}
''');
    await assertHasFix('''
void f(void Function(int, {bool? alpha, required bool zeta}) callback) {}

void g() {
  f((p0, {alpha, required zeta}) {});
}
''');
  }

  /// With `always_put_required_named_parameters_first` enabled, the missing
  /// named parameters are written with the required ones first, regardless of
  /// the order they appear in in the expected function type.
  Future<void> test_existingClosure_missingRequiredNamed_requiredFirst() async {
    newAnalysisOptionsYamlFile(
      testPackageRootPath,
      analysisOptionsContent(
        rules: [LintNames.always_put_required_named_parameters_first],
      ),
    );
    await resolveTestCode('''
void f(void Function(int, {required bool zeta, bool? alpha}) callback) {}

void g() {
  f((p0) {});
}
''');
    await assertHasFix('''
void f(void Function(int, {required bool zeta, bool? alpha}) callback) {}

void g() {
  f((p0, {required zeta, alpha}) {});
}
''');
  }

  Future<void> test_invalidArgumentType() async {
    await resolveTestCode('''
void f(void Function(int a, int b) callback) {}

void g() {
  f(0);
}
''');
    await assertNoFix();
  }

  Future<void> test_invalidClosureParameterType() async {
    await resolveTestCode('''
void f(void Function(int a, int b) callback) {}

void g() {
  f((String a) {});
}
''');
    await assertNoFix();
  }

  Future<void> test_invalidParameterType() async {
    await resolveTestCode('''
void f(int i) {}

void g() {
  f((String a) {});
}
''');
    await assertNoFix();
  }

  Future<void> test_one_positional() async {
    await resolveTestCode('''
void f(void Function(int, int) callback) {}

void g() {
  f((p0) {});
}
''');
    await assertHasFix('''
void f(void Function(int, int) callback) {}

void g() {
  f((p0, p1) {});
}
''');
  }

  Future<void> test_one_positional_fixMessage() async {
    await resolveTestCode('''
void f(void Function(int, int) callback) {}

void g() {
  f((p0) {});
}
''');
    await assertHasFix('''
void f(void Function(int, int) callback) {}

void g() {
  f((p0, p1) {});
}
''', fixMessageContains: 'Add 1 missing closure parameters');
  }

  Future<void> test_one_positional_onNamed() async {
    await resolveTestCode('''
void f({required void Function(int, int) callback}) {}

void g() {
  f(callback: (p0) {});
}
''');
    await assertHasFix('''
void f({required void Function(int, int) callback}) {}

void g() {
  f(callback: (p0, p1) {});
}
''');
  }

  Future<void> test_returnStatement() async {
    await resolveTestCode('''
void Function(int a, int b) bar() {
  return (a) => a;
}
''');
    await assertHasFix('''
void Function(int a, int b) bar() {
  return (a, b) => a;
}
''');
  }

  /// The [diag.returnOfInvalidTypeFromMethod] diagnostic is reported for a
  /// return inside an instance method just as
  /// [diag.returnOfInvalidTypeFromFunction] is for a top-level function; this
  /// exercises that diagnostic.
  Future<void> test_returnStatement_method() async {
    await resolveTestCode('''
class C {
  void Function(int a, int b) bar() {
    return (a) => a;
  }
}
''');
    await assertHasFix('''
class C {
  void Function(int a, int b) bar() {
    return (a, b) => a;
  }
}
''');
  }

  Future<void> test_switchExpressionCase() async {
    await resolveTestCode('''
void g(Object? foo) {
  void Function(int a, int b) _ = switch (foo) {
    null => (a) => a,
    _ => (a, b) => a,
  };
}
''');
    await assertHasFix('''
void g(Object? foo) {
  void Function(int a, int b) _ = switch (foo) {
    null => (a, b) => a,
    _ => (a, b) => a,
  };
}
''');
  }

  /// A ternary nested inside a switch expression case still knows the
  /// expected type from the enclosing switch expression.
  Future<void> test_switchExpressionCase_nestedTernary() async {
    await resolveTestCode('''
void g(Object? foo, bool cond) {
  void Function(int a, int b) _ = switch (foo) {
    null => cond ? (a) => a : (a, b) => a,
    _ => (a, b) => a,
  };
}
''');
    await assertHasFix('''
void g(Object? foo, bool cond) {
  void Function(int a, int b) _ = switch (foo) {
    null => cond ? (a, b) => a : (a, b) => a,
    _ => (a, b) => a,
  };
}
''');
  }

  Future<void> test_ternaryOperator_else() async {
    await resolveTestCode('''
void g() {
  void Function(int a, int b) f;
  f = 1 == 1 ? (a, b) => a : (a) => a;
  f(0, 0);
}
''');
    await assertHasFix('''
void g() {
  void Function(int a, int b) f;
  f = 1 == 1 ? (a, b) => a : (a, b) => a;
  f(0, 0);
}
''');
  }

  /// A ternary whose branch is missing parameters, itself the value of a
  /// named argument, still knows the expected type from the corresponding
  /// parameter.
  Future<void> test_ternaryOperator_nestedNamedArgument() async {
    await resolveTestCode('''
void f({required void Function(int a, int b) callback}) {}

void g(bool cond) {
  f(callback: cond ? (a) => a : (a, b) => a);
}
''');
    await assertHasFix('''
void f({required void Function(int a, int b) callback}) {}

void g(bool cond) {
  f(callback: cond ? (a, b) => a : (a, b) => a);
}
''');
  }

  /// A ternary whose branch is missing parameters, itself a positional
  /// argument, still knows the expected type from the corresponding
  /// parameter.
  Future<void> test_ternaryOperator_nestedPositionalArgument() async {
    await resolveTestCode('''
void f(void Function(int a, int b) callback) {}

void g(bool cond) {
  f(cond ? (a) => a : (a, b) => a);
}
''');
    await assertHasFix('''
void f(void Function(int a, int b) callback) {}

void g(bool cond) {
  f(cond ? (a, b) => a : (a, b) => a);
}
''');
  }

  /// A ternary whose branch is missing parameters, itself a `return`
  /// statement's value, still knows the expected type from the enclosing
  /// function's return type.
  Future<void> test_ternaryOperator_nestedReturnStatement() async {
    await resolveTestCode('''
void Function(int a, int b) bar(bool cond) {
  return cond ? (a) => a : (a, b) => a;
}
''');
    await assertHasFix('''
void Function(int a, int b) bar(bool cond) {
  return cond ? (a, b) => a : (a, b) => a;
}
''');
  }

  /// A switch expression nested inside a ternary branch still knows the
  /// expected type from the enclosing ternary.
  Future<void> test_ternaryOperator_nestedSwitchExpression() async {
    await resolveTestCode('''
void g(Object? foo, bool cond) {
  void Function(int a, int b) f;
  f = cond
      ? switch (foo) {
          null => (a) => a,
          _ => (a, b) => a,
        }
      : (a, b) => a;
  f(0, 0);
}
''');
    await assertHasFix('''
void g(Object? foo, bool cond) {
  void Function(int a, int b) f;
  f = cond
      ? switch (foo) {
          null => (a, b) => a,
          _ => (a, b) => a,
        }
      : (a, b) => a;
  f(0, 0);
}
''');
  }

  Future<void> test_ternaryOperator_then() async {
    await resolveTestCode('''
void g() {
  void Function(int a, int b) f;
  f = 1 == 1 ? (a) => a : (a, b) => a;
  f(0, 0);
}
''');
    await assertHasFix('''
void g() {
  void Function(int a, int b) f;
  f = 1 == 1 ? (a, b) => a : (a, b) => a;
  f(0, 0);
}
''');
  }

  Future<void> test_variableDeclaration() async {
    await resolveTestCode('''
void g() {
  void Function(int a, int b) _ = (a) => a;
}
''');
    await assertHasFix('''
void g() {
  void Function(int a, int b) _ = (a, b) => a;
}
''');
  }
}

@reflectiveTest
class AddMissingClosurePositionalTest extends FixProcessorTest {
  @override
  FixKind get kind => DartFixKind.addClosurePositional;

  Future<void> test_avoidTypesOnClosuresLint() async {
    newAnalysisOptionsYamlFile(
      testPackageRootPath,
      analysisOptionsContent(
        rules: [LintNames.avoid_types_on_closure_parameters],
      ),
    );
    await resolveTestCode('''
void f(void Function(void Function(int a) f) callback) {}

void g() {
  f();
}
''');
    await assertHasFix('''
void f(void Function(void Function(int a) f) callback) {}

void g() {
  f((f) {});
}
''');
  }

  Future<void> test_avoidTypesOnClosuresLint_specifyTypes() async {
    newAnalysisOptionsYamlFile(
      testPackageRootPath,
      analysisOptionsContent(
        rules: [
          LintNames.avoid_types_on_closure_parameters,
          LintNames.always_specify_types,
        ],
      ),
    );
    await resolveTestCode('''
void f(void Function(void Function(int a) f) callback) {}

void g() {
  f();
}
''');
    await assertHasFix('''
void f(void Function(void Function(int a) f) callback) {}

void g() {
  f((void Function(int a) f) {});
}
''');
  }

  Future<void> test_bareFunctionType() async {
    await resolveTestCode('''
void f(Function callback) {}

void g() {
  f();
}
''');
    await assertHasFix('''
void f(Function callback) {}

void g() {
  f(() {});
}
''');
  }

  /// The [diag.notEnoughPositionalArgumentsNameSingular] diagnostic is
  /// reported for a dot-shorthand constructor invocation (a
  /// [DotShorthandConstructorInvocation]) just as it is for an
  /// [InstanceCreationExpression]; this exercises that branch of
  /// `_addNewClosureArgument`.
  Future<void> test_dotShorthandConstructorInvocation() async {
    await resolveTestCode('''
class C {
  C(void Function(int a) callback);
}

void g() {
  C _ = .new();
}
''');
    await assertHasFix('''
class C {
  C(void Function(int a) callback);
}

void g() {
  C _ = .new((a) {});
}
''');
  }

  /// The [diag.notEnoughPositionalArgumentsNameSingular] diagnostic is
  /// reported for a dot-shorthand invocation (a [DotShorthandInvocation])
  /// just as it is for a [MethodInvocation]; this exercises that branch of
  /// `_addNewClosureArgument`.
  Future<void> test_dotShorthandInvocation() async {
    await resolveTestCode('''
class C {
  static C build(void Function(int a) callback) => throw '';
}

void g() {
  C _ = .build();
}
''');
    await assertHasFix('''
class C {
  static C build(void Function(int a) callback) => throw '';
}

void g() {
  C _ = .build((a) {});
}
''');
  }

  Future<void> test_functionType_argumentsNamed() async {
    newAnalysisOptionsYamlFile(
      testPackageRootPath,
      analysisOptionsContent(rules: [LintNames.always_specify_types]),
    );
    await resolveTestCode('''
void f(void Function(void Function(int a) f) callback) {}

void g() {
  f();
}
''');
    await assertHasFix('''
void f(void Function(void Function(int a) f) callback) {}

void g() {
  f((void Function(int a) f) {});
}
''');
  }

  Future<void> test_functionType_namedOptional() async {
    await resolveTestCode('''
void f(void Function({int? a}) callback) {}

void g() {
  f();
}
''');
    await assertHasFix('''
void f(void Function({int? a}) callback) {}

void g() {
  f(({a}) {});
}
''');
  }

  Future<void> test_functionType_namedRequired() async {
    await resolveTestCode('''
void f(void Function(int a, {required int b}) callback) {}

void g() {
  f();
}
''');
    await assertHasFix('''
void f(void Function(int a, {required int b}) callback) {}

void g() {
  f((a, {required b}) {});
}
''');
  }

  /// The [diag.notEnoughPositionalArgumentsNameSingular] diagnostic is reported
  /// for a constructor invocation (an [InstanceCreationExpression]) just as it
  /// is for a [MethodInvocation]; this exercises that branch of
  /// `_addNewClosureArgument`.
  Future<void> test_instanceCreationExpression() async {
    await resolveTestCode('''
class C {
  C(void Function(int a) callback);
}

void g() {
  C();
}
''');
    await assertHasFix('''
class C {
  C(void Function(int a) callback);
}

void g() {
  C((a) {});
}
''');
  }

  Future<void> test_invalidParameterType() async {
    await resolveTestCode('''
void f(int i) {}

void g() {
  f();
}
''');
    await assertNoFix();
  }

  Future<void> test_missingArgument_optionalPositional() async {
    await resolveTestCode('''
void f(void Function(int, [int]) callback) {}

void g() {
  f();
}
''');
    await assertHasFix('''
void f(void Function(int, [int]) callback) {}

void g() {
  f((p0, [p1]) {});
}
''');
  }

  /// The [diag.notEnoughPositionalArgumentsNamePlural] diagnostic (more than
  /// one missing required positional argument) is reported when there are
  /// multiple required parameters still missing.
  Future<void> test_namePlural() async {
    await resolveTestCode('''
void f(void Function(int) a, void Function(int) b) {}

void g() {
  f();
}
''');
    await assertHasFix('''
void f(void Function(int) a, void Function(int) b) {}

void g() {
  f((p0) {});
}
''');
  }

  Future<void> test_optionalPositionalArgumentWithName() async {
    await resolveTestCode('''
void f(void Function([int a]) callback) {}

void g() {
  f();
}
''');
    await assertHasFix('''
void f(void Function([int a]) callback) {}

void g() {
  f(([a]) {});
}
''');
  }

  Future<void> test_positionalArgumentWithName() async {
    await resolveTestCode('''
void f(void Function(int a) callback) {}

void g() {
  f();
}
''');
    await assertHasFix('''
void f(void Function(int a) callback) {}

void g() {
  f((a) {});
}
''');
  }

  Future<void> test_positionalArgumentWithName_afterNamedArgument() async {
    await resolveTestCode('''
void f(int i, void Function(int a) callback, {int? name}) {}

void g() {
  f(name: 1, 0);
}
''');
    await assertHasFix('''
void f(int i, void Function(int a) callback, {int? name}) {}

void g() {
  f(name: 1, 0, (a) {});
}
''');
  }

  Future<void> test_positionalArgumentWithName_beforeNamedArgument() async {
    await resolveTestCode('''
void f(int i, void Function(int a) callback, {int? name}) {}

void g() {
  f(0, name: 1);
}
''');
    await assertHasFix('''
void f(int i, void Function(int a) callback, {int? name}) {}

void g() {
  f(0, (a) {}, name: 1);
}
''');
  }

  Future<void> test_positionalArgumentWithName_fixMessage() async {
    await resolveTestCode('''
void f(void Function(int a) callback) {}

void g() {
  f();
}
''');
    await assertHasFix('''
void f(void Function(int a) callback) {}

void g() {
  f((a) {});
}
''', fixMessageContains: 'Add closure as 1st argument');
  }

  Future<void>
  test_positionalArgumentWithName_fixMessage_secondArgument() async {
    await resolveTestCode('''
void f(int i, void Function(int a) callback) {}

void g() {
  f(0);
}
''');
    await assertHasFix('''
void f(int i, void Function(int a) callback) {}

void g() {
  f(0, (a) {});
}
''', fixMessageContains: 'Add closure as 2nd argument');
  }

  Future<void>
  test_positionalArgumentWithName_fixMessage_thirdArgument() async {
    await resolveTestCode('''
void f(int i, int j, void Function(int a) callback) {}

void g() {
  f(0, 0);
}
''');
    await assertHasFix('''
void f(int i, int j, void Function(int a) callback) {}

void g() {
  f(0, 0, (a) {});
}
''', fixMessageContains: 'Add closure as 3rd argument');
  }

  Future<void> test_positionalArgumentWithName_onlyNamedArgument() async {
    await resolveTestCode('''
void f(void Function(int a) callback, {int? name}) {}

void g() {
  f(name: 1);
}
''');
    await assertHasFix('''
void f(void Function(int a) callback, {int? name}) {}

void g() {
  f((a) {}, name: 1);
}
''');
  }
}
