// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
import 'package:kernel/ast.dart';
import 'package:kernel/text/ast_to_text.dart';
import 'package:kernel/verifier.dart';
import 'package:test/test.dart';

/// Checks that the verifier correctly find errors in invalid programs.
///
/// The frontend should never generate invalid programs, so we have to test
/// these by manually constructing invalid ASTs.
///
/// We mostly test negative cases here, as we get plenty of positive cases by
/// compiling the Dart test suite with the verifier enabled.
main() {
  positiveTest('Test harness has no errors', () {
    return new NullLiteral();
  });
  negativeTest('VariableGet out of scope', () {
    return new VariableGet(makeVariable());
  });
  negativeTest('VariableSet out of scope', () {
    return new VariableSet(makeVariable(), new NullLiteral());
  });
  negativeTest('Variable block scope', () {
    VariableDeclaration variable = makeVariable();
    return new Block([
      new Block([variable]),
      new ReturnStatement(new VariableGet(variable))
    ]);
  });
  negativeTest('Variable let scope', () {
    VariableDeclaration variable = makeVariable();
    return new LogicalExpression(new Let(variable, new VariableGet(variable)),
        '&&', new VariableGet(variable));
  });
  negativeTest('Variable redeclared', () {
    VariableDeclaration variable = makeVariable();
    return new Block([variable, variable]);
  });
  negativeTest('Member redeclared', () {
    Field field = new Field(new Name('field'), initializer: new NullLiteral());
    return new Class(
        name: 'Test',
        supertype: objectClass.asRawSupertype,
        fields: [field, field]);
  });
  negativeTest('Class redeclared', () {
    return otherClass; // Test harness also adds otherClass to program.
  });
  negativeTest('Class type parameter redeclared', () {
    var parameter = makeTypeParameter();
    return new Class(
        name: 'Test',
        supertype: objectClass.asRawSupertype,
        typeParameters: [parameter, parameter]);
  });
  negativeTest('Member type parameter redeclared', () {
    var parameter = makeTypeParameter();
    return new Procedure(
        new Name('test'),
        ProcedureKind.Method,
        new FunctionNode(new ReturnStatement(new NullLiteral()),
            typeParameters: [parameter, parameter]));
  });
  negativeTest('Type parameter out of scope', () {
    var parameter = makeTypeParameter();
    return new ListLiteral([], typeArgument: new TypeParameterType(parameter));
  });
  negativeTest('Class type parameter from another class', () {
    return new TypeLiteral(new TypeParameterType(otherClass.typeParameters[0]));
  });
  negativeTest('Class type parameter in static method', () {
    return new Procedure(
        new Name('test'),
        ProcedureKind.Method,
        new FunctionNode(new ReturnStatement(
            new TypeLiteral(new TypeParameterType(classTypeParameter)))),
        isStatic: true);
  });
  negativeTest('Class type parameter in static field', () {
    return new Field(new Name('field'),
        initializer: new TypeLiteral(new TypeParameterType(classTypeParameter)),
        isStatic: true);
  });
  negativeTest('Method type parameter out of scope', () {
    var parameter = makeTypeParameter();
    return new Class(
        name: 'Test',
        supertype: objectClass.asRawSupertype,
        procedures: [
          new Procedure(
              new Name('generic'),
              ProcedureKind.Method,
              new FunctionNode(new EmptyStatement(),
                  typeParameters: [parameter])),
          new Procedure(
              new Name('use'),
              ProcedureKind.Method,
              new FunctionNode(new ReturnStatement(
                  new TypeLiteral(new TypeParameterType(parameter)))))
        ]);
  });
  negativeTest('Interface type arity too low', () {
    return new TypeLiteral(new InterfaceType(otherClass, []));
  });
  negativeTest('Interface type arity too high', () {
    return new TypeLiteral(
        new InterfaceType(otherClass, [new DynamicType(), new DynamicType()]));
  });
  negativeTest('Dangling interface type', () {
    return new TypeLiteral(new InterfaceType(new Class()));
  });
  negativeTest('Dangling field get', () {
    return new DirectPropertyGet(new NullLiteral(), new Field(new Name('foo')));
  });
  negativeTest('Missing block parent pointer', () {
    var block = new Block([]);
    block.statements.add(new ReturnStatement());
    return block;
  });
  negativeTest('Missing function parent pointer', () {
    var procedure = new Procedure(new Name('test'), ProcedureKind.Method, null);
    procedure.function = new FunctionNode(new EmptyStatement());
    return procedure;
  });
  negativeTest('StaticGet without target', () {
    return new StaticGet(null);
  });
  negativeTest('StaticSet without target', () {
    return new StaticSet(null, new NullLiteral());
  });
  negativeTest('StaticInvocation without target', () {
    return new StaticInvocation(null, new Arguments.empty());
  });
  positiveTest('Correct StaticInvocation', () {
    var method = new Procedure(new Name('test'), ProcedureKind.Method, null,
        isStatic: true);
    method.function = new FunctionNode(
        new ReturnStatement(
            new StaticInvocation(method, new Arguments([new NullLiteral()]))),
        positionalParameters: [new VariableDeclaration('p')])..parent = method;
    return new Class(
        name: 'Test',
        supertype: objectClass.asRawSupertype,
        procedures: [method]);
  });
  negativeTest('StaticInvocation with too many parameters', () {
    var method = new Procedure(new Name('test'), ProcedureKind.Method, null,
        isStatic: true);
    method.function = new FunctionNode(new ReturnStatement(
        new StaticInvocation(method, new Arguments([new NullLiteral()]))))
      ..parent = method;
    return new Class(
        name: 'Test',
        supertype: objectClass.asRawSupertype,
        procedures: [method]);
  });
  negativeTest('StaticInvocation with too few parameters', () {
    var method = new Procedure(new Name('test'), ProcedureKind.Method, null,
        isStatic: true);
    method.function = new FunctionNode(
        new ReturnStatement(
            new StaticInvocation(method, new Arguments.empty())),
        positionalParameters: [new VariableDeclaration('p')])..parent = method;
    return new Class(
        name: 'Test',
        supertype: objectClass.asRawSupertype,
        procedures: [method]);
  });
  negativeTest('StaticInvocation with unmatched named parameter', () {
    var method = new Procedure(new Name('test'), ProcedureKind.Method, null,
        isStatic: true);
    method.function = new FunctionNode(new ReturnStatement(new StaticInvocation(
        method,
        new Arguments([],
            named: [new NamedExpression('p', new NullLiteral())]))))
      ..parent = method;
    return new Class(
        name: 'Test',
        supertype: objectClass.asRawSupertype,
        procedures: [method]);
  });
  negativeTest('StaticInvocation with missing type argument', () {
    var method = new Procedure(new Name('test'), ProcedureKind.Method, null,
        isStatic: true);
    method.function = new FunctionNode(
        new ReturnStatement(
            new StaticInvocation(method, new Arguments.empty())),
        typeParameters: [makeTypeParameter()])..parent = method;
    return new Class(
        name: 'Test',
        supertype: objectClass.asRawSupertype,
        procedures: [method]);
  });
  negativeTest('ConstructorInvocation with missing type argument', () {
    var constructor = new Constructor(null);
    constructor.function = new FunctionNode(new ReturnStatement(
        new ConstructorInvocation(constructor, new Arguments.empty())))
      ..parent = constructor;
    return new Class(
        name: 'Test',
        typeParameters: [makeTypeParameter()],
        supertype: objectClass.asRawSupertype,
        constructors: [constructor]);
  });
}

checkHasError(Program program) {
  bool passed = false;
  try {
    verifyProgram(program);
    passed = true;
  } catch (e) {}
  if (passed) {
    fail('Failed to reject invalid program:\n${programToString(program)}');
  }
}

Class objectClass = new Class(name: 'Object');

Library stubLibrary = new Library(Uri.parse('dart:core'))
  ..addClass(objectClass);

TypeParameter classTypeParameter = makeTypeParameter('T');

Class otherClass = new Class(
    name: 'OtherClass',
    typeParameters: [makeTypeParameter('OtherT')],
    supertype: objectClass.asRawSupertype);

Program makeProgram(TreeNode makeBody()) {
  var node = makeBody();
  if (node is Expression) {
    node = new ReturnStatement(node);
  }
  if (node is Statement) {
    node = new FunctionNode(node);
  }
  if (node is FunctionNode) {
    node = new Procedure(new Name('test'), ProcedureKind.Method, node);
  }
  if (node is Member) {
    node = new Class(
        name: 'Test',
        typeParameters: [classTypeParameter],
        supertype: objectClass.asRawSupertype)..addMember(node);
  }
  if (node is Class) {
    node =
        new Library(Uri.parse('test.dart'), classes: <Class>[node, otherClass]);
  }
  if (node is Library) {
    node = new Program(<Library>[node, stubLibrary]);
  }
  assert(node is Program);
  return node;
}

negativeTest(String name, TreeNode makeBody()) {
  test(name, () {
    checkHasError(makeProgram(makeBody));
  });
}

positiveTest(String name, TreeNode makeBody()) {
  test(name, () {
    verifyProgram(makeProgram(makeBody));
  });
}

VariableDeclaration makeVariable() => new VariableDeclaration(null);

TypeParameter makeTypeParameter([String name]) {
  return new TypeParameter(name, new InterfaceType(objectClass));
}
