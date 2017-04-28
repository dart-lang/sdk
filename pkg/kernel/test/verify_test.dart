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
  positiveTest('Test harness has no errors', (TestHarness test) {
    return new NullLiteral();
  });
  negativeTest('VariableGet out of scope', (TestHarness test) {
    return new VariableGet(test.makeVariable());
  });
  negativeTest('VariableSet out of scope', (TestHarness test) {
    return new VariableSet(test.makeVariable(), new NullLiteral());
  });
  negativeTest('Variable block scope', (TestHarness test) {
    VariableDeclaration variable = test.makeVariable();
    return new Block([
      new Block([variable]),
      new ReturnStatement(new VariableGet(variable))
    ]);
  });
  negativeTest('Variable let scope', (TestHarness test) {
    VariableDeclaration variable = test.makeVariable();
    return new LogicalExpression(new Let(variable, new VariableGet(variable)),
        '&&', new VariableGet(variable));
  });
  negativeTest('Variable redeclared', (TestHarness test) {
    VariableDeclaration variable = test.makeVariable();
    return new Block([variable, variable]);
  });
  negativeTest('Member redeclared', (TestHarness test) {
    Field field = new Field(new Name('field'), initializer: new NullLiteral());
    return new Class(
        name: 'Test',
        supertype: test.objectClass.asRawSupertype,
        fields: [field, field]);
  });
  negativeTest('Class redeclared', (TestHarness test) {
    return test.otherClass; // Test harness also adds otherClass to program.
  });
  negativeTest('Class type parameter redeclared', (TestHarness test) {
    var parameter = test.makeTypeParameter();
    return new Class(
        name: 'Test',
        supertype: test.objectClass.asRawSupertype,
        typeParameters: [parameter, parameter]);
  });
  negativeTest('Member type parameter redeclared', (TestHarness test) {
    var parameter = test.makeTypeParameter();
    return new Procedure(
        new Name('bar'),
        ProcedureKind.Method,
        new FunctionNode(new ReturnStatement(new NullLiteral()),
            typeParameters: [parameter, parameter]));
  });
  negativeTest('Type parameter out of scope', (TestHarness test) {
    var parameter = test.makeTypeParameter();
    return new ListLiteral([], typeArgument: new TypeParameterType(parameter));
  });
  negativeTest('Class type parameter from another class', (TestHarness test) {
    return new TypeLiteral(
        new TypeParameterType(test.otherClass.typeParameters[0]));
  });
  negativeTest('Class type parameter in static method', (TestHarness test) {
    return new Procedure(
        new Name('bar'),
        ProcedureKind.Method,
        new FunctionNode(new ReturnStatement(
            new TypeLiteral(new TypeParameterType(test.classTypeParameter)))),
        isStatic: true);
  });
  negativeTest('Class type parameter in static field', (TestHarness test) {
    return new Field(new Name('field'),
        initializer:
            new TypeLiteral(new TypeParameterType(test.classTypeParameter)),
        isStatic: true);
  });
  negativeTest('Method type parameter out of scope', (TestHarness test) {
    var parameter = test.makeTypeParameter();
    return new Class(
        name: 'Test',
        supertype: test.objectClass.asRawSupertype,
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
  negativeTest('Interface type arity too low', (TestHarness test) {
    return new TypeLiteral(new InterfaceType(test.otherClass, []));
  });
  negativeTest('Interface type arity too high', (TestHarness test) {
    return new TypeLiteral(new InterfaceType(
        test.otherClass, [new DynamicType(), new DynamicType()]));
  });
  negativeTest('Dangling interface type', (TestHarness test) {
    var orphan = new Class();
    return new TypeLiteral(new InterfaceType(orphan));
  });
  negativeTest('Dangling field get', (TestHarness test) {
    var orphan = new Field(new Name('foo'));
    return new DirectPropertyGet(new NullLiteral(), orphan);
  });
  negativeTest('Missing block parent pointer', (TestHarness test) {
    var block = new Block([]);
    block.statements.add(new ReturnStatement());
    return block;
  });
  negativeTest('Missing function parent pointer', (TestHarness test) {
    var procedure = new Procedure(new Name('bar'), ProcedureKind.Method, null);
    procedure.function = new FunctionNode(new EmptyStatement());
    return procedure;
  });
  negativeTest('StaticGet without target', (TestHarness test) {
    return new StaticGet(null);
  });
  negativeTest('StaticSet without target', (TestHarness test) {
    return new StaticSet(null, new NullLiteral());
  });
  negativeTest('StaticInvocation without target', (TestHarness test) {
    return new StaticInvocation(null, new Arguments.empty());
  });
  positiveTest('Correct StaticInvocation', (TestHarness test) {
    var method = new Procedure(
        new Name('foo'),
        ProcedureKind.Method,
        new FunctionNode(new EmptyStatement(),
            positionalParameters: [new VariableDeclaration('p')]),
        isStatic: true);
    test.enclosingClass.addMember(method);
    return new StaticInvocation(method, new Arguments([new NullLiteral()]));
  });
  negativeTest('StaticInvocation with too many parameters', (TestHarness test) {
    var method = new Procedure(new Name('bar'), ProcedureKind.Method,
        new FunctionNode(new EmptyStatement()),
        isStatic: true);
    test.enclosingClass.addMember(method);
    return new StaticInvocation(method, new Arguments([new NullLiteral()]));
  });
  negativeTest('StaticInvocation with too few parameters', (TestHarness test) {
    var method = new Procedure(
        new Name('bar'),
        ProcedureKind.Method,
        new FunctionNode(new EmptyStatement(),
            positionalParameters: [new VariableDeclaration('p')]),
        isStatic: true);
    test.enclosingClass.addMember(method);
    return new StaticInvocation(method, new Arguments.empty());
  });
  negativeTest('StaticInvocation with unmatched named parameter',
      (TestHarness test) {
    var method = new Procedure(new Name('bar'), ProcedureKind.Method,
        new FunctionNode(new EmptyStatement()),
        isStatic: true);
    test.enclosingClass.addMember(method);
    return new StaticInvocation(
        method,
        new Arguments([],
            named: [new NamedExpression('p', new NullLiteral())]));
  });
  negativeTest('StaticInvocation with missing type argument',
      (TestHarness test) {
    var method = new Procedure(
        new Name('bar'),
        ProcedureKind.Method,
        new FunctionNode(new EmptyStatement(),
            typeParameters: [test.makeTypeParameter()]),
        isStatic: true);
    test.enclosingClass.addMember(method);
    return new StaticInvocation(method, new Arguments.empty());
  });
  negativeTest('ConstructorInvocation with missing type argument',
      (TestHarness test) {
    var class_ = new Class(
        name: 'Test',
        typeParameters: [test.makeTypeParameter()],
        supertype: test.objectClass.asRawSupertype);
    test.enclosingLibrary.addClass(class_);
    var constructor = new Constructor(new FunctionNode(new EmptyStatement()),
        name: new Name('foo'));
    test.enclosingClass.addMember(constructor);
    return new ConstructorInvocation(constructor, new Arguments.empty());
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

class TestHarness {
  Program program;
  Class objectClass;
  Library stubLibrary;

  TypeParameter classTypeParameter;

  Library enclosingLibrary;
  Class enclosingClass;
  Procedure enclosingMember;

  Class otherClass;

  void addNode(TreeNode node) {
    if (node is Expression) {
      addExpression(node);
    } else if (node is Statement) {
      addStatement(node);
    } else if (node is Member) {
      addClassMember(node);
    } else if (node is Class) {
      addClass(node);
    }
  }

  void addExpression(Expression node) {
    addStatement(new ReturnStatement(node));
  }

  void addStatement(Statement node) {
    var function = enclosingMember.function;
    function.body = node..parent = function;
  }

  void addClassMember(Member node) {
    enclosingClass.addMember(node);
  }

  void addTopLevelMember(Member node) {
    enclosingLibrary.addMember(node);
  }

  void addClass(Class node) {
    enclosingLibrary.addClass(node);
  }

  VariableDeclaration makeVariable() => new VariableDeclaration(null);

  TypeParameter makeTypeParameter([String name]) {
    return new TypeParameter(name, new InterfaceType(objectClass));
  }

  TestHarness() {
    setupProgram();
  }

  void setupProgram() {
    program = new Program();
    stubLibrary = new Library(Uri.parse('dart:core'));
    program.libraries.add(stubLibrary..parent = program);
    stubLibrary.name = 'dart.core';
    objectClass = new Class(name: 'Object');
    stubLibrary.addClass(objectClass);
    enclosingLibrary = new Library(Uri.parse('file://test.dart'));
    program.libraries.add(enclosingLibrary..parent = program);
    enclosingLibrary.name = 'test_lib';
    classTypeParameter = makeTypeParameter('T');
    enclosingClass = new Class(
        name: 'TestClass',
        typeParameters: [classTypeParameter],
        supertype: objectClass.asRawSupertype);
    enclosingLibrary.addClass(enclosingClass);
    enclosingMember = new Procedure(new Name('test'), ProcedureKind.Method,
        new FunctionNode(new EmptyStatement()));
    enclosingClass.addMember(enclosingMember);
    otherClass = new Class(
        name: 'OtherClass',
        typeParameters: [makeTypeParameter('OtherT')],
        supertype: objectClass.asRawSupertype);
    enclosingLibrary.addClass(otherClass);
  }
}

negativeTest(String name, TreeNode makeTestCase(TestHarness test)) {
  test(name, () {
    var test = new TestHarness();
    test.addNode(makeTestCase(test));
    checkHasError(test.program);
  });
}

positiveTest(String name, TreeNode makeTestCase(TestHarness test)) {
  test(name, () {
    var test = new TestHarness();
    test.addNode(makeTestCase(test));
    verifyProgram(test.program);
  });
}
