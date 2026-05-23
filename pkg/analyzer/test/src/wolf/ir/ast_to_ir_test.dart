// Copyright (c) 2023, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/src/wolf/ir/ast_to_ir.dart';
import 'package:analyzer/src/wolf/ir/call_descriptor.dart';
import 'package:analyzer/src/wolf/ir/coded_ir.dart';
import 'package:analyzer/src/wolf/ir/interpreter.dart';
import 'package:analyzer/src/wolf/ir/ir.dart';
import 'package:analyzer/src/wolf/ir/scope_analyzer.dart';
import 'package:analyzer/src/wolf/ir/validator.dart';
import 'package:checks/checks.dart';
import 'package:test/test.dart' show fail;
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../../dart/resolution/context_collection_resolution.dart';
import '../../dart/resolution/node_text_expectations.dart';
import 'utils.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(AstToIRTest);
    defineReflectiveTests(UpdateNodeTextExpectations);
  });
}

@reflectiveTest
class AstToIRTest extends AstToIRTestBase {
  late final _callHandlers = {
    'hook': binaryFunction<Object?, String>(hook<Object?>),
    'int.isEven': unaryFunction<int>((i) => i.isEven),
    'int.parse': unaryFunction<String>((s) => int.parse(s)),
    'int.toString': unaryFunction<int>((i) => i.toString()),
    'Iterable.first': unaryFunction<ListInstance>((list) => list.values.first),
    'Iterable.length': unaryFunction<ListInstance>(
      (list) => list.values.length,
    ),
    'List.add': binaryFunction<ListInstance, Object?>(
      (list, value) => list.values.add(value),
    ),
    'List.first=': binaryFunction<ListInstance, Object?>(
      (list, value) => list.values.first = value,
    ),
    'List.length=': binaryFunction<ListInstance, int>(
      (list, newLength) => list.values.length = newLength,
    ),
    'num.+': binaryFunction<num, num>((x, y) => x + y),
    'num.-': binaryFunction<num, num>((x, y) => x - y),
    'num.>': binaryFunction<num, num>((x, y) => x > y),
    'num.>=': binaryFunction<num, num>((x, y) => x >= y),
    'num.<': binaryFunction<num, num>((x, y) => x < y),
    'Object.hashCode': unaryFunction<Object?>((o) => o.hashCode),
    'String.contains': binaryFunction<String, String>(
      (this_, other) => this_.contains(other),
    ),
    'String.length': unaryFunction<String>((s) => s.length),
  };

  final _expectedHooks = <String>[];

  Object? Function(Instance)? _onAwait;

  void Function(Object?)? _onYield;

  Future<void> checkBinaryOp(String op) async {
    var result = await resolveTestCodeWithDiagnostics('''
class C {
  external int operator $op(int other);
}
test(C c, int other) => c $op other;
''');
    analyze(result, result.findNode.singleFunctionDeclaration);
    check(astNodes)[result.findNode.binary('c $op other')]
      ..containsSubrange(astNodes[result.findNode.simple('c $op')]!)
      ..containsSubrange(astNodes[result.findNode.simple('other;')]!);
    var c = Instance(result.findElement.class_('C').thisType);
    _callHandlers['C.$op'] = binaryFunction<Instance, int>((this_, other) {
      check(this_).identicalTo(c);
      check(other).equals(123);
      return 456;
    });
    check(runInterpreter(result, [c, 123])).equals(456);
  }

  Future<void> checkBinaryOpEq(String op) async {
    var unitResult = await resolveTestCodeWithDiagnostics('''
class C {
  external C operator $op(int other);
}
test(List<C> list, int other) => list.first $op= other;
''');
    analyze(unitResult, unitResult.findNode.singleFunctionDeclaration);
    check(astNodes)[unitResult.findNode.assignment('list.first $op= other')]
      ..containsSubrange(astNodes[unitResult.findNode.simple('list.first')]!)
      ..containsSubrange(astNodes[unitResult.findNode.prefixed('list.first')]!)
      ..containsSubrange(astNodes[unitResult.findNode.simple('other;')]!);
    var c = Instance(unitResult.findElement.class_('C').thisType);
    var result = Instance(unitResult.findElement.class_('C').thisType);
    _callHandlers['C.$op'] = binaryFunction<Instance, int>((this_, other) {
      check(this_).identicalTo(c);
      check(other).equals(123);
      return result;
    });
    var values = [c];
    check(
      runInterpreter(unitResult, [makeList(unitResult, values), 123]),
    ).identicalTo(result);
    check(values[0]).identicalTo(result);
  }

  /// Executes [callback], verifying that the calls to [hook] that occur while
  /// it is executing exactly match [expectedHooks].
  ///
  /// Calls to [hook] can either be made directly or via the interpreter. This
  /// allows unit tests to verify that the IR generated for certain complex
  /// constructs executes operations in the expected order.
  T expectHooks<T>(List<String> expectedHooks, T Function() callback) {
    _expectedHooks.addAll(expectedHooks);
    var result = callback();
    check(_expectedHooks).isEmpty;
    return result;
  }

  /// Returns [value], after first verifying that this call was expected.
  ///
  /// See [expectHooks].
  T hook<T>(T value, String hookName) {
    if (_expectedHooks.isEmpty) {
      fail('Unexpected invocation of hook $hookName');
    }
    check(_expectedHooks.removeAt(0)).equals(hookName);
    return value;
  }

  ListInstance makeList(TestResolvedUnitResult result, List<Object?> values) =>
      ListInstance(
        result.typeProvider.listType(result.typeProvider.objectQuestionType),
        values,
      );

  Object? runInterpreter(TestResolvedUnitResult result, List<Object?> args) =>
      interpret(
        ir,
        args,
        scopes: scopes,
        callDispatcher: _CallDispatcher(this),
        typeProvider: result.typeProvider,
        typeSystem: result.typeSystem,
      );

  test_adjacentStrings() async {
    var result = await resolveTestCodeWithDiagnostics('''
test() => 'foo' " " 'bar';
''');
    analyze(result, result.findNode.singleFunctionDeclaration);
    check(astNodes)[result.findNode.adjacentStrings('foo')]
      ..containsSubrange(astNodes[result.findNode.stringLiteral('foo')]!)
      ..containsSubrange(astNodes[result.findNode.stringLiteral('" "')]!)
      ..containsSubrange(astNodes[result.findNode.stringLiteral('bar')]!);
    check(runInterpreter(result, [])).equals('foo bar');
  }

  test_assignmentExpression_binaryAndEq() => checkBinaryOpEq('&');

  test_assignmentExpression_binaryOrEq() => checkBinaryOpEq('|');

  test_assignmentExpression_binaryXorEq() => checkBinaryOpEq('^');

  test_assignmentExpression_divideEq() => checkBinaryOpEq('/');

  test_assignmentExpression_integerDivideEq() => checkBinaryOpEq('~/');

  test_assignmentExpression_leftShiftEq() => checkBinaryOpEq('<<');

  test_assignmentExpression_local_compound_sideEffect() async {
    var result = await resolveTestCodeWithDiagnostics('''
test() {
  int i = 123;
  i += 456;
  return i;
}
''');
    analyze(result, result.findNode.singleFunctionDeclaration);
    check(astNodes)[result.findNode.assignment('i +=')]
      ..containsSubrange(astNodes[result.findNode.simple('i +=')]!)
      ..containsSubrange(astNodes[result.findNode.integerLiteral('456')]!);
    check(runInterpreter(result, [])).equals(579);
  }

  test_assignmentExpression_local_compound_value() async {
    var result = await resolveTestCodeWithDiagnostics('''
test() {
  int i = 123;
  return i += 456;
}
''');
    analyze(result, result.findNode.singleFunctionDeclaration);
    check(astNodes)[result.findNode.assignment('i +=')]
      ..containsSubrange(astNodes[result.findNode.simple('i +=')]!)
      ..containsSubrange(astNodes[result.findNode.integerLiteral('456')]!);
    check(runInterpreter(result, [])).equals(579);
  }

  test_assignmentExpression_local_ifNull_sideEffect() async {
    var result = await resolveTestCodeWithDiagnostics('''
external int? hook(int? x, String s);
test(int? i) {
  int? j = i;
  j ??= hook(123, '123');
  return j;
}
''');
    analyze(result, result.findNode.functionDeclaration('test'));
    check(astNodes)[result.findNode.assignment('j ??=')]
      ..containsSubrange(astNodes[result.findNode.simple('j ??=')]!)
      ..containsSubrange(
        astNodes[result.findNode.methodInvocation("hook(123, '123')")]!,
      );
    expectHooks([
      '123',
    ], () => check(runInterpreter(result, [null])).equals(123));
    expectHooks([], () => check(runInterpreter(result, [1])).equals(1));
  }

  test_assignmentExpression_local_ifNull_value() async {
    var result = await resolveTestCodeWithDiagnostics('''
external int? hook(int? x, String s);
test(int? i) {
  int? j = i; // ignore: unused_local_variable
  return j ??= hook(123, '123');
}
''');
    analyze(result, result.findNode.functionDeclaration('test'));
    check(astNodes)[result.findNode.assignment('j ??=')]
      ..containsSubrange(astNodes[result.findNode.simple('j ??=')]!)
      ..containsSubrange(
        astNodes[result.findNode.methodInvocation("hook(123, '123')")]!,
      );
    expectHooks([
      '123',
    ], () => check(runInterpreter(result, [null])).equals(123));
    expectHooks([], () => check(runInterpreter(result, [1])).equals(1));
  }

  test_assignmentExpression_local_simple_sideEffect() async {
    var result = await resolveTestCodeWithDiagnostics('''
test() {
  int i;
  i = 123;
  return i;
}
''');
    analyze(result, result.findNode.singleFunctionDeclaration);
    check(astNodes)[result.findNode.assignment('i =')]
      ..containsSubrange(astNodes[result.findNode.simple('i =')]!)
      ..containsSubrange(astNodes[result.findNode.integerLiteral('123')]!);
    check(runInterpreter(result, [])).equals(123);
  }

  test_assignmentExpression_local_simple_value() async {
    var result = await resolveTestCodeWithDiagnostics('''
test() {
  int i; // ignore: unused_local_variable
  return i = 123;
}
''');
    analyze(result, result.findNode.singleFunctionDeclaration);
    check(astNodes)[result.findNode.assignment('i =')]
      ..containsSubrange(astNodes[result.findNode.simple('i =')]!)
      ..containsSubrange(astNodes[result.findNode.integerLiteral('123')]!);
    check(runInterpreter(result, [])).equals(123);
  }

  test_assignmentExpression_minusEq() => checkBinaryOpEq('-');

  test_assignmentExpression_modEq() => checkBinaryOpEq('%');

  test_assignmentExpression_parameter_compound_sideEffect() async {
    var result = await resolveTestCodeWithDiagnostics('''
test(int i) {
  i += 456;
  return i;
}
''');
    analyze(result, result.findNode.singleFunctionDeclaration);
    check(astNodes)[result.findNode.assignment('i +=')]
      ..containsSubrange(astNodes[result.findNode.simple('i +=')]!)
      ..containsSubrange(astNodes[result.findNode.integerLiteral('456')]!);
    check(runInterpreter(result, [123])).equals(579);
  }

  test_assignmentExpression_parameter_compound_value() async {
    var result = await resolveTestCodeWithDiagnostics('''
test(int i) => i += 456;
''');
    analyze(result, result.findNode.singleFunctionDeclaration);
    check(astNodes)[result.findNode.assignment('i +=')]
      ..containsSubrange(astNodes[result.findNode.simple('i +=')]!)
      ..containsSubrange(astNodes[result.findNode.integerLiteral('456')]!);
    check(runInterpreter(result, [123])).equals(579);
  }

  test_assignmentExpression_parameter_ifNull_sideEffect() async {
    var result = await resolveTestCodeWithDiagnostics('''
external int? hook(int? x, String s);
test(int? i) {
  i ??= hook(123, '123');
  return i;
}
''');
    analyze(result, result.findNode.functionDeclaration('test'));
    check(astNodes)[result.findNode.assignment('i ??=')]
      ..containsSubrange(astNodes[result.findNode.simple('i ??=')]!)
      ..containsSubrange(
        astNodes[result.findNode.methodInvocation("hook(123, '123')")]!,
      );
    expectHooks([
      '123',
    ], () => check(runInterpreter(result, [null])).equals(123));
    expectHooks([], () => check(runInterpreter(result, [1])).equals(1));
  }

  test_assignmentExpression_parameter_ifNull_value() async {
    var result = await resolveTestCodeWithDiagnostics('''
external int? hook(int? x, String s);
test(int? i) => i ??= hook(123, '123');
''');
    analyze(result, result.findNode.functionDeclaration('test'));
    check(astNodes)[result.findNode.assignment('i ??=')]
      ..containsSubrange(astNodes[result.findNode.simple('i ??=')]!)
      ..containsSubrange(
        astNodes[result.findNode.methodInvocation("hook(123, '123')")]!,
      );
    expectHooks([
      '123',
    ], () => check(runInterpreter(result, [null])).equals(123));
    expectHooks([], () => check(runInterpreter(result, [1])).equals(1));
  }

  test_assignmentExpression_parameter_simple_sideEffect() async {
    var result = await resolveTestCodeWithDiagnostics('''
test(int i) {
  i = 123;
  return i;
}
''');
    analyze(result, result.findNode.singleFunctionDeclaration);
    check(astNodes)[result.findNode.assignment('i =')]
      ..containsSubrange(astNodes[result.findNode.simple('i =')]!)
      ..containsSubrange(astNodes[result.findNode.integerLiteral('123')]!);
    check(runInterpreter(result, [1])).equals(123);
  }

  test_assignmentExpression_parameter_simple_value() async {
    var result = await resolveTestCodeWithDiagnostics('''
test(int i) => i = 123;
''');
    analyze(result, result.findNode.singleFunctionDeclaration);
    check(astNodes)[result.findNode.assignment('i =')]
      ..containsSubrange(astNodes[result.findNode.simple('i =')]!)
      ..containsSubrange(astNodes[result.findNode.integerLiteral('123')]!);
    check(runInterpreter(result, [1])).equals(123);
  }

  test_assignmentExpression_plusEq() => checkBinaryOpEq('+');

  test_assignmentExpression_property_nullShorting_compound() async {
    var result = await resolveTestCodeWithDiagnostics('''
test(List? l) => l?.length -= 2;
''');
    analyze(result, result.findNode.singleFunctionDeclaration);
    check(astNodes)[result.findNode.assignment('l?.length -= 2')]
      ..containsSubrange(astNodes[result.findNode.simple('l?.length')]!)
      ..containsSubrange(astNodes[result.findNode.propertyAccess('l?.length')]!)
      ..containsSubrange(astNodes[result.findNode.integerLiteral('2')]!);
    check(runInterpreter(result, [null])).equals(null);
    var l = ['a', 'b', 'c', 'd', 'e'];
    check(runInterpreter(result, [makeList(result, l)])).equals(3);
    check(l).deepEquals(['a', 'b', 'c']);
  }

  test_assignmentExpression_property_nullShorting_ifNull() async {
    var result = await resolveTestCodeWithDiagnostics('''
external int? hook(int? x, String s);
class C {
  int? p;
}
test(C? c) => c?.p ??= hook(123, '123');
''');
    analyze(result, result.findNode.functionDeclaration('test'));
    check(astNodes)[result.findNode.assignment("c?.p ??= hook(123, '123')")]
      ..containsSubrange(astNodes[result.findNode.simple('c?.p')]!)
      ..containsSubrange(astNodes[result.findNode.propertyAccess('c?.p')]!)
      ..containsSubrange(
        astNodes[result.findNode.methodInvocation("hook(123, '123')")]!,
      );
    Object? p;
    _callHandlers['C.p'] = unaryFunction<Instance>((c) => hook(p, 'c.p'));
    _callHandlers['C.p='] = binaryFunction<Instance, int?>(
      (c, value) => hook(p = value, 'c.p=$value'),
    );
    var c = Instance(result.findElement.class_('C').thisType);
    expectHooks([], () => check(runInterpreter(result, [null])).equals(null));
    expectHooks([
      'c.p',
      '123',
      'c.p=123',
    ], () => check(runInterpreter(result, [c])).equals(123));
    check(p).equals(123);
    p = 456;
    expectHooks(['c.p'], () => check(runInterpreter(result, [c])).equals(456));
    check(p).equals(456);
  }

  test_assignmentExpression_property_nullShorting_simple() async {
    var result = await resolveTestCodeWithDiagnostics('''
test(List? l) => l?.length = 3;
''');
    analyze(result, result.findNode.singleFunctionDeclaration);
    check(astNodes)[result.findNode.assignment('l?.length = 3')]
      ..containsSubrange(astNodes[result.findNode.simple('l?.length')]!)
      ..containsSubrange(astNodes[result.findNode.propertyAccess('l?.length')]!)
      ..containsSubrange(astNodes[result.findNode.integerLiteral('3')]!);
    check(runInterpreter(result, [null])).equals(null);
    var l = ['a', 'b', 'c', 'd', 'e'];
    check(runInterpreter(result, [makeList(result, l)])).equals(3);
    check(l).deepEquals(['a', 'b', 'c']);
  }

  test_assignmentExpression_property_prefixedIdentifier_compound() async {
    var result = await resolveTestCodeWithDiagnostics('''
test(List l) => l.length -= 2;
''');
    analyze(result, result.findNode.singleFunctionDeclaration);
    check(astNodes)[result.findNode.assignment('l.length -= 2')]
      ..containsSubrange(astNodes[result.findNode.simple('l.length')]!)
      ..containsSubrange(astNodes[result.findNode.prefixed('l.length')]!)
      ..containsSubrange(astNodes[result.findNode.integerLiteral('2')]!);
    var l = ['a', 'b', 'c', 'd', 'e'];
    check(runInterpreter(result, [makeList(result, l)])).equals(3);
    check(l).deepEquals(['a', 'b', 'c']);
  }

  test_assignmentExpression_property_prefixedIdentifier_ifNull() async {
    var result = await resolveTestCodeWithDiagnostics('''
external int? hook(int? x, String s);
class C {
  int? p;
}
test(C c) => c.p ??= hook(123, '123');
''');
    analyze(result, result.findNode.functionDeclaration('test'));
    check(astNodes)[result.findNode.assignment("c.p ??= hook(123, '123')")]
      ..containsSubrange(astNodes[result.findNode.simple('c.p')]!)
      ..containsSubrange(astNodes[result.findNode.prefixed('c.p')]!)
      ..containsSubrange(
        astNodes[result.findNode.methodInvocation("hook(123, '123')")]!,
      );
    Object? p;
    _callHandlers['C.p'] = unaryFunction<Instance>((c) => hook(p, 'c.p'));
    _callHandlers['C.p='] = binaryFunction<Instance, int?>(
      (c, value) => hook(p = value, 'c.p=$value'),
    );
    var c = Instance(result.findElement.class_('C').thisType);
    expectHooks([
      'c.p',
      '123',
      'c.p=123',
    ], () => check(runInterpreter(result, [c])).equals(123));
    check(p).equals(123);
    p = 456;
    expectHooks(['c.p'], () => check(runInterpreter(result, [c])).equals(456));
    check(p).equals(456);
  }

  test_assignmentExpression_property_prefixedIdentifier_simple() async {
    var result = await resolveTestCodeWithDiagnostics('''
test(List l) => l.length = 3;
''');
    analyze(result, result.findNode.singleFunctionDeclaration);
    check(astNodes)[result.findNode.assignment('l.length = 3')]
      ..containsSubrange(astNodes[result.findNode.simple('l.length')]!)
      ..containsSubrange(astNodes[result.findNode.prefixed('l.length')]!)
      ..containsSubrange(astNodes[result.findNode.integerLiteral('3')]!);
    var l = ['a', 'b', 'c', 'd', 'e'];
    check(runInterpreter(result, [makeList(result, l)])).equals(3);
    check(l).deepEquals(['a', 'b', 'c']);
  }

  test_assignmentExpression_property_propertyAccess_compound() async {
    var result = await resolveTestCodeWithDiagnostics('''
test(List l) => (l).length -= 2;
''');
    analyze(result, result.findNode.singleFunctionDeclaration);
    check(astNodes)[result.findNode.assignment('(l).length -= 2')]
      ..containsSubrange(astNodes[result.findNode.parenthesized('(l)')]!)
      ..containsSubrange(
        astNodes[result.findNode.propertyAccess('(l).length')]!,
      )
      ..containsSubrange(astNodes[result.findNode.integerLiteral('2')]!);
    var l = ['a', 'b', 'c', 'd', 'e'];
    check(runInterpreter(result, [makeList(result, l)])).equals(3);
    check(l).deepEquals(['a', 'b', 'c']);
  }

  test_assignmentExpression_property_propertyAccess_ifNull() async {
    var result = await resolveTestCodeWithDiagnostics('''
external int? hook(int? x, String s);
class C {
  int? p;
}
test(C c) => (c).p ??= hook(123, '123');
''');
    analyze(result, result.findNode.functionDeclaration('test'));
    check(astNodes)[result.findNode.assignment("(c).p ??= hook(123, '123')")]
      ..containsSubrange(astNodes[result.findNode.parenthesized('(c)')]!)
      ..containsSubrange(astNodes[result.findNode.propertyAccess('(c).p')]!)
      ..containsSubrange(
        astNodes[result.findNode.methodInvocation("hook(123, '123')")]!,
      );
    Object? p;
    _callHandlers['C.p'] = unaryFunction<Instance>((c) => hook(p, 'c.p'));
    _callHandlers['C.p='] = binaryFunction<Instance, int?>(
      (c, value) => hook(p = value, 'c.p=$value'),
    );
    var c = Instance(result.findElement.class_('C').thisType);
    expectHooks([
      'c.p',
      '123',
      'c.p=123',
    ], () => check(runInterpreter(result, [c])).equals(123));
    check(p).equals(123);
    p = 456;
    expectHooks(['c.p'], () => check(runInterpreter(result, [c])).equals(456));
    check(p).equals(456);
  }

  test_assignmentExpression_property_propertyAccess_simple() async {
    var result = await resolveTestCodeWithDiagnostics('''
test(List l) => (l).length = 3;
''');
    analyze(result, result.findNode.singleFunctionDeclaration);
    check(astNodes)[result.findNode.assignment('(l).length = 3')]
      ..containsSubrange(astNodes[result.findNode.parenthesized('(l)')]!)
      ..containsSubrange(
        astNodes[result.findNode.propertyAccess('(l).length')]!,
      )
      ..containsSubrange(astNodes[result.findNode.integerLiteral('3')]!);
    var l = ['a', 'b', 'c', 'd', 'e'];
    check(runInterpreter(result, [makeList(result, l)])).equals(3);
    check(l).deepEquals(['a', 'b', 'c']);
  }

  test_assignmentExpression_property_simpleIdentifier_compound() async {
    var result = await resolveTestCodeWithDiagnostics('''
extension E on List {
  test() => length -= 2;
}
''');
    analyze(result, result.findNode.singleMethodDeclaration);
    check(astNodes)[result.findNode.assignment('length -= 2')]
      ..containsSubrange(astNodes[result.findNode.simple('length')]!)
      ..containsSubrange(astNodes[result.findNode.integerLiteral('2')]!);
    var l = ['a', 'b', 'c', 'd', 'e'];
    check(runInterpreter(result, [makeList(result, l)])).equals(3);
    check(l).deepEquals(['a', 'b', 'c']);
  }

  test_assignmentExpression_property_simpleIdentifier_ifNull() async {
    var result = await resolveTestCodeWithDiagnostics('''
external int? hook(int? x, String s);
class C {
  int? p;
  test() => p ??= hook(123, '123');
}
''');
    analyze(result, result.findNode.methodDeclaration('test'));
    check(astNodes)[result.findNode.assignment("p ??= hook(123, '123')")]
      ..containsSubrange(astNodes[result.findNode.simple('p ??=')]!)
      ..containsSubrange(
        astNodes[result.findNode.methodInvocation("hook(123, '123')")]!,
      );
    Object? p;
    _callHandlers['C.p'] = unaryFunction<Instance>((c) => hook(p, 'c.p'));
    _callHandlers['C.p='] = binaryFunction<Instance, int?>(
      (c, value) => hook(p = value, 'c.p=$value'),
    );
    var c = Instance(result.findElement.class_('C').thisType);
    expectHooks([
      'c.p',
      '123',
      'c.p=123',
    ], () => check(runInterpreter(result, [c])).equals(123));
    check(p).equals(123);
    p = 456;
    expectHooks(['c.p'], () => check(runInterpreter(result, [c])).equals(456));
    check(p).equals(456);
  }

  test_assignmentExpression_property_simpleIdentifier_simple() async {
    var result = await resolveTestCodeWithDiagnostics('''
extension E on List {
  test() => length = 3;
}
''');
    analyze(result, result.findNode.singleMethodDeclaration);
    check(astNodes)[result.findNode.assignment('length = 3')]
      ..containsSubrange(astNodes[result.findNode.simple('length')]!)
      ..containsSubrange(astNodes[result.findNode.integerLiteral('3')]!);
    var l = ['a', 'b', 'c', 'd', 'e'];
    check(runInterpreter(result, [makeList(result, l)])).equals(3);
    check(l).deepEquals(['a', 'b', 'c']);
  }

  test_assignmentExpression_rightShiftEq() => checkBinaryOpEq('>>');

  test_assignmentExpression_rightTripleShiftEq() => checkBinaryOpEq('>>>');

  test_assignmentExpression_timesEq() => checkBinaryOpEq('*');

  test_awaitExpression_future() async {
    var result = await resolveTestCodeWithDiagnostics('''
test(Future f) async => await f;
''');
    analyze(result, result.findNode.singleFunctionDeclaration);
    check(astNodes)[result.findNode.awaitExpression('await')].containsSubrange(
      astNodes[result.findNode.simple('f;')]!,
    );
    var f = Instance(
      result.typeProvider.futureType(result.typeProvider.intType),
    );
    _onAwait = (operand) {
      check(operand).identicalTo(f);
      return 123;
    };
    check(runInterpreter(result, [f])).equals(123);
  }

  test_binaryExpression_and() async {
    var result = await resolveTestCodeWithDiagnostics('''
external bool hook(bool b, String s);
test(bool x, bool y) => hook(x, 'x') && hook(y, 'y');
''');
    analyze(result, result.findNode.functionDeclaration('test'));
    check(astNodes)[result.findNode.binary("hook(x, 'x') && hook(y, 'y')")]
      ..containsSubrange(
        astNodes[result.findNode.methodInvocation("hook(x, 'x')")]!,
      )
      ..containsSubrange(
        astNodes[result.findNode.methodInvocation("hook(y, 'y')")]!,
      );
    expectHooks([
      'x',
    ], () => check(runInterpreter(result, [false, false])).equals(false));
    expectHooks([
      'x',
    ], () => check(runInterpreter(result, [false, true])).equals(false));
    expectHooks([
      'x',
      'y',
    ], () => check(runInterpreter(result, [true, false])).equals(false));
    expectHooks([
      'x',
      'y',
    ], () => check(runInterpreter(result, [true, true])).equals(true));
  }

  test_binaryExpression_binaryAnd() => checkBinaryOp('&');

  test_binaryExpression_binaryOr() => checkBinaryOp('|');

  test_binaryExpression_binaryXor() => checkBinaryOp('^');

  test_binaryExpression_divide() => checkBinaryOp('/');

  test_binaryExpression_equal() async {
    var result = await resolveTestCodeWithDiagnostics('''
test(Object? x, Object? y) => x == y;
''');
    analyze(result, result.findNode.singleFunctionDeclaration);
    check(astNodes)[result.findNode.binary('x == y')]
      ..containsSubrange(astNodes[result.findNode.simple('x ==')]!)
      ..containsSubrange(astNodes[result.findNode.simple('y;')]!);
    check(runInterpreter(result, [null, null])).equals(true);
    check(runInterpreter(result, [null, 1])).equals(false);
    check(runInterpreter(result, [1, null])).equals(false);
    check(runInterpreter(result, [1, 2])).equals(false);
    check(runInterpreter(result, [1, 1])).equals(true);
  }

  test_binaryExpression_greaterThan() => checkBinaryOp('>');

  test_binaryExpression_greaterThanOrEqual() => checkBinaryOp('>=');

  test_binaryExpression_ifNull() async {
    var result = await resolveTestCodeWithDiagnostics('''
external Object? hook(Object? x, String s);
test(Object? x, Object? y) => hook(x, 'x') ?? hook(y, 'y');
''');
    analyze(result, result.findNode.functionDeclaration('test'));
    check(astNodes)[result.findNode.binary("hook(x, 'x') ?? hook(y, 'y')")]
      ..containsSubrange(
        astNodes[result.findNode.methodInvocation("hook(x, 'x')")]!,
      )
      ..containsSubrange(
        astNodes[result.findNode.methodInvocation("hook(y, 'y')")]!,
      );
    expectHooks([
      'x',
      'y',
    ], () => check(runInterpreter(result, [null, null])).equals(null));
    expectHooks([
      'x',
      'y',
    ], () => check(runInterpreter(result, [null, 456])).equals(456));
    expectHooks([
      'x',
    ], () => check(runInterpreter(result, [123, null])).equals(123));
    expectHooks([
      'x',
    ], () => check(runInterpreter(result, [123, 456])).equals(123));
  }

  test_binaryExpression_integerDivide() => checkBinaryOp('~/');

  test_binaryExpression_leftShift() => checkBinaryOp('<<');

  test_binaryExpression_lessThan() => checkBinaryOp('<');

  test_binaryExpression_lessThanOrEqual() => checkBinaryOp('<=');

  test_binaryExpression_minus() => checkBinaryOp('-');

  test_binaryExpression_mod() => checkBinaryOp('%');

  test_binaryExpression_notEqual() async {
    var result = await resolveTestCodeWithDiagnostics('''
test(Object? x, Object? y) => x != y;
''');
    analyze(result, result.findNode.singleFunctionDeclaration);
    check(astNodes)[result.findNode.binary('x != y')]
      ..containsSubrange(astNodes[result.findNode.simple('x !=')]!)
      ..containsSubrange(astNodes[result.findNode.simple('y;')]!);
    check(runInterpreter(result, [null, null])).equals(false);
    check(runInterpreter(result, [null, 1])).equals(true);
    check(runInterpreter(result, [1, null])).equals(true);
    check(runInterpreter(result, [1, 2])).equals(true);
    check(runInterpreter(result, [1, 1])).equals(false);
  }

  test_binaryExpression_or() async {
    var result = await resolveTestCodeWithDiagnostics('''
external bool hook(bool b, String s);
test(bool x, bool y) => hook(x, 'x') || hook(y, 'y');
''');
    analyze(result, result.findNode.functionDeclaration('test'));
    check(astNodes)[result.findNode.binary("hook(x, 'x') || hook(y, 'y')")]
      ..containsSubrange(
        astNodes[result.findNode.methodInvocation("hook(x, 'x')")]!,
      )
      ..containsSubrange(
        astNodes[result.findNode.methodInvocation("hook(y, 'y')")]!,
      );
    expectHooks([
      'x',
      'y',
    ], () => check(runInterpreter(result, [false, false])).equals(false));
    expectHooks([
      'x',
      'y',
    ], () => check(runInterpreter(result, [false, true])).equals(true));
    expectHooks([
      'x',
    ], () => check(runInterpreter(result, [true, false])).equals(true));
    expectHooks([
      'x',
    ], () => check(runInterpreter(result, [true, true])).equals(true));
  }

  test_binaryExpression_plus() => checkBinaryOp('+');

  test_binaryExpression_rightShift() => checkBinaryOp('>>');

  test_binaryExpression_rightTripleShift() => checkBinaryOp('>>>');

  test_binaryExpression_times() => checkBinaryOp('*');

  test_block() async {
    var result = await resolveTestCodeWithDiagnostics('''
test(int i) {
  i = 123;
  i = 456;
  return i;
}
''');
    analyze(result, result.findNode.singleFunctionDeclaration);
    check(astNodes)[result.findNode.block('123')]
      ..containsSubrange(
        astNodes[result.findNode.expressionStatement('i = 123')]!,
      )
      ..containsSubrange(
        astNodes[result.findNode.expressionStatement('i = 456')]!,
      )
      ..containsSubrange(
        astNodes[result.findNode.returnStatement('return i')]!,
      );
    check(runInterpreter(result, [1])).equals(456);
  }

  test_blockFunctionBody() async {
    var result = await resolveTestCodeWithDiagnostics('''
test() {
  return 123;
}
''');
    analyze(result, result.findNode.singleFunctionDeclaration);
    check(astNodes)[result.findNode.blockFunctionBody('123')].containsSubrange(
      astNodes[result.findNode.block('123')]!,
    );
    check(runInterpreter(result, [])).equals(123);
  }

  test_booleanLiteral() async {
    var result = await resolveTestCodeWithDiagnostics('''
test() => true;
''');
    analyze(result, result.findNode.singleFunctionDeclaration);
    check(astNodes).containsNode(result.findNode.booleanLiteral('true'));
    check(runInterpreter(result, [])).equals(true);
  }

  test_breakStatement_fromDoLoop() async {
    var result = await resolveTestCodeWithDiagnostics('''
test(int count, List<int> result) {
  do {
    result.add(count--);
    if (count < 3) break;
  } while (count > 0);
}
''');
    analyze(result, result.findNode.singleFunctionDeclaration);
    check(astNodes).containsNode(result.findNode.breakStatement('break'));
    var values = <int>[];
    check(runInterpreter(result, [5, makeList(result, values)])).equals(null);
    check(values).deepEquals([5, 4, 3]);
  }

  test_breakStatement_fromForStatement_forParts() async {
    var result = await resolveTestCodeWithDiagnostics('''
test(int count, List<int> result) {
  for (var i = 0; i < count; i++) {
    result.add(i);
    if (i >= 2) break;
  }
}
''');
    analyze(result, result.findNode.singleFunctionDeclaration);
    check(astNodes).containsNode(result.findNode.breakStatement('break'));
    var values = <int>[];
    check(runInterpreter(result, [5, makeList(result, values)])).equals(null);
    check(values).deepEquals([0, 1, 2]);
  }

  test_breakStatement_fromWhileLoop() async {
    var result = await resolveTestCodeWithDiagnostics('''
test(int count, List<int> result) {
  while (count-- > 0) {
    result.add(count);
    if (count == 2) break;
  }
}
''');
    analyze(result, result.findNode.singleFunctionDeclaration);
    check(astNodes).containsNode(result.findNode.breakStatement('break'));
    var values = <int>[];
    check(runInterpreter(result, [5, makeList(result, values)])).equals(null);
    check(values).deepEquals([4, 3, 2]);
  }

  test_conditionalExpression() async {
    var result = await resolveTestCodeWithDiagnostics('''
test(bool b) => b ? 1 : 2;
''');
    analyze(result, result.findNode.singleFunctionDeclaration);
    check(astNodes)[result.findNode.conditionalExpression('b ? 1 : 2')]
      ..containsSubrange(astNodes[result.findNode.simple('b ?')]!)
      ..containsSubrange(astNodes[result.findNode.integerLiteral('1')]!)
      ..containsSubrange(astNodes[result.findNode.integerLiteral('2')]!);
    check(runInterpreter(result, [true])).equals(1);
    check(runInterpreter(result, [false])).equals(2);
  }

  test_continueStatement_inDoLoop() async {
    var result = await resolveTestCodeWithDiagnostics('''
test(int count, List<int> result) {
  do {
    if ((--count).isEven) continue;
    result.add(count);
  } while (count > 0);
}
''');
    analyze(result, result.findNode.singleFunctionDeclaration);
    check(astNodes).containsNode(result.findNode.continueStatement('continue'));
    var values = <int>[];
    check(runInterpreter(result, [5, makeList(result, values)])).equals(null);
    check(values).deepEquals([3, 1]);
  }

  test_continueStatement_inForStatement_forParts() async {
    var result = await resolveTestCodeWithDiagnostics('''
test(int count, List<int> result) {
  for (var i = 0; i < count; i++) {
    if (i.isEven) continue;
    result.add(i);
  }
}
''');
    analyze(result, result.findNode.singleFunctionDeclaration);
    check(astNodes).containsNode(result.findNode.continueStatement('continue'));
    var values = <int>[];
    check(runInterpreter(result, [5, makeList(result, values)])).equals(null);
    check(values).deepEquals([1, 3]);
  }

  test_continueStatement_inWhileLoop() async {
    var result = await resolveTestCodeWithDiagnostics('''
test(int count, List<int> result) {
  while (count-- > 0) {
    if (count.isEven) continue;
    result.add(count);
  }
}
''');
    analyze(result, result.findNode.singleFunctionDeclaration);
    check(astNodes).containsNode(result.findNode.continueStatement('continue'));
    var values = <int>[];
    check(runInterpreter(result, [5, makeList(result, values)])).equals(null);
    check(values).deepEquals([3, 1]);
  }

  test_doStatement_simple() async {
    var result = await resolveTestCodeWithDiagnostics('''
test(int count, List<int> result) {
  do {
    result.add(count--);
  } while (count > 0);
}
''');
    analyze(result, result.findNode.singleFunctionDeclaration);
    check(astNodes)[result.findNode.doStatement('do')]
      ..containsSubrange(astNodes[result.findNode.block('result.add')]!)
      ..containsSubrange(astNodes[result.findNode.binary('count > 0')]!);
    var values = <int>[];
    check(runInterpreter(result, [5, makeList(result, values)])).equals(null);
    check(values).deepEquals([5, 4, 3, 2, 1]);
    values.clear();
    // Make sure the loop always runs at least once.
    check(runInterpreter(result, [0, makeList(result, values)])).equals(null);
    check(values).deepEquals([0]);
  }

  test_doubleLiteral() async {
    var result = await resolveTestCodeWithDiagnostics('''
test() => 1.5;
''');
    analyze(result, result.findNode.singleFunctionDeclaration);
    check(astNodes).containsNode(result.findNode.doubleLiteral('1.5'));
    check(runInterpreter(result, [])).equals(1.5);
  }

  test_expressionFunctionBody() async {
    var result = await resolveTestCodeWithDiagnostics('''
test() => 0;
''');
    analyze(result, result.findNode.singleFunctionDeclaration);
    check(astNodes)[result.findNode.expressionFunctionBody('0')]
        .containsSubrange(astNodes[result.findNode.integerLiteral('0')]!);
  }

  test_expressionStatement() async {
    var result = await resolveTestCodeWithDiagnostics('''
test(int i) {
  i = 123;
  return i;
}
''');
    analyze(result, result.findNode.singleFunctionDeclaration);
    check(astNodes)[result.findNode.expressionStatement('i = 123')]
        .containsSubrange(astNodes[result.findNode.assignment('i = 123')]!);
    check(runInterpreter(result, [1])).equals(123);
  }

  test_forStatement_forParts_withDeclaration() async {
    var result = await resolveTestCodeWithDiagnostics('''
test(int count, List<int> result) {
  for (var i = 0; i < count; i++) {
    result.add(i);
  }
}
''');
    analyze(result, result.findNode.singleFunctionDeclaration);
    check(astNodes)[result.findNode.forStatement('for')]
      ..containsSubrange(
        astNodes[result.findNode.variableDeclarationList('var i = 0')]!,
      )
      ..containsSubrange(astNodes[result.findNode.binary('i < count')]!)
      ..containsSubrange(astNodes[result.findNode.postfix('i++')]!)
      ..containsSubrange(astNodes[result.findNode.block('result.add')]!);
    var values = <int>[];
    check(runInterpreter(result, [5, makeList(result, values)])).equals(null);
    check(values).deepEquals([0, 1, 2, 3, 4]);
  }

  test_ifStatement_noElse() async {
    var result = await resolveTestCodeWithDiagnostics('''
test(bool b) {
  Object? result;
  if (b /*test*/) {
    result = 1;
  }
  return result;
}
''');
    analyze(result, result.findNode.singleFunctionDeclaration);
    check(astNodes)[result.findNode.ifStatement('if')]
      ..containsSubrange(astNodes[result.findNode.simple('b /*test*/')]!)
      ..containsSubrange(astNodes[result.findNode.block('result = 1')]!);
    check(runInterpreter(result, [true])).equals(1);
    check(runInterpreter(result, [false])).equals(null);
  }

  test_ifStatement_noElse_earlyReturn() async {
    var result = await resolveTestCodeWithDiagnostics('''
test(bool b) {
  if (b /*test*/) {
    return 1;
  }
}
''');
    analyze(result, result.findNode.singleFunctionDeclaration);
    check(astNodes)[result.findNode.ifStatement('if')]
      ..containsSubrange(astNodes[result.findNode.simple('b /*test*/')]!)
      ..containsSubrange(astNodes[result.findNode.block('return 1')]!);
    check(runInterpreter(result, [true])).equals(1);
    check(runInterpreter(result, [false])).equals(null);
  }

  test_ifStatement_withElse() async {
    var result = await resolveTestCodeWithDiagnostics('''
test(bool b) {
  Object? result;
  if (b /*test*/) {
    result = 1;
  } else {
    result = 2;
  }
  return result;
}
''');
    analyze(result, result.findNode.singleFunctionDeclaration);
    check(astNodes)[result.findNode.ifStatement('if')]
      ..containsSubrange(astNodes[result.findNode.simple('b /*test*/')]!)
      ..containsSubrange(astNodes[result.findNode.block('result = 1')]!)
      ..containsSubrange(astNodes[result.findNode.block('result = 2')]!);
    check(runInterpreter(result, [true])).equals(1);
    check(runInterpreter(result, [false])).equals(2);
  }

  test_ifStatement_withElse_earlyReturn() async {
    var result = await resolveTestCodeWithDiagnostics('''
test(bool b) {
  if (b /*test*/) {
    return 1;
  } else {
    return 2;
  }
}
''');
    analyze(result, result.findNode.singleFunctionDeclaration);
    check(astNodes)[result.findNode.ifStatement('if')]
      ..containsSubrange(astNodes[result.findNode.simple('b /*test*/')]!)
      ..containsSubrange(astNodes[result.findNode.block('return 1')]!)
      ..containsSubrange(astNodes[result.findNode.block('return 2')]!);
    check(runInterpreter(result, [true])).equals(1);
    check(runInterpreter(result, [false])).equals(2);
  }

  test_integerLiteral() async {
    var result = await resolveTestCodeWithDiagnostics('''
test() => 123;
''');
    analyze(result, result.findNode.singleFunctionDeclaration);
    check(astNodes).containsNode(result.findNode.integerLiteral('123'));
    check(runInterpreter(result, [])).equals(123);
  }

  test_isExpression_inverted() async {
    var result = await resolveTestCodeWithDiagnostics('''
test(Object? o) => o is! String;
''');
    analyze(result, result.findNode.singleFunctionDeclaration);
    check(astNodes)[result.findNode.isExpression('is')].containsSubrange(
      astNodes[result.findNode.simple('o is')]!,
    );
    check(runInterpreter(result, [123])).equals(true);
    check(runInterpreter(result, ['123'])).equals(false);
  }

  test_isExpression_uninverted() async {
    var result = await resolveTestCodeWithDiagnostics('''
test(Object? o) => o is String;
''');
    analyze(result, result.findNode.singleFunctionDeclaration);
    check(astNodes)[result.findNode.isExpression('is')].containsSubrange(
      astNodes[result.findNode.simple('o is')]!,
    );
    check(runInterpreter(result, [123])).equals(false);
    check(runInterpreter(result, ['123'])).equals(true);
  }

  test_methodInvocation_identical() async {
    var result = await resolveTestCodeWithDiagnostics('''
test(Object? x, Object? y) => identical(x, y);
''');
    analyze(result, result.findNode.singleFunctionDeclaration);
    check(astNodes)[result.findNode.methodInvocation('identical(x, y)')]
      ..containsSubrange(astNodes[result.findNode.simple('x, y')]!)
      ..containsSubrange(astNodes[result.findNode.simple('y);')]!);
    var s1 = 's';
    var s2 = String.fromCharCode(s1.codeUnitAt(0));
    assert(!identical(s1, s2));
    check(runInterpreter(result, [s1, s2])).equals(false);
    check(runInterpreter(result, [s1, s1])).equals(true);
  }

  test_methodInvocation_identical_decoy() async {
    var result = await resolveTestCodeWithDiagnostics('''
external bool identical(Object? x, Object? y);
test(Object? x, Object? y) => identical(x, y); // invocation
''');
    analyze(result, result.findNode.functionDeclaration('test'));
    check(astNodes)[result.findNode.methodInvocation('identical(x, y)')]
      ..containsSubrange(astNodes[result.findNode.simple('x, y')]!)
      ..containsSubrange(
        astNodes[result.findNode.simple('y); // invocation')]!,
      );
    var s1 = 's';
    var s2 = String.fromCharCode(s1.codeUnitAt(0));
    assert(!identical(s1, s2));
    _callHandlers['identical'] = binaryFunction<Object?, Object?>(
      (x, y) => !identical(x, y),
    );
    check(runInterpreter(result, [s1, s2])).equals(true);
    check(runInterpreter(result, [s1, s1])).equals(false);
  }

  test_methodInvocation_instanceMethod() async {
    var result = await resolveTestCodeWithDiagnostics('''
test(String s1, String s2) => s1.contains(s2);
''');
    analyze(result, result.findNode.singleFunctionDeclaration);
    check(astNodes)[result.findNode.methodInvocation('s1.contains(s2)')]
      ..containsSubrange(astNodes[result.findNode.simple('s1.contains')]!)
      ..containsSubrange(astNodes[result.findNode.simple('s2);')]!);
    check(runInterpreter(result, ['abcde', 'bcd'])).equals(true);
    check(runInterpreter(result, ['abc', 'abcde'])).equals(false);
  }

  test_methodInvocation_instanceMethod_implicitThis() async {
    var result = await resolveTestCodeWithDiagnostics('''
class C {
  external int f(int x);
  test(int x) => f(x); // invocation
}
''');
    analyze(result, result.findNode.methodDeclaration('test'));
    check(astNodes)[result.findNode.methodInvocation('f(x)')].containsSubrange(
      astNodes[result.findNode.simple('x); // invocation')]!,
    );
    var c = Instance(result.findElement.class_('C').thisType);
    _callHandlers['C.f'] = binaryFunction<Instance, int>((this_, x) {
      check(this_).identicalTo(c);
      check(x).equals(123);
      return 456;
    });
    check(runInterpreter(result, [c, 123])).equals(456);
  }

  test_methodInvocation_nullAware() async {
    var result = await resolveTestCodeWithDiagnostics('''
external String f();
test(String? s) => s?.contains(f());
''');
    analyze(result, result.findNode.functionDeclaration('test'));
    check(astNodes)[result.findNode.methodInvocation('s?.contains(f())')]
      ..containsSubrange(astNodes[result.findNode.simple('s?.contains')]!)
      ..containsSubrange(astNodes[result.findNode.methodInvocation('f())')]!);
    late bool fCalled;
    late String fValue;
    _callHandlers['f'] = nullaryFunction(() {
      check(fCalled).isFalse();
      fCalled = true;
      return fValue;
    });
    fCalled = false;
    fValue = 'bcd';
    check(runInterpreter(result, ['abcde'])).equals(true);
    check(fCalled).isTrue;
    fCalled = false;
    fValue = 'abcde';
    check(runInterpreter(result, ['abc'])).equals(false);
    check(fCalled).isTrue;
    fCalled = false;
    fValue = 'irrelevant';
    check(runInterpreter(result, [null])).equals(null);
    check(fCalled).isFalse;
  }

  test_methodInvocation_staticMethod() async {
    var result = await resolveTestCodeWithDiagnostics('''
test(String s) => int.parse(s);
''');
    analyze(result, result.findNode.singleFunctionDeclaration);
    check(astNodes)[result.findNode.methodInvocation('int.parse(s)')]
        .containsSubrange(astNodes[result.findNode.simple('s);')]!);
    check(astNodes).not((s) => s.containsNode(result.findNode.simple('int')));
    check(runInterpreter(result, ['123'])).equals(123);
  }

  test_methodInvocation_staticMethod_inScope() async {
    var result = await resolveTestCodeWithDiagnostics('''
class C {
  external static int f(int x);
  test(int x) => f(x); // invocation
  }
''');
    analyze(result, result.findNode.methodDeclaration('test'));
    check(astNodes)[result.findNode.methodInvocation('f(x)')].containsSubrange(
      astNodes[result.findNode.simple('x); // invocation')]!,
    );
    _callHandlers['C.f'] = unaryFunction<int>((x) {
      check(x).equals(123);
      return 456;
    });
    var c = Instance(result.findElement.class_('C').thisType);
    check(runInterpreter(result, [c, 123])).equals(456);
  }

  test_methodInvocation_topLevelFunction_nullary() async {
    var result = await resolveTestCodeWithDiagnostics('''
external int f();
test() => f(); // invocation
''');
    analyze(result, result.findNode.functionDeclaration('test'));
    check(
      astNodes,
    ).containsNode(result.findNode.methodInvocation('f(); // invocation'));
    _callHandlers['f'] = nullaryFunction(() => 123);
    check(runInterpreter(result, [])).equals(123);
  }

  test_methodInvocation_topLevelFunction_oneNamedArgument() async {
    var result = await resolveTestCodeWithDiagnostics('''
external int f(int x, {required int y});
test(int x, int y) => f(x, y: y); // invocation
''');
    analyze(result, result.findNode.functionDeclaration('test'));
    check(astNodes)[result.findNode.methodInvocation('f(x, y: y)')]
      ..containsSubrange(astNodes[result.findNode.simple('x, y')]!)
      ..containsSubrange(
        astNodes[result.findNode.simple('y); // invocation')]!,
      );
    _callHandlers['f'] = (callDescriptor, positionalArguments, namedArguments) {
      check(callDescriptor.typeArguments).isEmpty;
      check(positionalArguments).length.equals(1);
      var x = positionalArguments[0] as int;
      check(namedArguments).keys.unorderedEquals(['y']);
      var y = namedArguments['y'] as int;
      return 10 * x + y;
    };
    check(runInterpreter(result, [1, 2])).equals(12);
  }

  test_methodInvocation_topLevelFunction_positionalArguments() async {
    var result = await resolveTestCodeWithDiagnostics('''
external int f(int x, int y);
test(int x, int y) => f(x, y); // invocation
''');
    analyze(result, result.findNode.functionDeclaration('test'));
    check(astNodes)[result.findNode.methodInvocation('f(x, y)')]
      ..containsSubrange(astNodes[result.findNode.simple('x, y')]!)
      ..containsSubrange(
        astNodes[result.findNode.simple('y); // invocation')]!,
      );
    _callHandlers['f'] = binaryFunction<int, int>((x, y) => 10 * x + y);
    check(runInterpreter(result, [1, 2])).equals(12);
  }

  test_methodInvocation_topLevelFunction_twoNamedArguments() async {
    var result = await resolveTestCodeWithDiagnostics('''
external int f({required int x, required int y});
test(int x, int y) => f(y: y, x: x);
''');
    analyze(result, result.findNode.functionDeclaration('test'));
    check(astNodes)[result.findNode.methodInvocation('f(y: y, x: x)')]
      ..containsSubrange(astNodes[result.findNode.simple('y, x')]!)
      ..containsSubrange(astNodes[result.findNode.simple('x);')]!);
    _callHandlers['f'] = (callDescriptor, positionalArguments, namedArguments) {
      check(callDescriptor.typeArguments).isEmpty;
      check(positionalArguments).isEmpty;
      check(namedArguments).keys.unorderedEquals(['x', 'y']);
      var x = namedArguments['x'] as int;
      var y = namedArguments['y'] as int;
      return 10 * x + y;
    };
    check(runInterpreter(result, [1, 2])).equals(12);
  }

  test_methodInvocation_typeArguments_explicit() async {
    var result = await resolveTestCodeWithDiagnostics('''
external f<T, U>();
test() => f<int, String>();
''');
    analyze(result, result.findNode.functionDeclaration('test'));
    check(
      astNodes,
    ).containsNode(result.findNode.methodInvocation('f<int, String>()'));
    _callHandlers['f'] = (callDescriptor, positinalArguments, namedArguments) {
      check(callDescriptor.typeArguments).length.equals(2);
      check(
        callDescriptor.typeArguments[0],
      ).equals(result.typeProvider.intType);
      check(
        callDescriptor.typeArguments[1],
      ).equals(result.typeProvider.stringType);
      return null;
    };
    check(runInterpreter(result, [])).equals(null);
  }

  test_multipleParameters_first() async {
    var result = await resolveTestCodeWithDiagnostics('''
test(int i, int j) => i;
''');
    analyze(result, result.findNode.singleFunctionDeclaration);
    check(runInterpreter(result, [123, 456])).equals(123);
  }

  test_multipleParameters_second() async {
    var result = await resolveTestCodeWithDiagnostics('''
test(int i, int j) => j;
''');
    analyze(result, result.findNode.singleFunctionDeclaration);
    check(runInterpreter(result, [123, 456])).equals(456);
  }

  test_noReturnAtEndOfFunction() async {
    var result = await resolveTestCodeWithDiagnostics('''
test() {}
''');
    analyze(result, result.findNode.singleFunctionDeclaration);
    check(runInterpreter(result, [])).equals(null);
  }

  test_nullLiteral() async {
    var result = await resolveTestCodeWithDiagnostics('''
test() => null;
''');
    analyze(result, result.findNode.singleFunctionDeclaration);
    check(astNodes).containsNode(result.findNode.nullLiteral('null'));
    check(runInterpreter(result, [])).equals(null);
  }

  test_parenthesizedExpression() async {
    var result = await resolveTestCodeWithDiagnostics('''
test(int i) => (i);
''');
    analyze(result, result.findNode.singleFunctionDeclaration);
    check(astNodes)[result.findNode.parenthesized('(i)')].containsSubrange(
      astNodes[result.findNode.simple('i);')]!,
    );
    check(runInterpreter(result, [123])).equals(123);
  }

  test_parenthesizedExpression_stopsNullShorting() async {
    var result = await resolveTestCodeWithDiagnostics('''
test(List<Object?>? list) => (list?.first).hashCode;
''');
    analyze(result, result.findNode.singleFunctionDeclaration);
    check(runInterpreter(result, [null])).equals(null.hashCode);
    check(
      runInterpreter(result, [
        makeList(result, [123]),
      ]),
    ).equals(123.hashCode);
  }

  test_postfixExpression_decrement_property_nullShorting() async {
    var result = await resolveTestCodeWithDiagnostics('''
test(List? l) => l?.length--;
''');
    analyze(result, result.findNode.singleFunctionDeclaration);
    check(astNodes)[result.findNode.postfix('l?.length--')]
      ..containsSubrange(astNodes[result.findNode.simple('l?.length')]!)
      ..containsSubrange(
        astNodes[result.findNode.propertyAccess('l?.length')]!,
      );
    check(runInterpreter(result, [null])).equals(null);
    var l = ['a', 'b', 'c', 'd', 'e'];
    check(runInterpreter(result, [makeList(result, l)])).equals(5);
    check(l).deepEquals(['a', 'b', 'c', 'd']);
  }

  test_postfixExpression_decrement_property_prefixedIdentifier() async {
    var result = await resolveTestCodeWithDiagnostics('''
test(List l) => l.length--;
''');
    analyze(result, result.findNode.singleFunctionDeclaration);
    check(astNodes)[result.findNode.postfix('l.length--')]
      ..containsSubrange(astNodes[result.findNode.simple('l.length')]!)
      ..containsSubrange(astNodes[result.findNode.prefixed('l.length')]!);
    var l = ['a', 'b', 'c', 'd', 'e'];
    check(runInterpreter(result, [makeList(result, l)])).equals(5);
    check(l).deepEquals(['a', 'b', 'c', 'd']);
  }

  test_postfixExpression_decrement_property_propertyAccess() async {
    var result = await resolveTestCodeWithDiagnostics('''
test(List l) => (l).length--;
''');
    analyze(result, result.findNode.singleFunctionDeclaration);
    check(astNodes)[result.findNode.postfix('(l).length--')]
      ..containsSubrange(astNodes[result.findNode.parenthesized('(l)')]!)
      ..containsSubrange(
        astNodes[result.findNode.propertyAccess('(l).length')]!,
      );
    var l = ['a', 'b', 'c', 'd', 'e'];
    check(runInterpreter(result, [makeList(result, l)])).equals(5);
    check(l).deepEquals(['a', 'b', 'c', 'd']);
  }

  test_postfixExpression_decrement_property_simpleIdentifier() async {
    var result = await resolveTestCodeWithDiagnostics('''
extension E on List {
  test() => length--;
}
''');
    analyze(result, result.findNode.singleMethodDeclaration);
    check(astNodes)[result.findNode.postfix('length--')].containsSubrange(
      astNodes[result.findNode.simple('length')]!,
    );
    var l = ['a', 'b', 'c', 'd', 'e'];
    check(runInterpreter(result, [makeList(result, l)])).equals(5);
    check(l).deepEquals(['a', 'b', 'c', 'd']);
  }

  test_postfixExpression_increment_local_sideEffect() async {
    var result = await resolveTestCodeWithDiagnostics('''
test() {
  int i = 123;
  i++;
  return i;
}
''');
    analyze(result, result.findNode.singleFunctionDeclaration);
    check(astNodes)[result.findNode.postfix('i++')].containsSubrange(
      astNodes[result.findNode.simple('i++')]!,
    );
    check(runInterpreter(result, [])).equals(124);
  }

  test_postfixExpression_increment_local_value() async {
    var result = await resolveTestCodeWithDiagnostics('''
test() {
  int i = 123;
  return i++;
}
''');
    analyze(result, result.findNode.singleFunctionDeclaration);
    check(astNodes)[result.findNode.postfix('i++')].containsSubrange(
      astNodes[result.findNode.simple('i++')]!,
    );
    check(runInterpreter(result, [])).equals(123);
  }

  test_postfixExpression_increment_parameter_sideEffect() async {
    var result = await resolveTestCodeWithDiagnostics('''
test(int i) {
  i++;
  return i;
}
''');
    analyze(result, result.findNode.singleFunctionDeclaration);
    check(astNodes)[result.findNode.postfix('i++')].containsSubrange(
      astNodes[result.findNode.simple('i++')]!,
    );
    check(runInterpreter(result, [123])).equals(124);
  }

  test_postfixExpression_increment_parameter_value() async {
    var result = await resolveTestCodeWithDiagnostics('''
test(int i) => i++;
''');
    analyze(result, result.findNode.singleFunctionDeclaration);
    check(astNodes)[result.findNode.postfix('i++')].containsSubrange(
      astNodes[result.findNode.simple('i++')]!,
    );
    check(runInterpreter(result, [123])).equals(123);
  }

  test_prefixExpression_decrement_property_nullShorting() async {
    var result = await resolveTestCodeWithDiagnostics('''
test(List? l) => --l?.length;
''');
    analyze(result, result.findNode.singleFunctionDeclaration);
    check(astNodes)[result.findNode.prefix('--l?.length')]
      ..containsSubrange(astNodes[result.findNode.simple('l?.length')]!)
      ..containsSubrange(
        astNodes[result.findNode.propertyAccess('l?.length')]!,
      );
    check(runInterpreter(result, [null])).equals(null);
    var l = ['a', 'b', 'c', 'd', 'e'];
    check(runInterpreter(result, [makeList(result, l)])).equals(4);
    check(l).deepEquals(['a', 'b', 'c', 'd']);
  }

  test_prefixExpression_decrement_property_prefixedIdentifier() async {
    var result = await resolveTestCodeWithDiagnostics('''
test(List l) => --l.length;
''');
    analyze(result, result.findNode.singleFunctionDeclaration);
    check(astNodes)[result.findNode.prefix('--l.length')]
      ..containsSubrange(astNodes[result.findNode.simple('l.length')]!)
      ..containsSubrange(astNodes[result.findNode.prefixed('l.length')]!);
    var l = ['a', 'b', 'c', 'd', 'e'];
    check(runInterpreter(result, [makeList(result, l)])).equals(4);
    check(l).deepEquals(['a', 'b', 'c', 'd']);
  }

  test_prefixExpression_decrement_property_propertyAccess() async {
    var result = await resolveTestCodeWithDiagnostics('''
test(List l) => --(l).length;
''');
    analyze(result, result.findNode.singleFunctionDeclaration);
    check(astNodes)[result.findNode.prefix('--(l).length')]
      ..containsSubrange(astNodes[result.findNode.parenthesized('(l)')]!)
      ..containsSubrange(
        astNodes[result.findNode.propertyAccess('(l).length')]!,
      );
    var l = ['a', 'b', 'c', 'd', 'e'];
    check(runInterpreter(result, [makeList(result, l)])).equals(4);
    check(l).deepEquals(['a', 'b', 'c', 'd']);
  }

  test_prefixExpression_decrement_property_simpleIdentifier() async {
    var result = await resolveTestCodeWithDiagnostics('''
extension E on List {
  test() => --length;
}
''');
    analyze(result, result.findNode.singleMethodDeclaration);
    check(astNodes)[result.findNode.prefix('--length')].containsSubrange(
      astNodes[result.findNode.simple('length')]!,
    );
    var l = ['a', 'b', 'c', 'd', 'e'];
    check(runInterpreter(result, [makeList(result, l)])).equals(4);
    check(l).deepEquals(['a', 'b', 'c', 'd']);
  }

  test_prefixExpression_increment_local_sideEffect() async {
    var result = await resolveTestCodeWithDiagnostics('''
test() {
  int i = 123;
  ++i; // increment
  return i;
}
''');
    analyze(result, result.findNode.singleFunctionDeclaration);
    check(astNodes)[result.findNode.prefix('++i')].containsSubrange(
      astNodes[result.findNode.simple('i; // increment')]!,
    );
    check(runInterpreter(result, [])).equals(124);
  }

  test_prefixExpression_increment_local_value() async {
    var result = await resolveTestCodeWithDiagnostics('''
test() {
  int i = 123;
  return ++i;
}
''');
    analyze(result, result.findNode.singleFunctionDeclaration);
    check(astNodes)[result.findNode.prefix('++i')].containsSubrange(
      astNodes[result.findNode.simple('i;')]!,
    );
    check(runInterpreter(result, [])).equals(124);
  }

  test_prefixExpression_increment_parameter_sideEffect() async {
    var result = await resolveTestCodeWithDiagnostics('''
test(int i) {
  ++i; // increment
  return i;
}
''');
    analyze(result, result.findNode.singleFunctionDeclaration);
    check(astNodes)[result.findNode.prefix('++i')].containsSubrange(
      astNodes[result.findNode.simple('i; // increment')]!,
    );
    check(runInterpreter(result, [123])).equals(124);
  }

  test_prefixExpression_increment_parameter_value() async {
    var result = await resolveTestCodeWithDiagnostics('''
test(int i) => ++i;
''');
    analyze(result, result.findNode.singleFunctionDeclaration);
    check(astNodes)[result.findNode.prefix('++i')].containsSubrange(
      astNodes[result.findNode.simple('i;')]!,
    );
    check(runInterpreter(result, [123])).equals(124);
  }

  test_prefixExpression_not() async {
    var result = await resolveTestCodeWithDiagnostics('''
test(bool b) => !b;
''');
    analyze(result, result.findNode.singleFunctionDeclaration);
    check(astNodes)[result.findNode.prefix('!b')].containsSubrange(
      astNodes[result.findNode.simple('b;')]!,
    );
    check(runInterpreter(result, [true])).equals(false);
    check(runInterpreter(result, [false])).equals(true);
  }

  test_propertyAccess_allowsNullShorting() async {
    var result = await resolveTestCodeWithDiagnostics('''
test(List<Object?>? list) => list?.first.hashCode;
''');
    analyze(result, result.findNode.singleFunctionDeclaration);
    check(runInterpreter(result, [null])).equals(null);
    check(
      runInterpreter(result, [
        makeList(result, [123]),
      ]),
    ).equals(123.hashCode);
  }

  test_propertyAccess_nestedNullShorting() async {
    var result = await resolveTestCodeWithDiagnostics('''
test(List<Object?>? list) => list?.first?.hashCode;
''');
    analyze(result, result.findNode.singleFunctionDeclaration);
    check(
          astNodes,
          because: 'both null checks should use the same block',
        )[result.findNode.singleFunctionBody].instructions
        .withOpcode(Opcode.block)
        .hasLength(1);
    check(runInterpreter(result, [null])).equals(null);
    check(
      runInterpreter(result, [
        makeList(result, [123]),
      ]),
    ).equals(123.hashCode);
  }

  test_propertyGet_nullShorting() async {
    var result = await resolveTestCodeWithDiagnostics('''
test(String? s) => s?.length;
''');
    analyze(result, result.findNode.singleFunctionDeclaration);
    check(astNodes)[result.findNode.propertyAccess('s?.length')]
        .containsSubrange(astNodes[result.findNode.simple('s?.length')]!);
    check(runInterpreter(result, [null])).equals(null);
    check(runInterpreter(result, ['foo'])).equals(3);
  }

  test_propertyGet_prefixedIdentifier() async {
    var result = await resolveTestCodeWithDiagnostics('''
test(int i) => i.isEven;
''');
    analyze(result, result.findNode.singleFunctionDeclaration);
    check(astNodes)[result.findNode.prefixed('i.isEven')].containsSubrange(
      astNodes[result.findNode.simple('i.')]!,
    );
    check(runInterpreter(result, [1])).equals(false);
    check(runInterpreter(result, [2])).equals(true);
  }

  test_propertyGet_propertyAccess() async {
    var result = await resolveTestCodeWithDiagnostics('''
test() => 'foo'.length;
''');
    analyze(result, result.findNode.singleFunctionDeclaration);
    check(astNodes)[result.findNode.propertyAccess("'foo'.length")]
        .containsSubrange(astNodes[result.findNode.stringLiteral("'foo'")]!);
    check(runInterpreter(result, [])).equals(3);
  }

  test_propertyGet_simpleIdentifier() async {
    var result = await resolveTestCodeWithDiagnostics('''
extension E on String {
  test() => length;
}
''');
    analyze(result, result.findNode.singleMethodDeclaration);
    check(astNodes).containsNode(result.findNode.simple('length'));
    check(runInterpreter(result, ['foo'])).equals(3);
  }

  test_returnStatement_noValue() async {
    var result = await resolveTestCodeWithDiagnostics('''
test() {
  return;
  return 1; // ignore: dead_code
}
''');
    analyze(result, result.findNode.singleFunctionDeclaration);
    check(astNodes).containsNode(result.findNode.returnStatement('return;'));
    check(runInterpreter(result, [])).equals(null);
  }

  test_returnStatement_value() async {
    var result = await resolveTestCodeWithDiagnostics('''
test() {
  return 123;
  return 1; // ignore: dead_code
}
''');
    analyze(result, result.findNode.singleFunctionDeclaration);
    check(astNodes)[result.findNode.returnStatement('return 123')]
        .containsSubrange(astNodes[result.findNode.integerLiteral('123')]!);
    check(runInterpreter(result, [])).equals(123);
  }

  test_simpleIdentifier_local() async {
    var result = await resolveTestCodeWithDiagnostics('''
test() {
  var i = 123;
  return i;
}
''');
    analyze(result, result.findNode.singleFunctionDeclaration);
    check(astNodes).containsNode(result.findNode.simple('i;'));
    check(runInterpreter(result, [])).equals(123);
  }

  test_simpleIdentifier_parameter() async {
    var result = await resolveTestCodeWithDiagnostics('''
test(int i) => i;
''');
    analyze(result, result.findNode.singleFunctionDeclaration);
    check(astNodes).containsNode(result.findNode.simple('i;'));
    check(runInterpreter(result, [123])).equals(123);
  }

  test_stringInterpolation_withBraces() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
test(int x) => 'x = ${x}';
''');
    analyze(result, result.findNode.singleFunctionDeclaration);
    check(astNodes)[result.findNode.stringInterpolation('x =')]
      ..containsSubrange(astNodes[result.findNode.interpolationString('x =')]!)
      ..containsSubrange(
        astNodes[result.findNode.interpolationExpression(r'${x}')]!,
      );
    check(runInterpreter(result, [123])).equals('x = 123');
  }

  test_stringInterpolation_withoutBraces() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
test(int x) => 'x = $x';
''');
    analyze(result, result.findNode.singleFunctionDeclaration);
    check(astNodes)[result.findNode.stringInterpolation('x =')]
      ..containsSubrange(astNodes[result.findNode.interpolationString('x =')]!)
      ..containsSubrange(
        astNodes[result.findNode.interpolationExpression(r'$x')]!,
      );
    check(runInterpreter(result, [123])).equals('x = 123');
  }

  test_stringLiteral() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
test() => 'foo';
''');
    analyze(result, result.findNode.singleFunctionDeclaration);
    check(astNodes).containsNode(result.findNode.stringLiteral('foo'));
    check(runInterpreter(result, [])).equals('foo');
  }

  test_thisExpression() async {
    var result = await resolveTestCodeWithDiagnostics('''
class C {
  test() => this;
}
''');
    analyze(result, result.findNode.singleMethodDeclaration);
    check(astNodes).containsNode(result.findNode.this_('this'));
    var thisValue = Instance(result.findElement.class_('C').thisType);
    check(runInterpreter(result, [thisValue])).identicalTo(thisValue);
  }

  test_variableDeclarationList_singleVariable_initialized() async {
    var result = await resolveTestCodeWithDiagnostics('''
test() {
  int i = 123;
  return i;
}
''');
    analyze(result, result.findNode.singleFunctionDeclaration);
    check(astNodes)[result.findNode.variableDeclarationList('int i = 123')]
        .containsSubrange(astNodes[result.findNode.integerLiteral('123')]!);
    check(runInterpreter(result, [])).identicalTo(123);
  }

  test_variableDeclarationList_singleVariable_uninitialized_nonNullable() async {
    var result = await resolveTestCodeWithDiagnostics('''
test() {
  int i; // ignore: unused_local_variable
  return 123;
}
''');
    analyze(result, result.findNode.singleFunctionDeclaration);
    check(astNodes)[result.findNode.variableDeclarationList('int i')].not(
      (s) => s.instructions.any((s) => s.opcode.equals(Opcode.writeLocal)),
    );
    check(runInterpreter(result, [])).identicalTo(123);
  }

  test_variableDeclarationList_singleVariable_uninitialized_nullable() async {
    var result = await resolveTestCodeWithDiagnostics('''
test() {
  int? i;
  return i;
}
''');
    analyze(result, result.findNode.singleFunctionDeclaration);
    check(
      astNodes,
    ).containsNode(result.findNode.variableDeclarationList('int? i'));
    check(runInterpreter(result, [])).identicalTo(null);
  }

  test_variableDeclarationList_singleVariable_uninitialized_unsound() async {
    var result = await resolveTestCodeWithDiagnostics('''
test() {
  int i;
  return i; // UNSOUND
//       ^
// [diag.notAssignedPotentiallyNonNullableLocalVariable] The non-nullable local variable 'i' must be assigned before it can be used.
}
''');
    analyze(result, result.findNode.singleFunctionDeclaration);
    check(astNodes)[result.findNode.variableDeclarationList('int i')].not(
      (s) => s.instructions.any((s) => s.opcode.equals(Opcode.writeLocal)),
    );
    check(() => runInterpreter(result, [])).throws<SoundnessError>()
      ..address.equals(astNodes[result.findNode.simple('i; // UNSOUND')]!.start)
      ..message.equals('Read of unset local');
  }

  test_variableDeclarationList_twoVariables_first() async {
    var result = await resolveTestCodeWithDiagnostics('''
test() {
  int i = 123, j = 456; // ignore: unused_local_variable
  return i;
}
''');
    analyze(result, result.findNode.singleFunctionDeclaration);
    check(astNodes)[result.findNode.variableDeclarationList('int i = 123')]
      ..containsSubrange(astNodes[result.findNode.integerLiteral('123')]!)
      ..containsSubrange(astNodes[result.findNode.integerLiteral('456')]!);
    check(runInterpreter(result, [])).identicalTo(123);
  }

  test_variableDeclarationList_twoVariables_second() async {
    var result = await resolveTestCodeWithDiagnostics('''
test() {
  int i = 123, j = 456; // ignore: unused_local_variable
  return j;
}
''');
    analyze(result, result.findNode.singleFunctionDeclaration);
    check(astNodes)[result.findNode.variableDeclarationList('int i = 123')]
      ..containsSubrange(astNodes[result.findNode.integerLiteral('123')]!)
      ..containsSubrange(astNodes[result.findNode.integerLiteral('456')]!);
    check(runInterpreter(result, [])).identicalTo(456);
  }

  test_variableDeclarationStatement() async {
    var result = await resolveTestCodeWithDiagnostics('''
test() {
  int i = 123; // ignore: unused_local_variable
}
''');
    analyze(result, result.findNode.singleFunctionDeclaration);
    check(astNodes)[result.findNode.variableDeclarationStatement('int i = 123')]
        .containsSubrange(
          astNodes[result.findNode.variableDeclarationList('int i = 123')]!,
        );
    check(runInterpreter(result, [])).identicalTo(null);
  }

  test_whileStatement_simple() async {
    var result = await resolveTestCodeWithDiagnostics('''
test(int count, List<int> result) {
  while (count-- > 0) {
    result.add(count);
  }
}
''');
    analyze(result, result.findNode.singleFunctionDeclaration);
    check(astNodes)[result.findNode.whileStatement('while')]
      ..containsSubrange(astNodes[result.findNode.binary('count-- > 0')]!)
      ..containsSubrange(astNodes[result.findNode.block('result.add')]!);
    var values = <int>[];
    check(runInterpreter(result, [5, makeList(result, values)])).equals(null);
    check(values).deepEquals([4, 3, 2, 1, 0]);
  }

  test_yieldStatement() async {
    var result = await resolveTestCodeWithDiagnostics('''
test(Object? o) sync* {
  yield o;
}
''');
    analyze(result, result.findNode.singleFunctionDeclaration);
    check(astNodes)[result.findNode.yieldStatement('yield')].containsSubrange(
      astNodes[result.findNode.simple('o;')]!,
    );
    _onYield = (value) {
      check(value).equals(123);
      hook(null, 'onYield');
    };
    expectHooks([
      'onYield',
    ], () => check(runInterpreter(result, [123])).equals(null));
  }

  static CallHandler binaryFunction<T, U>(Object? Function(T, U) f) =>
      (callDescriptor, positionalArguments, namedArguments) {
        check(callDescriptor.typeArguments).isEmpty;
        check(positionalArguments).length.equals(2);
        check(namedArguments).isEmpty();
        return f(positionalArguments[0] as T, positionalArguments[1] as U);
      };

  static CallHandler nullaryFunction(Object? Function() f) =>
      (callDescriptor, positionalArguments, namedArguments) {
        check(callDescriptor.typeArguments).isEmpty;
        check(positionalArguments).isEmpty();
        check(namedArguments).isEmpty();
        return f();
      };

  static CallHandler unaryFunction<T>(Object? Function(T) f) =>
      (callDescriptor, positionalArguments, namedArguments) {
        check(callDescriptor.typeArguments).isEmpty;
        check(positionalArguments).length.equals(1);
        check(namedArguments).isEmpty();
        return f(positionalArguments[0] as T);
      };
}

class AstToIRTestBase extends PubPackageResolutionTest {
  final astNodes = AstNodes();
  late final CodedIRContainer ir;
  late final Scopes scopes;

  void analyze(TestResolvedUnitResult result, Declaration declaration) {
    switch (declaration) {
      case FunctionDeclaration():
        var declaredElement = declaration.declaredFragment!.element;
        ir = astToIR(
          declaredElement,
          declaration.functionExpression.body,
          typeProvider: result.typeProvider,
          typeSystem: result.typeSystem,
          inheritanceManager: result.inheritanceManager,
          eventListener: astNodes,
        );
      case MethodDeclaration():
        var declaredElement = declaration.declaredFragment!.element;
        ir = astToIR(
          declaredElement,
          declaration.body,
          typeProvider: result.typeProvider,
          typeSystem: result.typeSystem,
          inheritanceManager: result.inheritanceManager,
          eventListener: astNodes,
        );
      default:
        throw UnimplementedError('TODO(paulberry): $declaration');
    }
    validate(ir);
    scopes = analyzeScopes(ir);
  }
}

/// Interpreter representation of a [List] object.
class ListInstance extends Instance {
  final List<Object?> values;

  ListInstance(super.type, this.values);
}

class _CallDispatcher implements CallDispatcher {
  final AstToIRTest _test;

  _CallDispatcher(this._test);

  @override
  Object? await_(Instance future) {
    if (_test._onAwait case var onAwait?) {
      return onAwait(future);
    } else {
      fail('Unexpected await');
    }
  }

  @override
  bool equals(Object firstValue, Object secondValue) {
    if (firstValue is Literal) {
      throw UnimplementedError('TODO(paulberry): call custom operator==');
    }
    return firstValue == secondValue;
  }

  @override
  CallHandler lookupCallDescriptor(CallDescriptor callDescriptor) {
    CallHandler? handler;
    switch (callDescriptor) {
      case ElementCallDescriptor(:var name, :var element):
        if (element.enclosingElement case InstanceElement(name: var typeName)) {
          name = '${typeName ?? '<unnamed>'}.$name';
        }
        handler = _test._callHandlers[name];
    }
    if (handler == null) {
      throw StateError('No handler for $callDescriptor');
    }
    return handler;
  }

  @override
  void yield_(Object? value) {
    if (_test._onYield case var onYield?) {
      onYield(value);
    } else {
      fail('Unexpected yield');
    }
  }
}

extension on Subject<SoundnessError> {
  Subject<int> get address => has((e) => e.address, 'address');
  Subject<String> get message => has((e) => e.message, 'message');
}
