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
  positiveTest('Valid typedef Foo = `(C) => void`', (TestHarness test) {
    var typedef_ = new Typedef(
        'Foo', new FunctionType([test.otherClass.rawType], const VoidType()));
    test.enclosingLibrary.addTypedef(typedef_);
  });
  positiveTest('Valid typedef Foo = C<dynamic>', (TestHarness test) {
    var typedef_ = new Typedef(
        'Foo', new InterfaceType(test.otherClass, [const DynamicType()]));
    test.enclosingLibrary.addTypedef(typedef_);
  });
  positiveTest('Valid typedefs Foo = Bar, Bar = C', (TestHarness test) {
    var foo = new Typedef('Foo', null);
    var bar = new Typedef('Bar', null);
    foo.type = new TypedefType(bar);
    bar.type = test.otherClass.rawType;
    test.enclosingLibrary.addTypedef(foo);
    test.enclosingLibrary.addTypedef(bar);
  });
  positiveTest('Valid typedefs Foo = C<Bar>, Bar = C', (TestHarness test) {
    var foo = new Typedef('Foo', null);
    var bar = new Typedef('Bar', null);
    foo.type = new InterfaceType(test.otherClass, [new TypedefType(bar)]);
    bar.type = test.otherClass.rawType;
    test.enclosingLibrary.addTypedef(foo);
    test.enclosingLibrary.addTypedef(bar);
  });
  positiveTest('Valid typedef type in field', (TestHarness test) {
    var typedef_ = new Typedef(
        'Foo', new FunctionType([test.otherClass.rawType], const VoidType()));
    var field = new Field(new Name('field'), type: new TypedefType(typedef_));
    test.enclosingLibrary.addTypedef(typedef_);
    test.enclosingLibrary.addMember(field);
  });
  negativeTest('Invalid typedef Foo = Foo', (TestHarness test) {
    var typedef_ = new Typedef('Foo', null);
    typedef_.type = new TypedefType(typedef_);
    test.enclosingLibrary.addTypedef(typedef_);
  });
  negativeTest('Invalid typedef Foo = `(Foo) => void`', (TestHarness test) {
    var typedef_ = new Typedef('Foo', null);
    typedef_.type =
        new FunctionType([new TypedefType(typedef_)], const VoidType());
    test.enclosingLibrary.addTypedef(typedef_);
  });
  negativeTest('Invalid typedef Foo = `() => Foo`', (TestHarness test) {
    var typedef_ = new Typedef('Foo', null);
    typedef_.type = new FunctionType([], new TypedefType(typedef_));
    test.enclosingLibrary.addTypedef(typedef_);
  });
  negativeTest('Invalid typedef Foo = C<Foo>', (TestHarness test) {
    var typedef_ = new Typedef('Foo', null);
    typedef_.type =
        new InterfaceType(test.otherClass, [new TypedefType(typedef_)]);
    test.enclosingLibrary.addTypedef(typedef_);
  });
  negativeTest('Invalid typedefs Foo = Bar, Bar = Foo', (TestHarness test) {
    var foo = new Typedef('Foo', null);
    var bar = new Typedef('Bar', null);
    foo.type = new TypedefType(bar);
    bar.type = new TypedefType(foo);
    test.enclosingLibrary.addTypedef(foo);
    test.enclosingLibrary.addTypedef(bar);
  });
  negativeTest('Invalid typedefs Foo = Bar, Bar = C<Foo>', (TestHarness test) {
    var foo = new Typedef('Foo', null);
    var bar = new Typedef('Bar', null);
    foo.type = new TypedefType(bar);
    bar.type = new InterfaceType(test.otherClass, [new TypedefType(foo)]);
    test.enclosingLibrary.addTypedef(foo);
    test.enclosingLibrary.addTypedef(bar);
  });
  negativeTest('Invalid typedefs Foo = C<Bar>, Bar = C<Foo>',
      (TestHarness test) {
    var foo = new Typedef('Foo', null);
    var bar = new Typedef('Bar', null);
    foo.type = new InterfaceType(test.otherClass, [new TypedefType(bar)]);
    bar.type = new InterfaceType(test.otherClass, [new TypedefType(foo)]);
    test.enclosingLibrary.addTypedef(foo);
    test.enclosingLibrary.addTypedef(bar);
  });
  positiveTest('Valid long typedefs C20 = C19 = ... = C1 = C0 = dynamic',
      (TestHarness test) {
    var typedef_ = new Typedef('C0', const DynamicType());
    test.enclosingLibrary.addTypedef(typedef_);
    for (int i = 1; i < 20; ++i) {
      typedef_ = new Typedef('C$i', new TypedefType(typedef_));
      test.enclosingLibrary.addTypedef(typedef_);
    }
  });
  negativeTest('Invalid long typedefs C20 = C19 = ... = C1 = C0 = C20',
      (TestHarness test) {
    var typedef_ = new Typedef('C0', null);
    test.enclosingLibrary.addTypedef(typedef_);
    var first = typedef_;
    for (int i = 1; i < 20; ++i) {
      typedef_ = new Typedef('C$i', new TypedefType(typedef_));
      test.enclosingLibrary.addTypedef(typedef_);
    }
    first.type = new TypedefType(typedef_);
  });
  positiveTest('Valid typedef Foo<T extends C> = C<T>', (TestHarness test) {
    var param = new TypeParameter('T', test.otherClass.rawType);
    var foo = new Typedef('Foo',
        new InterfaceType(test.otherClass, [new TypeParameterType(param)]),
        typeParameters: [param]);
    test.enclosingLibrary.addTypedef(foo);
  });
  positiveTest('Valid typedef Foo<T extends C<T>> = C<T>', (TestHarness test) {
    var param = new TypeParameter('T', test.otherClass.rawType);
    param.bound =
        new InterfaceType(test.otherClass, [new TypeParameterType(param)]);
    var foo = new Typedef('Foo',
        new InterfaceType(test.otherClass, [new TypeParameterType(param)]),
        typeParameters: [param]);
    test.enclosingLibrary.addTypedef(foo);
  });
  positiveTest('Valid typedef Foo<T> = dynamic, Bar<T extends Foo<T>> = C<T>',
      (TestHarness test) {
    var fooParam = test.makeTypeParameter('T');
    var foo =
        new Typedef('Foo', const DynamicType(), typeParameters: [fooParam]);
    var barParam = new TypeParameter('T', null);
    barParam.bound = new TypedefType(foo, [new TypeParameterType(barParam)]);
    var bar = new Typedef('Bar',
        new InterfaceType(test.otherClass, [new TypeParameterType(barParam)]),
        typeParameters: [barParam]);
    test.enclosingLibrary.addTypedef(foo);
    test.enclosingLibrary.addTypedef(bar);
  });
  negativeTest('Invalid typedefs Foo<T extends Bar<T>>, Bar<T extends Foo<T>>',
      (TestHarness test) {
    var fooParam = test.makeTypeParameter('T');
    var foo =
        new Typedef('Foo', const DynamicType(), typeParameters: [fooParam]);
    var barParam = new TypeParameter('T', null);
    barParam.bound = new TypedefType(foo, [new TypeParameterType(barParam)]);
    var bar = new Typedef('Bar',
        new InterfaceType(test.otherClass, [new TypeParameterType(barParam)]),
        typeParameters: [barParam]);
    fooParam.bound = new TypedefType(bar, [new TypeParameterType(fooParam)]);
    test.enclosingLibrary.addTypedef(foo);
    test.enclosingLibrary.addTypedef(bar);
  });
  negativeTest('Invalid typedef Foo<T extends Foo<dynamic> = C<T>',
      (TestHarness test) {
    var param = new TypeParameter('T', null);
    var foo = new Typedef('Foo',
        new InterfaceType(test.otherClass, [new TypeParameterType(param)]),
        typeParameters: [param]);
    param.bound = new TypedefType(foo, [const DynamicType()]);
    test.enclosingLibrary.addTypedef(foo);
  });
  negativeTest('Typedef arity error', (TestHarness test) {
    var param = test.makeTypeParameter('T');
    var foo =
        new Typedef('Foo', test.otherClass.rawType, typeParameters: [param]);
    var field = new Field(new Name('field'), type: new TypedefType(foo, []));
    test.enclosingLibrary.addTypedef(foo);
    test.enclosingLibrary.addMember(field);
  });
  negativeTest('Dangling typedef reference', (TestHarness test) {
    var foo = new Typedef('Foo', test.otherClass.rawType, typeParameters: []);
    var field = new Field(new Name('field'), type: new TypedefType(foo, []));
    test.enclosingLibrary.addMember(field);
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
