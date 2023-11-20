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
import 'package:analyzer/src/wolf/ir/validator.dart';
import 'package:checks/checks.dart';
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
  final _instanceGetHandlers = {
    'int.isEven': unaryFunction<int>((i) => i.isEven),
    'String.length': unaryFunction<String>((s) => s.length)
  };

  final _instanceSetHandlers = {
    'List.length=': binaryFunction<ListInstance, int>(
        (list, newLength) => list.values.length = newLength)
  };

  ListInstance makeList(List<Object?> values) => ListInstance(
      typeProvider.listType(typeProvider.objectQuestionType), values);

  Object? runInterpreter(List<Object?> args) =>
      interpret(ir, args, callDispatcher: _callDispatcher);

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

  test_integerLiteral() async {
    await assertNoErrorsInCode('''
test() => 123;
''');
    analyze(findNode.singleFunctionDeclaration);
    check(astNodes).containsNode(findNode.integerLiteral('123'));
    check(runInterpreter([])).equals(123);
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

  CallHandler _callDispatcher(CallDescriptor callDescriptor) {
    CallHandler? handler;
    switch (callDescriptor) {
      case InstanceGetDescriptor(
          getter: PropertyAccessorElement(
            enclosingElement: InstanceElement(name: var typeName?)
          )
        ):
        handler = _instanceGetHandlers['$typeName.${callDescriptor.name}'];
      case InstanceSetDescriptor(
          setter: PropertyAccessorElement(
            enclosingElement: InstanceElement(name: var typeName?)
          )
        ):
        handler = _instanceSetHandlers['$typeName.${callDescriptor.name}'];
      case dynamic(:var runtimeType):
        throw UnimplementedError('TODO(paulberry): $runtimeType');
    }
    if (handler == null) {
      throw StateError('No handler for $callDescriptor');
    }
    return handler;
  }

  static CallHandler binaryFunction<T, U>(Object? Function(T, U) f) =>
      (positionalArguments, namedArguments) {
        check(positionalArguments).length.equals(2);
        check(namedArguments).isEmpty();
        return f(positionalArguments[0] as T, positionalArguments[1] as U);
      };

  static CallHandler unaryFunction<T>(Object? Function(T) f) =>
      (positionalArguments, namedArguments) {
        check(positionalArguments).length.equals(1);
        check(namedArguments).isEmpty();
        return f(positionalArguments[0] as T);
      };
}

class AstToIRTestBase extends PubPackageResolutionTest {
  final astNodes = AstNodes();
  late final CodedIRContainer ir;

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
  }
}

/// Interpreter representation of a [List] object.
class ListInstance extends Instance {
  final List<Object?> values;

  ListInstance(super.type, this.values);
}

extension on Subject<SoundnessError> {
  Subject<int> get address => has((e) => e.address, 'address');
  Subject<String> get message => has((e) => e.message, 'message');
}
