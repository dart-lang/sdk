// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
library kernel.type_propagation.selfcheck;

import 'dart:io';
import 'package:kernel/core_types.dart';
import 'package:kernel/kernel.dart';
import 'package:kernel/type_propagation/type_propagation.dart';

const String usage = '''
Usage: selfcheck input.dill output.dill

Runs type propagation on the given program and inserts dynamic checks
to verify that all the propagated types are correct.
''';

main(List<String> args) {
  if (args.length != 2) {
    print(usage);
    exit(1);
  }
  var program = loadProgramFromBinary(args[0]);
  var typePropagation = new TypePropagation(program);
  new SelfCheckTransformer(typePropagation).transform(program);
  writeProgramToBinary(program, args[1]);
}

class SelfCheckTransformer {
  final TypePropagation typePropagation;
  Member currentMember;

  CoreTypes get coreTypes => typePropagation.builder.coreTypes;

  SelfCheckTransformer(this.typePropagation);

  void transform(Program program) {
    for (var library in program.libraries) {
      library.procedures.forEach(transformProcedure);
      library.fields.forEach(transformField);
      for (var class_ in library.classes) {
        class_.procedures.forEach(transformProcedure);
        class_.fields.forEach(transformField);
        class_.constructors.forEach(transformConstructor);
      }
    }
  }

  void transformProcedure(Procedure node) {
    currentMember = node;
    transformFunction(node.function, checkReturn: true);
  }

  void transformConstructor(Constructor node) {
    currentMember = node;
    transformFunction(node.function, checkReturn: false);
  }

  void transformField(Field node) {
    // TODO(asgerf): To check this, we could wrap with a getter/setter pair
    //   and instrument constructor initializers.  But for now we don't do
    //   anything for fields.
  }

  void transformFunction(FunctionNode node, {bool checkReturn}) {
    if (node.body == null) return; // Nothing to check if there is no body.
    List<Statement> newStatements = <Statement>[];
    for (VariableDeclaration parameter in node.positionalParameters) {
      InferredValue value = typePropagation.getParameterValue(parameter);
      newStatements.add(makeCheck(parameter, value));
    }
    for (VariableDeclaration parameter in node.namedParameters) {
      InferredValue value = typePropagation.getParameterValue(parameter);
      newStatements.add(makeCheck(parameter, value));
    }
    newStatements.add(node.body);
    node.body = new Block(newStatements)..parent = node;
    // TODO(asgerf): Also check return value.
  }

  /// Make a statement that throws if the value in [variable] is not in the
  /// value set implied by [expected].
  Statement makeCheck(VariableDeclaration variable, InferredValue expected) {
    Expression condition = new LogicalExpression(
        makeBaseClassCheck(variable, expected),
        '&&',
        makeBitmaskCheck(variable, expected));
    return new IfStatement(
        new Not(condition),
        new ExpressionStatement(new Throw(new StringConcatenation([
          new StringLiteral(
              'Unexpected value in $currentMember::${variable.name}: '),
          new VariableGet(variable)
        ]))),
        null);
  }

  /// Makes an expression that returns `false` if the base class relation or
  /// nullability is not satisfied by the value in [variable],
  Expression makeBaseClassCheck(
      VariableDeclaration variable, InferredValue expected) {
    Expression condition;
    switch (expected.baseClassKind) {
      case BaseClassKind.None:
        condition = new BoolLiteral(false);
        break;

      case BaseClassKind.Exact:
        if (expected.baseClass.typeParameters.isNotEmpty) {
          // TODO(asgerf): For this we need a way to get the raw concrete type
          //   of an object.  For now, just emit the less accurate subtype
          //   check.
          condition = new IsExpression(
              new VariableGet(variable), expected.baseClass.rawType);
        } else {
          // Check `value.runtimeType == C`.
          var runtimeType = new PropertyGet(
              new VariableGet(variable), new Name('runtimeType'));
          condition = new MethodInvocation(runtimeType, new Name('=='),
              new Arguments([new TypeLiteral(expected.baseClass.rawType)]));
        }
        break;

      case BaseClassKind.Subclass:
      case BaseClassKind.Subtype:
        // TODO(asgerf): For subclass checks, we should check more precisely
        //   that is it a subclass, but for now just emit a subtype check.
        condition = new IsExpression(
            new VariableGet(variable), expected.baseClass.rawType);
        break;
    }
    // Always allow 'null'.  The base class relation should always permit 'null'
    // as a possible value, but the checks generated above disallow it.
    var nullCheck = makeIsNull(new VariableGet(variable));
    return new LogicalExpression(nullCheck, '||', condition);
  }

  Expression makeIsNull(Expression value) {
    return new MethodInvocation(
        value, new Name('=='), new Arguments([new NullLiteral()]));
  }

  /// Makes an expression that returns `false` if the value bits other than
  /// [ValueBit.null_] are not satisfied by the value in [variable],
  Expression makeBitmaskCheck(
      VariableDeclaration variable, InferredValue expected) {
    if (expected.valueBits == 0) return new BoolLiteral(false);

    // List of conditions that all must hold.  For each zero bit we know that
    // type of value is not allowed to occur.
    List<Expression> allChecks = <Expression>[];

    // List of condition of which one must hold.  This is used for checking the
    // [ValueBit.other] bit.  For each one bit, we know that type of value
    // is allowed to occur.  We use this because it is hard to check directly
    // that a value is of the 'other' type.
    bool disallowOtherValues = expected.valueBits & ValueBit.other == 0;
    List<Expression> anyChecks = disallowOtherValues
        ? <Expression>[]
        : null;

    void checkType(int bit, DartType type) {
      if (expected.valueBits & bit == 0) {
        allChecks
            .add(new Not(new IsExpression(new VariableGet(variable), type)));
      } else if (disallowOtherValues) {
        anyChecks.add(new IsExpression(new VariableGet(variable), type));
      }
    }

    checkType(ValueBit.integer, coreTypes.intClass.rawType);
    checkType(ValueBit.double_, coreTypes.doubleClass.rawType);
    checkType(ValueBit.string, coreTypes.stringClass.rawType);
    checkType(ValueBit.null_, coreTypes.nullClass.rawType);

    if (disallowOtherValues) {
      Expression any =
          anyChecks.reduce((e1, e2) => new LogicalExpression(e1, '||', e2));
      allChecks.add(any);
    }
    return allChecks.isEmpty
        ? new BoolLiteral(true)
        : allChecks.reduce((e1, e2) => new LogicalExpression(e1, '&&', e2));
  }
}
