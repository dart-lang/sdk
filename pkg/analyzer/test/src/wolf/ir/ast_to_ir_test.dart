// Copyright (c) 2023, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/src/error/codes.dart';
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
import 'utils.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(AstToIRTest);
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
    'Iterable.length':
        unaryFunction<ListInstance>((list) => list.values.length),
    'List.add': binaryFunction<ListInstance, Object?>(
        (list, value) => list.values.add(value)),
    'List.first=': binaryFunction<ListInstance, Object?>(
        (list, value) => list.values.first = value),
    'List.length=': binaryFunction<ListInstance, int>(
        (list, newLength) => list.values.length = newLength),
    'num.+': binaryFunction<num, num>((x, y) => x + y),
    'num.-': binaryFunction<num, num>((x, y) => x - y),
    'num.>': binaryFunction<num, num>((x, y) => x > y),
    'num.>=': binaryFunction<num, num>((x, y) => x >= y),
    'num.<': binaryFunction<num, num>((x, y) => x < y),
    'Object.hashCode': unaryFunction<Object?>((o) => o.hashCode),
    'String.contains':
        binaryFunction<String, String>((this_, other) => this_.contains(other)),
    'String.length': unaryFunction<String>((s) => s.length)
  };

  final _expectedHooks = <String>[];

  Object? Function(Instance)? _onAwait;

  void Function(Object?)? _onYield;

  Future<void> checkBinaryOp(String op) async {
    await assertNoErrorsInCode('''
class C {
  external int operator $op(int other);
}
test(C c, int other) => c $op other;
''');
    analyze(findNode.singleFunctionDeclaration);
    check(astNodes)[findNode.binary('c $op other')]
      ..containsSubrange(astNodes[findNode.simple('c $op')]!)
      ..containsSubrange(astNodes[findNode.simple('other;')]!);
    var c = Instance(findElement.class_('C').thisType);
    _callHandlers['C.$op'] = binaryFunction<Instance, int>((this_, other) {
      check(this_).identicalTo(c);
      check(other).equals(123);
      return 456;
    });
    check(runInterpreter([c, 123])).equals(456);
  }

  Future<void> checkBinaryOpEq(String op) async {
    await assertNoErrorsInCode('''
class C {
  external C operator $op(int other);
}
test(List<C> list, int other) => list.first $op= other;
''');
    analyze(findNode.singleFunctionDeclaration);
    check(astNodes)[findNode.assignment('list.first $op= other')]
      ..containsSubrange(astNodes[findNode.simple('list.first')]!)
      ..containsSubrange(astNodes[findNode.prefixed('list.first')]!)
      ..containsSubrange(astNodes[findNode.simple('other;')]!);
    var c = Instance(findElement.class_('C').thisType);
    var result = Instance(findElement.class_('C').thisType);
    _callHandlers['C.$op'] = binaryFunction<Instance, int>((this_, other) {
      check(this_).identicalTo(c);
      check(other).equals(123);
      return result;
    });
    var values = [c];
    check(runInterpreter([makeList(values), 123])).identicalTo(result);
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

  ListInstance makeList(List<Object?> values) => ListInstance(
      typeProvider.listType(typeProvider.objectQuestionType), values);

  Object? runInterpreter(List<Object?> args) => interpret(ir, args,
      scopes: scopes,
      callDispatcher: _CallDispatcher(this),
      typeProvider: typeProvider,
      typeSystem: typeSystem);

  test_adjacentStrings() async {
    await assertNoErrorsInCode('''
test() => 'foo' " " 'bar';
''');
    analyze(findNode.singleFunctionDeclaration);
    check(astNodes)[findNode.adjacentStrings('foo')]
      ..containsSubrange(astNodes[findNode.stringLiteral('foo')]!)
      ..containsSubrange(astNodes[findNode.stringLiteral('" "')]!)
      ..containsSubrange(astNodes[findNode.stringLiteral('bar')]!);
    check(runInterpreter([])).equals('foo bar');
  }

  test_assignmentExpression_binaryAndEq() => checkBinaryOpEq('&');

  test_assignmentExpression_binaryOrEq() => checkBinaryOpEq('|');

  test_assignmentExpression_binaryXorEq() => checkBinaryOpEq('^');

  test_assignmentExpression_divideEq() => checkBinaryOpEq('/');

  test_assignmentExpression_integerDivideEq() => checkBinaryOpEq('~/');

  test_assignmentExpression_leftShiftEq() => checkBinaryOpEq('<<');

  test_assignmentExpression_local_compound_sideEffect() async {
    await assertNoErrorsInCode('''
test() {
  int i = 123;
  i += 456;
  return i;
}
''');
    analyze(findNode.singleFunctionDeclaration);
    check(astNodes)[findNode.assignment('i +=')]
      ..containsSubrange(astNodes[findNode.simple('i +=')]!)
      ..containsSubrange(astNodes[findNode.integerLiteral('456')]!);
    check(runInterpreter([])).equals(579);
  }

  test_assignmentExpression_local_compound_value() async {
    await assertNoErrorsInCode('''
test() {
  int i = 123;
  return i += 456;
}
''');
    analyze(findNode.singleFunctionDeclaration);
    check(astNodes)[findNode.assignment('i +=')]
      ..containsSubrange(astNodes[findNode.simple('i +=')]!)
      ..containsSubrange(astNodes[findNode.integerLiteral('456')]!);
    check(runInterpreter([])).equals(579);
  }

  test_assignmentExpression_local_ifNull_sideEffect() async {
    await assertNoErrorsInCode('''
external int? hook(int? x, String s);
test(int? i) {
  int? j = i;
  j ??= hook(123, '123');
  return j;
}
''');
    analyze(findNode.functionDeclaration('test'));
    check(astNodes)[findNode.assignment('j ??=')]
      ..containsSubrange(astNodes[findNode.simple('j ??=')]!)
      ..containsSubrange(
          astNodes[findNode.methodInvocation("hook(123, '123')")]!);
    expectHooks(['123'], () => check(runInterpreter([null])).equals(123));
    expectHooks([], () => check(runInterpreter([1])).equals(1));
  }

  test_assignmentExpression_local_ifNull_value() async {
    await assertNoErrorsInCode('''
external int? hook(int? x, String s);
test(int? i) {
  int? j = i; // ignore: unused_local_variable
  return j ??= hook(123, '123');
}
''');
    analyze(findNode.functionDeclaration('test'));
    check(astNodes)[findNode.assignment('j ??=')]
      ..containsSubrange(astNodes[findNode.simple('j ??=')]!)
      ..containsSubrange(
          astNodes[findNode.methodInvocation("hook(123, '123')")]!);
    expectHooks(['123'], () => check(runInterpreter([null])).equals(123));
    expectHooks([], () => check(runInterpreter([1])).equals(1));
  }

  test_assignmentExpression_local_simple_sideEffect() async {
    await assertNoErrorsInCode('''
test() {
  int i;
  i = 123;
  return i;
}
''');
    analyze(findNode.singleFunctionDeclaration);
    check(astNodes)[findNode.assignment('i =')]
      ..containsSubrange(astNodes[findNode.simple('i =')]!)
      ..containsSubrange(astNodes[findNode.integerLiteral('123')]!);
    check(runInterpreter([])).equals(123);
  }

  test_assignmentExpression_local_simple_value() async {
    await assertNoErrorsInCode('''
test() {
  int i; // ignore: unused_local_variable
  return i = 123;
}
''');
    analyze(findNode.singleFunctionDeclaration);
    check(astNodes)[findNode.assignment('i =')]
      ..containsSubrange(astNodes[findNode.simple('i =')]!)
      ..containsSubrange(astNodes[findNode.integerLiteral('123')]!);
    check(runInterpreter([])).equals(123);
  }

  test_assignmentExpression_minusEq() => checkBinaryOpEq('-');

  test_assignmentExpression_modEq() => checkBinaryOpEq('%');

  test_assignmentExpression_parameter_compound_sideEffect() async {
    await assertNoErrorsInCode('''
test(int i) {
  i += 456;
  return i;
}
''');
    analyze(findNode.singleFunctionDeclaration);
    check(astNodes)[findNode.assignment('i +=')]
      ..containsSubrange(astNodes[findNode.simple('i +=')]!)
      ..containsSubrange(astNodes[findNode.integerLiteral('456')]!);
    check(runInterpreter([123])).equals(579);
  }

  test_assignmentExpression_parameter_compound_value() async {
    await assertNoErrorsInCode('''
test(int i) => i += 456;
''');
    analyze(findNode.singleFunctionDeclaration);
    check(astNodes)[findNode.assignment('i +=')]
      ..containsSubrange(astNodes[findNode.simple('i +=')]!)
      ..containsSubrange(astNodes[findNode.integerLiteral('456')]!);
    check(runInterpreter([123])).equals(579);
  }

  test_assignmentExpression_parameter_ifNull_sideEffect() async {
    await assertNoErrorsInCode('''
external int? hook(int? x, String s);
test(int? i) {
  i ??= hook(123, '123');
  return i;
}
''');
    analyze(findNode.functionDeclaration('test'));
    check(astNodes)[findNode.assignment('i ??=')]
      ..containsSubrange(astNodes[findNode.simple('i ??=')]!)
      ..containsSubrange(
          astNodes[findNode.methodInvocation("hook(123, '123')")]!);
    expectHooks(['123'], () => check(runInterpreter([null])).equals(123));
    expectHooks([], () => check(runInterpreter([1])).equals(1));
  }

  test_assignmentExpression_parameter_ifNull_value() async {
    await assertNoErrorsInCode('''
external int? hook(int? x, String s);
test(int? i) => i ??= hook(123, '123');
''');
    analyze(findNode.functionDeclaration('test'));
    check(astNodes)[findNode.assignment('i ??=')]
      ..containsSubrange(astNodes[findNode.simple('i ??=')]!)
      ..containsSubrange(
          astNodes[findNode.methodInvocation("hook(123, '123')")]!);
    expectHooks(['123'], () => check(runInterpreter([null])).equals(123));
    expectHooks([], () => check(runInterpreter([1])).equals(1));
  }

  test_assignmentExpression_parameter_simple_sideEffect() async {
    await assertNoErrorsInCode('''
test(int i) {
  i = 123;
  return i;
}
''');
    analyze(findNode.singleFunctionDeclaration);
    check(astNodes)[findNode.assignment('i =')]
      ..containsSubrange(astNodes[findNode.simple('i =')]!)
      ..containsSubrange(astNodes[findNode.integerLiteral('123')]!);
    check(runInterpreter([1])).equals(123);
  }

  test_assignmentExpression_parameter_simple_value() async {
    await assertNoErrorsInCode('''
test(int i) => i = 123;
''');
    analyze(findNode.singleFunctionDeclaration);
    check(astNodes)[findNode.assignment('i =')]
      ..containsSubrange(astNodes[findNode.simple('i =')]!)
      ..containsSubrange(astNodes[findNode.integerLiteral('123')]!);
    check(runInterpreter([1])).equals(123);
  }

  test_assignmentExpression_plusEq() => checkBinaryOpEq('+');

  test_assignmentExpression_property_nullShorting_compound() async {
    await assertNoErrorsInCode('''
test(List? l) => l?.length -= 2;
''');
    analyze(findNode.singleFunctionDeclaration);
    check(astNodes)[findNode.assignment('l?.length -= 2')]
      ..containsSubrange(astNodes[findNode.simple('l?.length')]!)
      ..containsSubrange(astNodes[findNode.propertyAccess('l?.length')]!)
      ..containsSubrange(astNodes[findNode.integerLiteral('2')]!);
    check(runInterpreter([null])).equals(null);
    var l = ['a', 'b', 'c', 'd', 'e'];
    check(runInterpreter([makeList(l)])).equals(3);
    check(l).deepEquals(['a', 'b', 'c']);
  }

  test_assignmentExpression_property_nullShorting_ifNull() async {
    await assertNoErrorsInCode('''
external int? hook(int? x, String s);
class C {
  int? p;
}
test(C? c) => c?.p ??= hook(123, '123');
''');
    analyze(findNode.functionDeclaration('test'));
    check(astNodes)[findNode.assignment("c?.p ??= hook(123, '123')")]
      ..containsSubrange(astNodes[findNode.simple('c?.p')]!)
      ..containsSubrange(astNodes[findNode.propertyAccess('c?.p')]!)
      ..containsSubrange(
          astNodes[findNode.methodInvocation("hook(123, '123')")]!);
    Object? p;
    _callHandlers['C.p'] = unaryFunction<Instance>((c) => hook(p, 'c.p'));
    _callHandlers['C.p='] = binaryFunction<Instance, int?>(
        (c, value) => hook(p = value, 'c.p=$value'));
    var c = Instance(findElement.class_('C').thisType);
    expectHooks([], () => check(runInterpreter([null])).equals(null));
    expectHooks(['c.p', '123', 'c.p=123'],
        () => check(runInterpreter([c])).equals(123));
    check(p).equals(123);
    p = 456;
    expectHooks(['c.p'], () => check(runInterpreter([c])).equals(456));
    check(p).equals(456);
  }

  test_assignmentExpression_property_nullShorting_simple() async {
    await assertNoErrorsInCode('''
test(List? l) => l?.length = 3;
''');
    analyze(findNode.singleFunctionDeclaration);
    check(astNodes)[findNode.assignment('l?.length = 3')]
      ..containsSubrange(astNodes[findNode.simple('l?.length')]!)
      ..containsSubrange(astNodes[findNode.propertyAccess('l?.length')]!)
      ..containsSubrange(astNodes[findNode.integerLiteral('3')]!);
    check(runInterpreter([null])).equals(null);
    var l = ['a', 'b', 'c', 'd', 'e'];
    check(runInterpreter([makeList(l)])).equals(3);
    check(l).deepEquals(['a', 'b', 'c']);
  }

  test_assignmentExpression_property_prefixedIdentifier_compound() async {
    await assertNoErrorsInCode('''
test(List l) => l.length -= 2;
''');
    analyze(findNode.singleFunctionDeclaration);
    check(astNodes)[findNode.assignment('l.length -= 2')]
      ..containsSubrange(astNodes[findNode.simple('l.length')]!)
      ..containsSubrange(astNodes[findNode.prefixed('l.length')]!)
      ..containsSubrange(astNodes[findNode.integerLiteral('2')]!);
    var l = ['a', 'b', 'c', 'd', 'e'];
    check(runInterpreter([makeList(l)])).equals(3);
    check(l).deepEquals(['a', 'b', 'c']);
  }

  test_assignmentExpression_property_prefixedIdentifier_ifNull() async {
    await assertNoErrorsInCode('''
external int? hook(int? x, String s);
class C {
  int? p;
}
test(C c) => c.p ??= hook(123, '123');
''');
    analyze(findNode.functionDeclaration('test'));
    check(astNodes)[findNode.assignment("c.p ??= hook(123, '123')")]
      ..containsSubrange(astNodes[findNode.simple('c.p')]!)
      ..containsSubrange(astNodes[findNode.prefixed('c.p')]!)
      ..containsSubrange(
          astNodes[findNode.methodInvocation("hook(123, '123')")]!);
    Object? p;
    _callHandlers['C.p'] = unaryFunction<Instance>((c) => hook(p, 'c.p'));
    _callHandlers['C.p='] = binaryFunction<Instance, int?>(
        (c, value) => hook(p = value, 'c.p=$value'));
    var c = Instance(findElement.class_('C').thisType);
    expectHooks(['c.p', '123', 'c.p=123'],
        () => check(runInterpreter([c])).equals(123));
    check(p).equals(123);
    p = 456;
    expectHooks(['c.p'], () => check(runInterpreter([c])).equals(456));
    check(p).equals(456);
  }

  test_assignmentExpression_property_prefixedIdentifier_simple() async {
    await assertNoErrorsInCode('''
test(List l) => l.length = 3;
''');
    analyze(findNode.singleFunctionDeclaration);
    check(astNodes)[findNode.assignment('l.length = 3')]
      ..containsSubrange(astNodes[findNode.simple('l.length')]!)
      ..containsSubrange(astNodes[findNode.prefixed('l.length')]!)
      ..containsSubrange(astNodes[findNode.integerLiteral('3')]!);
    var l = ['a', 'b', 'c', 'd', 'e'];
    check(runInterpreter([makeList(l)])).equals(3);
    check(l).deepEquals(['a', 'b', 'c']);
  }

  test_assignmentExpression_property_propertyAccess_compound() async {
    await assertNoErrorsInCode('''
test(List l) => (l).length -= 2;
''');
    analyze(findNode.singleFunctionDeclaration);
    check(astNodes)[findNode.assignment('(l).length -= 2')]
      ..containsSubrange(astNodes[findNode.parenthesized('(l)')]!)
      ..containsSubrange(astNodes[findNode.propertyAccess('(l).length')]!)
      ..containsSubrange(astNodes[findNode.integerLiteral('2')]!);
    var l = ['a', 'b', 'c', 'd', 'e'];
    check(runInterpreter([makeList(l)])).equals(3);
    check(l).deepEquals(['a', 'b', 'c']);
  }

  test_assignmentExpression_property_propertyAccess_ifNull() async {
    await assertNoErrorsInCode('''
external int? hook(int? x, String s);
class C {
  int? p;
}
test(C c) => (c).p ??= hook(123, '123');
''');
    analyze(findNode.functionDeclaration('test'));
    check(astNodes)[findNode.assignment("(c).p ??= hook(123, '123')")]
      ..containsSubrange(astNodes[findNode.parenthesized('(c)')]!)
      ..containsSubrange(astNodes[findNode.propertyAccess('(c).p')]!)
      ..containsSubrange(
          astNodes[findNode.methodInvocation("hook(123, '123')")]!);
    Object? p;
    _callHandlers['C.p'] = unaryFunction<Instance>((c) => hook(p, 'c.p'));
    _callHandlers['C.p='] = binaryFunction<Instance, int?>(
        (c, value) => hook(p = value, 'c.p=$value'));
    var c = Instance(findElement.class_('C').thisType);
    expectHooks(['c.p', '123', 'c.p=123'],
        () => check(runInterpreter([c])).equals(123));
    check(p).equals(123);
    p = 456;
    expectHooks(['c.p'], () => check(runInterpreter([c])).equals(456));
    check(p).equals(456);
  }

  test_assignmentExpression_property_propertyAccess_simple() async {
    await assertNoErrorsInCode('''
test(List l) => (l).length = 3;
''');
    analyze(findNode.singleFunctionDeclaration);
    check(astNodes)[findNode.assignment('(l).length = 3')]
      ..containsSubrange(astNodes[findNode.parenthesized('(l)')]!)
      ..containsSubrange(astNodes[findNode.propertyAccess('(l).length')]!)
      ..containsSubrange(astNodes[findNode.integerLiteral('3')]!);
    var l = ['a', 'b', 'c', 'd', 'e'];
    check(runInterpreter([makeList(l)])).equals(3);
    check(l).deepEquals(['a', 'b', 'c']);
  }

  test_assignmentExpression_property_simpleIdentifier_compound() async {
    await assertNoErrorsInCode('''
extension E on List {
  test() => length -= 2;
}
''');
    analyze(findNode.singleMethodDeclaration);
    check(astNodes)[findNode.assignment('length -= 2')]
      ..containsSubrange(astNodes[findNode.simple('length')]!)
      ..containsSubrange(astNodes[findNode.integerLiteral('2')]!);
    var l = ['a', 'b', 'c', 'd', 'e'];
    check(runInterpreter([makeList(l)])).equals(3);
    check(l).deepEquals(['a', 'b', 'c']);
  }

  test_assignmentExpression_property_simpleIdentifier_ifNull() async {
    await assertNoErrorsInCode('''
external int? hook(int? x, String s);
class C {
  int? p;
  test() => p ??= hook(123, '123');
}
''');
    analyze(findNode.methodDeclaration('test'));
    check(astNodes)[findNode.assignment("p ??= hook(123, '123')")]
      ..containsSubrange(astNodes[findNode.simple('p ??=')]!)
      ..containsSubrange(
          astNodes[findNode.methodInvocation("hook(123, '123')")]!);
    Object? p;
    _callHandlers['C.p'] = unaryFunction<Instance>((c) => hook(p, 'c.p'));
    _callHandlers['C.p='] = binaryFunction<Instance, int?>(
        (c, value) => hook(p = value, 'c.p=$value'));
    var c = Instance(findElement.class_('C').thisType);
    expectHooks(['c.p', '123', 'c.p=123'],
        () => check(runInterpreter([c])).equals(123));
    check(p).equals(123);
    p = 456;
    expectHooks(['c.p'], () => check(runInterpreter([c])).equals(456));
    check(p).equals(456);
  }

  test_assignmentExpression_property_simpleIdentifier_simple() async {
    await assertNoErrorsInCode('''
extension E on List {
  test() => length = 3;
}
''');
    analyze(findNode.singleMethodDeclaration);
    check(astNodes)[findNode.assignment('length = 3')]
      ..containsSubrange(astNodes[findNode.simple('length')]!)
      ..containsSubrange(astNodes[findNode.integerLiteral('3')]!);
    var l = ['a', 'b', 'c', 'd', 'e'];
    check(runInterpreter([makeList(l)])).equals(3);
    check(l).deepEquals(['a', 'b', 'c']);
  }

  test_assignmentExpression_rightShiftEq() => checkBinaryOpEq('>>');

  test_assignmentExpression_rightTripleShiftEq() => checkBinaryOpEq('>>>');

  test_assignmentExpression_timesEq() => checkBinaryOpEq('*');

  test_awaitExpression_future() async {
    await assertNoErrorsInCode('''
test(Future f) async => await f;
''');
    analyze(findNode.singleFunctionDeclaration);
    check(astNodes)[findNode.awaitExpression('await')]
        .containsSubrange(astNodes[findNode.simple('f;')]!);
    var f = Instance(typeProvider.futureType(typeProvider.intType));
    _onAwait = (operand) {
      check(operand).identicalTo(f);
      return 123;
    };
    check(runInterpreter([f])).equals(123);
  }

  test_binaryExpression_and() async {
    await assertNoErrorsInCode('''
external bool hook(bool b, String s);
test(bool x, bool y) => hook(x, 'x') && hook(y, 'y');
''');
    analyze(findNode.functionDeclaration('test'));
    check(astNodes)[findNode.binary("hook(x, 'x') && hook(y, 'y')")]
      ..containsSubrange(astNodes[findNode.methodInvocation("hook(x, 'x')")]!)
      ..containsSubrange(astNodes[findNode.methodInvocation("hook(y, 'y')")]!);
    expectHooks(
        ['x'], () => check(runInterpreter([false, false])).equals(false));
    expectHooks(
        ['x'], () => check(runInterpreter([false, true])).equals(false));
    expectHooks(
        ['x', 'y'], () => check(runInterpreter([true, false])).equals(false));
    expectHooks(
        ['x', 'y'], () => check(runInterpreter([true, true])).equals(true));
  }

  test_binaryExpression_binaryAnd() => checkBinaryOp('&');

  test_binaryExpression_binaryOr() => checkBinaryOp('|');

  test_binaryExpression_binaryXor() => checkBinaryOp('^');

  test_binaryExpression_divide() => checkBinaryOp('/');

  test_binaryExpression_equal() async {
    await assertNoErrorsInCode('''
test(Object? x, Object? y) => x == y;
''');
    analyze(findNode.singleFunctionDeclaration);
    check(astNodes)[findNode.binary('x == y')]
      ..containsSubrange(astNodes[findNode.simple('x ==')]!)
      ..containsSubrange(astNodes[findNode.simple('y;')]!);
    check(runInterpreter([null, null])).equals(true);
    check(runInterpreter([null, 1])).equals(false);
    check(runInterpreter([1, null])).equals(false);
    check(runInterpreter([1, 2])).equals(false);
    check(runInterpreter([1, 1])).equals(true);
  }

  test_binaryExpression_greaterThan() => checkBinaryOp('>');

  test_binaryExpression_greaterThanOrEqual() => checkBinaryOp('>=');

  test_binaryExpression_ifNull() async {
    await assertNoErrorsInCode('''
external Object? hook(Object? x, String s);
test(Object? x, Object? y) => hook(x, 'x') ?? hook(y, 'y');
''');
    analyze(findNode.functionDeclaration('test'));
    check(astNodes)[findNode.binary("hook(x, 'x') ?? hook(y, 'y')")]
      ..containsSubrange(astNodes[findNode.methodInvocation("hook(x, 'x')")]!)
      ..containsSubrange(astNodes[findNode.methodInvocation("hook(y, 'y')")]!);
    expectHooks(
        ['x', 'y'], () => check(runInterpreter([null, null])).equals(null));
    expectHooks(
        ['x', 'y'], () => check(runInterpreter([null, 456])).equals(456));
    expectHooks(['x'], () => check(runInterpreter([123, null])).equals(123));
    expectHooks(['x'], () => check(runInterpreter([123, 456])).equals(123));
  }

  test_binaryExpression_integerDivide() => checkBinaryOp('~/');

  test_binaryExpression_leftShift() => checkBinaryOp('<<');

  test_binaryExpression_lessThan() => checkBinaryOp('<');

  test_binaryExpression_lessThanOrEqual() => checkBinaryOp('<=');

  test_binaryExpression_minus() => checkBinaryOp('-');

  test_binaryExpression_mod() => checkBinaryOp('%');

  test_binaryExpression_notEqual() async {
    await assertNoErrorsInCode('''
test(Object? x, Object? y) => x != y;
''');
    analyze(findNode.singleFunctionDeclaration);
    check(astNodes)[findNode.binary('x != y')]
      ..containsSubrange(astNodes[findNode.simple('x !=')]!)
      ..containsSubrange(astNodes[findNode.simple('y;')]!);
    check(runInterpreter([null, null])).equals(false);
    check(runInterpreter([null, 1])).equals(true);
    check(runInterpreter([1, null])).equals(true);
    check(runInterpreter([1, 2])).equals(true);
    check(runInterpreter([1, 1])).equals(false);
  }

  test_binaryExpression_or() async {
    await assertNoErrorsInCode('''
external bool hook(bool b, String s);
test(bool x, bool y) => hook(x, 'x') || hook(y, 'y');
''');
    analyze(findNode.functionDeclaration('test'));
    check(astNodes)[findNode.binary("hook(x, 'x') || hook(y, 'y')")]
      ..containsSubrange(astNodes[findNode.methodInvocation("hook(x, 'x')")]!)
      ..containsSubrange(astNodes[findNode.methodInvocation("hook(y, 'y')")]!);
    expectHooks(
        ['x', 'y'], () => check(runInterpreter([false, false])).equals(false));
    expectHooks(
        ['x', 'y'], () => check(runInterpreter([false, true])).equals(true));
    expectHooks(['x'], () => check(runInterpreter([true, false])).equals(true));
    expectHooks(['x'], () => check(runInterpreter([true, true])).equals(true));
  }

  test_binaryExpression_plus() => checkBinaryOp('+');

  test_binaryExpression_rightShift() => checkBinaryOp('>>');

  test_binaryExpression_rightTripleShift() => checkBinaryOp('>>>');

  test_binaryExpression_times() => checkBinaryOp('*');

  test_block() async {
    await assertNoErrorsInCode('''
test(int i) {
  i = 123;
  i = 456;
  return i;
}
''');
    analyze(findNode.singleFunctionDeclaration);
    check(astNodes)[findNode.block('123')]
      ..containsSubrange(astNodes[findNode.expressionStatement('i = 123')]!)
      ..containsSubrange(astNodes[findNode.expressionStatement('i = 456')]!)
      ..containsSubrange(astNodes[findNode.returnStatement('return i')]!);
    check(runInterpreter([1])).equals(456);
  }

  test_blockFunctionBody() async {
    await assertNoErrorsInCode('''
test() {
  return 123;
}
''');
    analyze(findNode.singleFunctionDeclaration);
    check(astNodes)[findNode.blockFunctionBody('123')]
        .containsSubrange(astNodes[findNode.block('123')]!);
    check(runInterpreter([])).equals(123);
  }

  test_booleanLiteral() async {
    await assertNoErrorsInCode('''
test() => true;
''');
    analyze(findNode.singleFunctionDeclaration);
    check(astNodes).containsNode(findNode.booleanLiteral('true'));
    check(runInterpreter([])).equals(true);
  }

  test_breakStatement_fromDoLoop() async {
    await assertNoErrorsInCode('''
test(int count, List<int> result) {
  do {
    result.add(count--);
    if (count < 3) break;
  } while (count > 0);
}
''');
    analyze(findNode.singleFunctionDeclaration);
    check(astNodes).containsNode(findNode.breakStatement('break'));
    var values = <int>[];
    check(runInterpreter([5, makeList(values)])).equals(null);
    check(values).deepEquals([5, 4, 3]);
  }

  test_breakStatement_fromForStatement_forParts() async {
    await assertNoErrorsInCode('''
test(int count, List<int> result) {
  for (var i = 0; i < count; i++) {
    result.add(i);
    if (i >= 2) break;
  }
}
''');
    analyze(findNode.singleFunctionDeclaration);
    check(astNodes).containsNode(findNode.breakStatement('break'));
    var values = <int>[];
    check(runInterpreter([5, makeList(values)])).equals(null);
    check(values).deepEquals([0, 1, 2]);
  }

  test_breakStatement_fromWhileLoop() async {
    await assertNoErrorsInCode('''
test(int count, List<int> result) {
  while (count-- > 0) {
    result.add(count);
    if (count == 2) break;
  }
}
''');
    analyze(findNode.singleFunctionDeclaration);
    check(astNodes).containsNode(findNode.breakStatement('break'));
    var values = <int>[];
    check(runInterpreter([5, makeList(values)])).equals(null);
    check(values).deepEquals([4, 3, 2]);
  }

  test_conditionalExpression() async {
    await assertNoErrorsInCode('''
test(bool b) => b ? 1 : 2;
''');
    analyze(findNode.singleFunctionDeclaration);
    check(astNodes)[findNode.conditionalExpression('b ? 1 : 2')]
      ..containsSubrange(astNodes[findNode.simple('b ?')]!)
      ..containsSubrange(astNodes[findNode.integerLiteral('1')]!)
      ..containsSubrange(astNodes[findNode.integerLiteral('2')]!);
    check(runInterpreter([true])).equals(1);
    check(runInterpreter([false])).equals(2);
  }

  test_continueStatement_inDoLoop() async {
    await assertNoErrorsInCode('''
test(int count, List<int> result) {
  do {
    if ((--count).isEven) continue;
    result.add(count);
  } while (count > 0);
}
''');
    analyze(findNode.singleFunctionDeclaration);
    check(astNodes).containsNode(findNode.continueStatement('continue'));
    var values = <int>[];
    check(runInterpreter([5, makeList(values)])).equals(null);
    check(values).deepEquals([3, 1]);
  }

  test_continueStatement_inForStatement_forParts() async {
    await assertNoErrorsInCode('''
test(int count, List<int> result) {
  for (var i = 0; i < count; i++) {
    if (i.isEven) continue;
    result.add(i);
  }
}
''');
    analyze(findNode.singleFunctionDeclaration);
    check(astNodes).containsNode(findNode.continueStatement('continue'));
    var values = <int>[];
    check(runInterpreter([5, makeList(values)])).equals(null);
    check(values).deepEquals([1, 3]);
  }

  test_continueStatement_inWhileLoop() async {
    await assertNoErrorsInCode('''
test(int count, List<int> result) {
  while (count-- > 0) {
    if (count.isEven) continue;
    result.add(count);
  }
}
''');
    analyze(findNode.singleFunctionDeclaration);
    check(astNodes).containsNode(findNode.continueStatement('continue'));
    var values = <int>[];
    check(runInterpreter([5, makeList(values)])).equals(null);
    check(values).deepEquals([3, 1]);
  }

  test_doStatement_simple() async {
    await assertNoErrorsInCode('''
test(int count, List<int> result) {
  do {
    result.add(count--);
  } while (count > 0);
}
''');
    analyze(findNode.singleFunctionDeclaration);
    check(astNodes)[findNode.doStatement('do')]
      ..containsSubrange(astNodes[findNode.block('result.add')]!)
      ..containsSubrange(astNodes[findNode.binary('count > 0')]!);
    var values = <int>[];
    check(runInterpreter([5, makeList(values)])).equals(null);
    check(values).deepEquals([5, 4, 3, 2, 1]);
    values.clear();
    // Make sure the loop always runs at least once.
    check(runInterpreter([0, makeList(values)])).equals(null);
    check(values).deepEquals([0]);
  }

  test_doubleLiteral() async {
    await assertNoErrorsInCode('''
test() => 1.5;
''');
    analyze(findNode.singleFunctionDeclaration);
    check(astNodes).containsNode(findNode.doubleLiteral('1.5'));
    check(runInterpreter([])).equals(1.5);
  }

  test_expressionFunctionBody() async {
    await assertNoErrorsInCode('''
test() => 0;
''');
    analyze(findNode.singleFunctionDeclaration);
    check(astNodes)[findNode.expressionFunctionBody('0')]
        .containsSubrange(astNodes[findNode.integerLiteral('0')]!);
  }

  test_expressionStatement() async {
    await assertNoErrorsInCode('''
test(int i) {
  i = 123;
  return i;
}
''');
    analyze(findNode.singleFunctionDeclaration);
    check(astNodes)[findNode.expressionStatement('i = 123')]
        .containsSubrange(astNodes[findNode.assignment('i = 123')]!);
    check(runInterpreter([1])).equals(123);
  }

  test_forStatement_forParts_withDeclaration() async {
    await assertNoErrorsInCode('''
test(int count, List<int> result) {
  for (var i = 0; i < count; i++) {
    result.add(i);
  }
}
''');
    analyze(findNode.singleFunctionDeclaration);
    check(astNodes)[findNode.forStatement('for')]
      ..containsSubrange(
          astNodes[findNode.variableDeclarationList('var i = 0')]!)
      ..containsSubrange(astNodes[findNode.binary('i < count')]!)
      ..containsSubrange(astNodes[findNode.postfix('i++')]!)
      ..containsSubrange(astNodes[findNode.block('result.add')]!);
    var values = <int>[];
    check(runInterpreter([5, makeList(values)])).equals(null);
    check(values).deepEquals([0, 1, 2, 3, 4]);
  }

  test_ifStatement_noElse() async {
    await assertNoErrorsInCode('''
test(bool b) {
  Object? result;
  if (b /*test*/) {
    result = 1;
  }
  return result;
}
''');
    analyze(findNode.singleFunctionDeclaration);
    check(astNodes)[findNode.ifStatement('if')]
      ..containsSubrange(astNodes[findNode.simple('b /*test*/')]!)
      ..containsSubrange(astNodes[findNode.block('result = 1')]!);
    check(runInterpreter([true])).equals(1);
    check(runInterpreter([false])).equals(null);
  }

  test_ifStatement_noElse_earlyReturn() async {
    await assertNoErrorsInCode('''
test(bool b) {
  if (b /*test*/) {
    return 1;
  }
}
''');
    analyze(findNode.singleFunctionDeclaration);
    check(astNodes)[findNode.ifStatement('if')]
      ..containsSubrange(astNodes[findNode.simple('b /*test*/')]!)
      ..containsSubrange(astNodes[findNode.block('return 1')]!);
    check(runInterpreter([true])).equals(1);
    check(runInterpreter([false])).equals(null);
  }

  test_ifStatement_withElse() async {
    await assertNoErrorsInCode('''
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
    analyze(findNode.singleFunctionDeclaration);
    check(astNodes)[findNode.ifStatement('if')]
      ..containsSubrange(astNodes[findNode.simple('b /*test*/')]!)
      ..containsSubrange(astNodes[findNode.block('result = 1')]!)
      ..containsSubrange(astNodes[findNode.block('result = 2')]!);
    check(runInterpreter([true])).equals(1);
    check(runInterpreter([false])).equals(2);
  }

  test_ifStatement_withElse_earlyReturn() async {
    await assertNoErrorsInCode('''
test(bool b) {
  if (b /*test*/) {
    return 1;
  } else {
    return 2;
  }
}
''');
    analyze(findNode.singleFunctionDeclaration);
    check(astNodes)[findNode.ifStatement('if')]
      ..containsSubrange(astNodes[findNode.simple('b /*test*/')]!)
      ..containsSubrange(astNodes[findNode.block('return 1')]!)
      ..containsSubrange(astNodes[findNode.block('return 2')]!);
    check(runInterpreter([true])).equals(1);
    check(runInterpreter([false])).equals(2);
  }

  test_integerLiteral() async {
    await assertNoErrorsInCode('''
test() => 123;
''');
    analyze(findNode.singleFunctionDeclaration);
    check(astNodes).containsNode(findNode.integerLiteral('123'));
    check(runInterpreter([])).equals(123);
  }

  test_isExpression_inverted() async {
    await assertNoErrorsInCode('''
test(Object? o) => o is! String;
''');
    analyze(findNode.singleFunctionDeclaration);
    check(astNodes)[findNode.isExpression('is')]
        .containsSubrange(astNodes[findNode.simple('o is')]!);
    check(runInterpreter([123])).equals(true);
    check(runInterpreter(['123'])).equals(false);
  }

  test_isExpression_uninverted() async {
    await assertNoErrorsInCode('''
test(Object? o) => o is String;
''');
    analyze(findNode.singleFunctionDeclaration);
    check(astNodes)[findNode.isExpression('is')]
        .containsSubrange(astNodes[findNode.simple('o is')]!);
    check(runInterpreter([123])).equals(false);
    check(runInterpreter(['123'])).equals(true);
  }

  test_methodInvocation_identical() async {
    await assertNoErrorsInCode('''
test(Object? x, Object? y) => identical(x, y);
''');
    analyze(findNode.singleFunctionDeclaration);
    check(astNodes)[findNode.methodInvocation('identical(x, y)')]
      ..containsSubrange(astNodes[findNode.simple('x, y')]!)
      ..containsSubrange(astNodes[findNode.simple('y);')]!);
    var s1 = 's';
    var s2 = String.fromCharCode(s1.codeUnitAt(0));
    assert(!identical(s1, s2));
    check(runInterpreter([s1, s2])).equals(false);
    check(runInterpreter([s1, s1])).equals(true);
  }

  test_methodInvocation_identical_decoy() async {
    await assertNoErrorsInCode('''
external bool identical(Object? x, Object? y);
test(Object? x, Object? y) => identical(x, y); // invocation
''');
    analyze(findNode.functionDeclaration('test'));
    check(astNodes)[findNode.methodInvocation('identical(x, y)')]
      ..containsSubrange(astNodes[findNode.simple('x, y')]!)
      ..containsSubrange(astNodes[findNode.simple('y); // invocation')]!);
    var s1 = 's';
    var s2 = String.fromCharCode(s1.codeUnitAt(0));
    assert(!identical(s1, s2));
    _callHandlers['identical'] =
        binaryFunction<Object?, Object?>((x, y) => !identical(x, y));
    check(runInterpreter([s1, s2])).equals(true);
    check(runInterpreter([s1, s1])).equals(false);
  }

  test_methodInvocation_instanceMethod() async {
    await assertNoErrorsInCode('''
test(String s1, String s2) => s1.contains(s2);
''');
    analyze(findNode.singleFunctionDeclaration);
    check(astNodes)[findNode.methodInvocation('s1.contains(s2)')]
      ..containsSubrange(astNodes[findNode.simple('s1.contains')]!)
      ..containsSubrange(astNodes[findNode.simple('s2);')]!);
    check(runInterpreter(['abcde', 'bcd'])).equals(true);
    check(runInterpreter(['abc', 'abcde'])).equals(false);
  }

  test_methodInvocation_instanceMethod_implicitThis() async {
    await assertNoErrorsInCode('''
class C {
  external int f(int x);
  test(int x) => f(x); // invocation
}
''');
    analyze(findNode.methodDeclaration('test'));
    check(astNodes)[findNode.methodInvocation('f(x)')]
        .containsSubrange(astNodes[findNode.simple('x); // invocation')]!);
    var c = Instance(findElement.class_('C').thisType);
    _callHandlers['C.f'] = binaryFunction<Instance, int>((this_, x) {
      check(this_).identicalTo(c);
      check(x).equals(123);
      return 456;
    });
    check(runInterpreter([c, 123])).equals(456);
  }

  test_methodInvocation_nullAware() async {
    await assertNoErrorsInCode('''
external String f();
test(String? s) => s?.contains(f());
''');
    analyze(findNode.functionDeclaration('test'));
    check(astNodes)[findNode.methodInvocation('s?.contains(f())')]
      ..containsSubrange(astNodes[findNode.simple('s?.contains')]!)
      ..containsSubrange(astNodes[findNode.methodInvocation('f())')]!);
    late bool fCalled;
    late String fValue;
    _callHandlers['f'] = nullaryFunction(() {
      check(fCalled).isFalse();
      fCalled = true;
      return fValue;
    });
    fCalled = false;
    fValue = 'bcd';
    check(runInterpreter(['abcde'])).equals(true);
    check(fCalled).isTrue;
    fCalled = false;
    fValue = 'abcde';
    check(runInterpreter(['abc'])).equals(false);
    check(fCalled).isTrue;
    fCalled = false;
    fValue = 'irrelevant';
    check(runInterpreter([null])).equals(null);
    check(fCalled).isFalse;
  }

  test_methodInvocation_staticMethod() async {
    await assertNoErrorsInCode('''
test(String s) => int.parse(s);
''');
    analyze(findNode.singleFunctionDeclaration);
    check(astNodes)[findNode.methodInvocation('int.parse(s)')]
        .containsSubrange(astNodes[findNode.simple('s);')]!);
    check(astNodes).not((s) => s.containsNode(findNode.simple('int')));
    check(runInterpreter(['123'])).equals(123);
  }

  test_methodInvocation_staticMethod_inScope() async {
    await assertNoErrorsInCode('''
class C {
  external static int f(int x);
  test(int x) => f(x); // invocation
  }
''');
    analyze(findNode.methodDeclaration('test'));
    check(astNodes)[findNode.methodInvocation('f(x)')]
        .containsSubrange(astNodes[findNode.simple('x); // invocation')]!);
    _callHandlers['C.f'] = unaryFunction<int>((x) {
      check(x).equals(123);
      return 456;
    });
    var c = Instance(findElement.class_('C').thisType);
    check(runInterpreter([c, 123])).equals(456);
  }

  test_methodInvocation_topLevelFunction_nullary() async {
    await assertNoErrorsInCode('''
external int f();
test() => f(); // invocation
''');
    analyze(findNode.functionDeclaration('test'));
    check(astNodes)
        .containsNode(findNode.methodInvocation('f(); // invocation'));
    _callHandlers['f'] = nullaryFunction(() => 123);
    check(runInterpreter([])).equals(123);
  }

  test_methodInvocation_topLevelFunction_oneNamedArgument() async {
    await assertNoErrorsInCode('''
external int f(int x, {required int y});
test(int x, int y) => f(x, y: y); // invocation
''');
    analyze(findNode.functionDeclaration('test'));
    check(astNodes)[findNode.methodInvocation('f(x, y: y)')]
      ..containsSubrange(astNodes[findNode.simple('x, y')]!)
      ..containsSubrange(astNodes[findNode.simple('y); // invocation')]!);
    _callHandlers['f'] = (callDescriptor, positionalArguments, namedArguments) {
      check(callDescriptor.typeArguments).isEmpty;
      check(positionalArguments).length.equals(1);
      var x = positionalArguments[0] as int;
      check(namedArguments).keys.unorderedEquals(['y']);
      var y = namedArguments['y'] as int;
      return 10 * x + y;
    };
    check(runInterpreter([1, 2])).equals(12);
  }

  test_methodInvocation_topLevelFunction_positionalArguments() async {
    await assertNoErrorsInCode('''
external int f(int x, int y);
test(int x, int y) => f(x, y); // invocation
''');
    analyze(findNode.functionDeclaration('test'));
    check(astNodes)[findNode.methodInvocation('f(x, y)')]
      ..containsSubrange(astNodes[findNode.simple('x, y')]!)
      ..containsSubrange(astNodes[findNode.simple('y); // invocation')]!);
    _callHandlers['f'] = binaryFunction<int, int>((x, y) => 10 * x + y);
    check(runInterpreter([1, 2])).equals(12);
  }

  test_methodInvocation_topLevelFunction_twoNamedArguments() async {
    await assertNoErrorsInCode('''
external int f({required int x, required int y});
test(int x, int y) => f(y: y, x: x);
''');
    analyze(findNode.functionDeclaration('test'));
    check(astNodes)[findNode.methodInvocation('f(y: y, x: x)')]
      ..containsSubrange(astNodes[findNode.simple('y, x')]!)
      ..containsSubrange(astNodes[findNode.simple('x);')]!);
    _callHandlers['f'] = (callDescriptor, positionalArguments, namedArguments) {
      check(callDescriptor.typeArguments).isEmpty;
      check(positionalArguments).isEmpty;
      check(namedArguments).keys.unorderedEquals(['x', 'y']);
      var x = namedArguments['x'] as int;
      var y = namedArguments['y'] as int;
      return 10 * x + y;
    };
    check(runInterpreter([1, 2])).equals(12);
  }

  test_methodInvocation_typeArguments_explicit() async {
    await assertNoErrorsInCode('''
external f<T, U>();
test() => f<int, String>();
''');
    analyze(findNode.functionDeclaration('test'));
    check(astNodes).containsNode(findNode.methodInvocation('f<int, String>()'));
    _callHandlers['f'] = (callDescriptor, positinalArguments, namedArguments) {
      check(callDescriptor.typeArguments).length.equals(2);
      check(callDescriptor.typeArguments[0]).equals(typeProvider.intType);
      check(callDescriptor.typeArguments[1]).equals(typeProvider.stringType);
      return null;
    };
    check(runInterpreter([])).equals(null);
  }

  test_multipleParameters_first() async {
    await assertNoErrorsInCode('''
test(int i, int j) => i;
''');
    analyze(findNode.singleFunctionDeclaration);
    check(runInterpreter([123, 456])).equals(123);
  }

  test_multipleParameters_second() async {
    await assertNoErrorsInCode('''
test(int i, int j) => j;
''');
    analyze(findNode.singleFunctionDeclaration);
    check(runInterpreter([123, 456])).equals(456);
  }

  test_noReturnAtEndOfFunction() async {
    await assertNoErrorsInCode('''
test() {}
''');
    analyze(findNode.singleFunctionDeclaration);
    check(runInterpreter([])).equals(null);
  }

  test_nullLiteral() async {
    await assertNoErrorsInCode('''
test() => null;
''');
    analyze(findNode.singleFunctionDeclaration);
    check(astNodes).containsNode(findNode.nullLiteral('null'));
    check(runInterpreter([])).equals(null);
  }

  test_parenthesizedExpression() async {
    await assertNoErrorsInCode('''
test(int i) => (i);
''');
    analyze(findNode.singleFunctionDeclaration);
    check(astNodes)[findNode.parenthesized('(i)')]
        .containsSubrange(astNodes[findNode.simple('i);')]!);
    check(runInterpreter([123])).equals(123);
  }

  test_parenthesizedExpression_stopsNullShorting() async {
    await assertNoErrorsInCode('''
test(List<Object?>? list) => (list?.first).hashCode;
''');
    analyze(findNode.singleFunctionDeclaration);
    check(runInterpreter([null])).equals(null.hashCode);
    check(runInterpreter([
      makeList([123])
    ])).equals(123.hashCode);
  }

  test_postfixExpression_decrement_property_nullShorting() async {
    await assertNoErrorsInCode('''
test(List? l) => l?.length--;
''');
    analyze(findNode.singleFunctionDeclaration);
    check(astNodes)[findNode.postfix('l?.length--')]
      ..containsSubrange(astNodes[findNode.simple('l?.length')]!)
      ..containsSubrange(astNodes[findNode.propertyAccess('l?.length')]!);
    check(runInterpreter([null])).equals(null);
    var l = ['a', 'b', 'c', 'd', 'e'];
    check(runInterpreter([makeList(l)])).equals(5);
    check(l).deepEquals(['a', 'b', 'c', 'd']);
  }

  test_postfixExpression_decrement_property_prefixedIdentifier() async {
    await assertNoErrorsInCode('''
test(List l) => l.length--;
''');
    analyze(findNode.singleFunctionDeclaration);
    check(astNodes)[findNode.postfix('l.length--')]
      ..containsSubrange(astNodes[findNode.simple('l.length')]!)
      ..containsSubrange(astNodes[findNode.prefixed('l.length')]!);
    var l = ['a', 'b', 'c', 'd', 'e'];
    check(runInterpreter([makeList(l)])).equals(5);
    check(l).deepEquals(['a', 'b', 'c', 'd']);
  }

  test_postfixExpression_decrement_property_propertyAccess() async {
    await assertNoErrorsInCode('''
test(List l) => (l).length--;
''');
    analyze(findNode.singleFunctionDeclaration);
    check(astNodes)[findNode.postfix('(l).length--')]
      ..containsSubrange(astNodes[findNode.parenthesized('(l)')]!)
      ..containsSubrange(astNodes[findNode.propertyAccess('(l).length')]!);
    var l = ['a', 'b', 'c', 'd', 'e'];
    check(runInterpreter([makeList(l)])).equals(5);
    check(l).deepEquals(['a', 'b', 'c', 'd']);
  }

  test_postfixExpression_decrement_property_simpleIdentifier() async {
    await assertNoErrorsInCode('''
extension E on List {
  test() => length--;
}
''');
    analyze(findNode.singleMethodDeclaration);
    check(astNodes)[findNode.postfix('length--')]
        .containsSubrange(astNodes[findNode.simple('length')]!);
    var l = ['a', 'b', 'c', 'd', 'e'];
    check(runInterpreter([makeList(l)])).equals(5);
    check(l).deepEquals(['a', 'b', 'c', 'd']);
  }

  test_postfixExpression_increment_local_sideEffect() async {
    await assertNoErrorsInCode('''
test() {
  int i = 123;
  i++;
  return i;
}
''');
    analyze(findNode.singleFunctionDeclaration);
    check(astNodes)[findNode.postfix('i++')]
        .containsSubrange(astNodes[findNode.simple('i++')]!);
    check(runInterpreter([])).equals(124);
  }

  test_postfixExpression_increment_local_value() async {
    await assertNoErrorsInCode('''
test() {
  int i = 123;
  return i++;
}
''');
    analyze(findNode.singleFunctionDeclaration);
    check(astNodes)[findNode.postfix('i++')]
        .containsSubrange(astNodes[findNode.simple('i++')]!);
    check(runInterpreter([])).equals(123);
  }

  test_postfixExpression_increment_parameter_sideEffect() async {
    await assertNoErrorsInCode('''
test(int i) {
  i++;
  return i;
}
''');
    analyze(findNode.singleFunctionDeclaration);
    check(astNodes)[findNode.postfix('i++')]
        .containsSubrange(astNodes[findNode.simple('i++')]!);
    check(runInterpreter([123])).equals(124);
  }

  test_postfixExpression_increment_parameter_value() async {
    await assertNoErrorsInCode('''
test(int i) => i++;
''');
    analyze(findNode.singleFunctionDeclaration);
    check(astNodes)[findNode.postfix('i++')]
        .containsSubrange(astNodes[findNode.simple('i++')]!);
    check(runInterpreter([123])).equals(123);
  }

  test_prefixExpression_decrement_property_nullShorting() async {
    await assertNoErrorsInCode('''
test(List? l) => --l?.length;
''');
    analyze(findNode.singleFunctionDeclaration);
    check(astNodes)[findNode.prefix('--l?.length')]
      ..containsSubrange(astNodes[findNode.simple('l?.length')]!)
      ..containsSubrange(astNodes[findNode.propertyAccess('l?.length')]!);
    check(runInterpreter([null])).equals(null);
    var l = ['a', 'b', 'c', 'd', 'e'];
    check(runInterpreter([makeList(l)])).equals(4);
    check(l).deepEquals(['a', 'b', 'c', 'd']);
  }

  test_prefixExpression_decrement_property_prefixedIdentifier() async {
    await assertNoErrorsInCode('''
test(List l) => --l.length;
''');
    analyze(findNode.singleFunctionDeclaration);
    check(astNodes)[findNode.prefix('--l.length')]
      ..containsSubrange(astNodes[findNode.simple('l.length')]!)
      ..containsSubrange(astNodes[findNode.prefixed('l.length')]!);
    var l = ['a', 'b', 'c', 'd', 'e'];
    check(runInterpreter([makeList(l)])).equals(4);
    check(l).deepEquals(['a', 'b', 'c', 'd']);
  }

  test_prefixExpression_decrement_property_propertyAccess() async {
    await assertNoErrorsInCode('''
test(List l) => --(l).length;
''');
    analyze(findNode.singleFunctionDeclaration);
    check(astNodes)[findNode.prefix('--(l).length')]
      ..containsSubrange(astNodes[findNode.parenthesized('(l)')]!)
      ..containsSubrange(astNodes[findNode.propertyAccess('(l).length')]!);
    var l = ['a', 'b', 'c', 'd', 'e'];
    check(runInterpreter([makeList(l)])).equals(4);
    check(l).deepEquals(['a', 'b', 'c', 'd']);
  }

  test_prefixExpression_decrement_property_simpleIdentifier() async {
    await assertNoErrorsInCode('''
extension E on List {
  test() => --length;
}
''');
    analyze(findNode.singleMethodDeclaration);
    check(astNodes)[findNode.prefix('--length')]
        .containsSubrange(astNodes[findNode.simple('length')]!);
    var l = ['a', 'b', 'c', 'd', 'e'];
    check(runInterpreter([makeList(l)])).equals(4);
    check(l).deepEquals(['a', 'b', 'c', 'd']);
  }

  test_prefixExpression_increment_local_sideEffect() async {
    await assertNoErrorsInCode('''
test() {
  int i = 123;
  ++i; // increment
  return i;
}
''');
    analyze(findNode.singleFunctionDeclaration);
    check(astNodes)[findNode.prefix('++i')]
        .containsSubrange(astNodes[findNode.simple('i; // increment')]!);
    check(runInterpreter([])).equals(124);
  }

  test_prefixExpression_increment_local_value() async {
    await assertNoErrorsInCode('''
test() {
  int i = 123;
  return ++i;
}
''');
    analyze(findNode.singleFunctionDeclaration);
    check(astNodes)[findNode.prefix('++i')]
        .containsSubrange(astNodes[findNode.simple('i;')]!);
    check(runInterpreter([])).equals(124);
  }

  test_prefixExpression_increment_parameter_sideEffect() async {
    await assertNoErrorsInCode('''
test(int i) {
  ++i; // increment
  return i;
}
''');
    analyze(findNode.singleFunctionDeclaration);
    check(astNodes)[findNode.prefix('++i')]
        .containsSubrange(astNodes[findNode.simple('i; // increment')]!);
    check(runInterpreter([123])).equals(124);
  }

  test_prefixExpression_increment_parameter_value() async {
    await assertNoErrorsInCode('''
test(int i) => ++i;
''');
    analyze(findNode.singleFunctionDeclaration);
    check(astNodes)[findNode.prefix('++i')]
        .containsSubrange(astNodes[findNode.simple('i;')]!);
    check(runInterpreter([123])).equals(124);
  }

  test_prefixExpression_not() async {
    await assertNoErrorsInCode('''
test(bool b) => !b;
''');
    analyze(findNode.singleFunctionDeclaration);
    check(astNodes)[findNode.prefix('!b')]
        .containsSubrange(astNodes[findNode.simple('b;')]!);
    check(runInterpreter([true])).equals(false);
    check(runInterpreter([false])).equals(true);
  }

  test_propertyAccess_allowsNullShorting() async {
    await assertNoErrorsInCode('''
test(List<Object?>? list) => list?.first.hashCode;
''');
    analyze(findNode.singleFunctionDeclaration);
    check(runInterpreter([null])).equals(null);
    check(runInterpreter([
      makeList([123])
    ])).equals(123.hashCode);
  }

  test_propertyAccess_nestedNullShorting() async {
    await assertNoErrorsInCode('''
test(List<Object?>? list) => list?.first?.hashCode;
''');
    analyze(findNode.singleFunctionDeclaration);
    check(astNodes, because: 'both null checks should use the same block')[
            findNode.singleFunctionBody]
        .instructions
        .withOpcode(Opcode.block)
        .hasLength(1);
    check(runInterpreter([null])).equals(null);
    check(runInterpreter([
      makeList([123])
    ])).equals(123.hashCode);
  }

  test_propertyGet_nullShorting() async {
    await assertNoErrorsInCode('''
test(String? s) => s?.length;
''');
    analyze(findNode.singleFunctionDeclaration);
    check(astNodes)[findNode.propertyAccess('s?.length')]
        .containsSubrange(astNodes[findNode.simple('s?.length')]!);
    check(runInterpreter([null])).equals(null);
    check(runInterpreter(['foo'])).equals(3);
  }

  test_propertyGet_prefixedIdentifier() async {
    await assertNoErrorsInCode('''
test(int i) => i.isEven;
''');
    analyze(findNode.singleFunctionDeclaration);
    check(astNodes)[findNode.prefixed('i.isEven')]
        .containsSubrange(astNodes[findNode.simple('i.')]!);
    check(runInterpreter([1])).equals(false);
    check(runInterpreter([2])).equals(true);
  }

  test_propertyGet_propertyAccess() async {
    await assertNoErrorsInCode('''
test() => 'foo'.length;
''');
    analyze(findNode.singleFunctionDeclaration);
    check(astNodes)[findNode.propertyAccess("'foo'.length")]
        .containsSubrange(astNodes[findNode.stringLiteral("'foo'")]!);
    check(runInterpreter([])).equals(3);
  }

  test_propertyGet_simpleIdentifier() async {
    await assertNoErrorsInCode('''
extension E on String {
  test() => length;
}
''');
    analyze(findNode.singleMethodDeclaration);
    check(astNodes).containsNode(findNode.simple('length'));
    check(runInterpreter(['foo'])).equals(3);
  }

  test_returnStatement_noValue() async {
    await assertNoErrorsInCode('''
test() {
  return;
  return 1; // ignore: dead_code
}
''');
    analyze(findNode.singleFunctionDeclaration);
    check(astNodes).containsNode(findNode.returnStatement('return;'));
    check(runInterpreter([])).equals(null);
  }

  test_returnStatement_value() async {
    await assertNoErrorsInCode('''
test() {
  return 123;
  return 1; // ignore: dead_code
}
''');
    analyze(findNode.singleFunctionDeclaration);
    check(astNodes)[findNode.returnStatement('return 123')]
        .containsSubrange(astNodes[findNode.integerLiteral('123')]!);
    check(runInterpreter([])).equals(123);
  }

  test_simpleIdentifier_local() async {
    await assertNoErrorsInCode('''
test() {
  var i = 123;
  return i;
}
''');
    analyze(findNode.singleFunctionDeclaration);
    check(astNodes).containsNode(findNode.simple('i;'));
    check(runInterpreter([])).equals(123);
  }

  test_simpleIdentifier_parameter() async {
    await assertNoErrorsInCode('''
test(int i) => i;
''');
    analyze(findNode.singleFunctionDeclaration);
    check(astNodes).containsNode(findNode.simple('i;'));
    check(runInterpreter([123])).equals(123);
  }

  test_stringInterpolation_withBraces() async {
    await assertNoErrorsInCode(r'''
test(int x) => 'x = ${x}';
''');
    analyze(findNode.singleFunctionDeclaration);
    check(astNodes)[findNode.stringInterpolation('x =')]
      ..containsSubrange(astNodes[findNode.interpolationString('x =')]!)
      ..containsSubrange(astNodes[findNode.interpolationExpression(r'${x}')]!);
    check(runInterpreter([123])).equals('x = 123');
  }

  test_stringInterpolation_withoutBraces() async {
    await assertNoErrorsInCode(r'''
test(int x) => 'x = $x';
''');
    analyze(findNode.singleFunctionDeclaration);
    check(astNodes)[findNode.stringInterpolation('x =')]
      ..containsSubrange(astNodes[findNode.interpolationString('x =')]!)
      ..containsSubrange(astNodes[findNode.interpolationExpression(r'$x')]!);
    check(runInterpreter([123])).equals('x = 123');
  }

  test_stringLiteral() async {
    await assertNoErrorsInCode(r'''
test() => 'foo';
''');
    analyze(findNode.singleFunctionDeclaration);
    check(astNodes).containsNode(findNode.stringLiteral('foo'));
    check(runInterpreter([])).equals('foo');
  }

  test_thisExpression() async {
    await assertNoErrorsInCode('''
class C {
  test() => this;
}
''');
    analyze(findNode.singleMethodDeclaration);
    check(astNodes).containsNode(findNode.this_('this'));
    var thisValue = Instance(findElement.class_('C').thisType);
    check(runInterpreter([thisValue])).identicalTo(thisValue);
  }

  test_variableDeclarationList_singleVariable_initialized() async {
    await assertNoErrorsInCode('''
test() {
  int i = 123;
  return i;
}
''');
    analyze(findNode.singleFunctionDeclaration);
    check(astNodes)[findNode.variableDeclarationList('int i = 123')]
        .containsSubrange(astNodes[findNode.integerLiteral('123')]!);
    check(runInterpreter([])).identicalTo(123);
  }

  test_variableDeclarationList_singleVariable_uninitialized_nonNullable() async {
    await assertNoErrorsInCode('''
test() {
  int i; // ignore: unused_local_variable
  return 123;
}
''');
    analyze(findNode.singleFunctionDeclaration);
    check(astNodes)[findNode.variableDeclarationList('int i')].not(
        (s) => s.instructions.any((s) => s.opcode.equals(Opcode.writeLocal)));
    check(runInterpreter([])).identicalTo(123);
  }

  test_variableDeclarationList_singleVariable_uninitialized_nullable() async {
    await assertNoErrorsInCode('''
test() {
  int? i;
  return i;
}
''');
    analyze(findNode.singleFunctionDeclaration);
    check(astNodes).containsNode(findNode.variableDeclarationList('int? i'));
    check(runInterpreter([])).identicalTo(null);
  }

  test_variableDeclarationList_singleVariable_uninitialized_unsound() async {
    await assertErrorsInCode('''
test() {
  int i;
  return i; // UNSOUND
}
''', [
      error(
          CompileTimeErrorCode
              .NOT_ASSIGNED_POTENTIALLY_NON_NULLABLE_LOCAL_VARIABLE,
          27,
          1),
    ]);
    analyze(findNode.singleFunctionDeclaration);
    check(astNodes)[findNode.variableDeclarationList('int i')].not(
        (s) => s.instructions.any((s) => s.opcode.equals(Opcode.writeLocal)));
    check(() => runInterpreter([])).throws<SoundnessError>()
      ..address.equals(astNodes[findNode.simple('i; // UNSOUND')]!.start)
      ..message.equals('Read of unset local');
  }

  test_variableDeclarationList_twoVariables_first() async {
    await assertNoErrorsInCode('''
test() {
  int i = 123, j = 456; // ignore: unused_local_variable
  return i;
}
''');
    analyze(findNode.singleFunctionDeclaration);
    check(astNodes)[findNode.variableDeclarationList('int i = 123')]
      ..containsSubrange(astNodes[findNode.integerLiteral('123')]!)
      ..containsSubrange(astNodes[findNode.integerLiteral('456')]!);
    check(runInterpreter([])).identicalTo(123);
  }

  test_variableDeclarationList_twoVariables_second() async {
    await assertNoErrorsInCode('''
test() {
  int i = 123, j = 456; // ignore: unused_local_variable
  return j;
}
''');
    analyze(findNode.singleFunctionDeclaration);
    check(astNodes)[findNode.variableDeclarationList('int i = 123')]
      ..containsSubrange(astNodes[findNode.integerLiteral('123')]!)
      ..containsSubrange(astNodes[findNode.integerLiteral('456')]!);
    check(runInterpreter([])).identicalTo(456);
  }

  test_variableDeclarationStatement() async {
    await assertNoErrorsInCode('''
test() {
  int i = 123; // ignore: unused_local_variable
}
''');
    analyze(findNode.singleFunctionDeclaration);
    check(astNodes)[findNode.variableDeclarationStatement('int i = 123')]
        .containsSubrange(
            astNodes[findNode.variableDeclarationList('int i = 123')]!);
    check(runInterpreter([])).identicalTo(null);
  }

  test_whileStatement_simple() async {
    await assertNoErrorsInCode('''
test(int count, List<int> result) {
  while (count-- > 0) {
    result.add(count);
  }
}
''');
    analyze(findNode.singleFunctionDeclaration);
    check(astNodes)[findNode.whileStatement('while')]
      ..containsSubrange(astNodes[findNode.binary('count-- > 0')]!)
      ..containsSubrange(astNodes[findNode.block('result.add')]!);
    var values = <int>[];
    check(runInterpreter([5, makeList(values)])).equals(null);
    check(values).deepEquals([4, 3, 2, 1, 0]);
  }

  test_yieldStatement() async {
    await assertNoErrorsInCode('''
test(Object? o) sync* {
  yield o;
}
''');
    analyze(findNode.singleFunctionDeclaration);
    check(astNodes)[findNode.yieldStatement('yield')]
        .containsSubrange(astNodes[findNode.simple('o;')]!);
    _onYield = (value) {
      check(value).equals(123);
      hook(null, 'onYield');
    };
    expectHooks(['onYield'], () => check(runInterpreter([123])).equals(null));
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

  void analyze(Declaration declaration) {
    switch (declaration) {
      case FunctionDeclaration(
          :var declaredElement!,
          functionExpression: FunctionExpression(:var body)
        ):
      case MethodDeclaration(:var declaredElement!, :var body):
        ir = astToIR(declaredElement, body,
            typeProvider: typeProvider,
            typeSystem: typeSystem,
            eventListener: astNodes);
      default:
        throw UnimplementedError(
            'TODO(paulberry): ${declaration.declaredElement}');
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
        if (element.enclosingElement3
            case InstanceElement(name: var typeName)) {
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
