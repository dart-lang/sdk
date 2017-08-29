// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:kernel/ast.dart';
import 'package:kernel/text/ast_to_text.dart';
import 'package:kernel/verifier.dart';
import 'package:test/test.dart';

const String varRegexp = "#t[0-9]+";

const String tvarRegexp = "#T[0-9]+";

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
  negativeTest('VariableGet out of scope',
      matches("Variable '$varRegexp' used out of scope\\."),
      (TestHarness test) {
    return new VariableGet(test.makeVariable());
  });
  negativeTest('VariableSet out of scope',
      matches("Variable '$varRegexp' used out of scope\\."),
      (TestHarness test) {
    return new VariableSet(test.makeVariable(), new NullLiteral());
  });
  negativeTest('Variable block scope',
      matches("Variable '$varRegexp' used out of scope\\."),
      (TestHarness test) {
    VariableDeclaration variable = test.makeVariable();
    return new Block([
      new Block([variable]),
      new ReturnStatement(new VariableGet(variable))
    ]);
  });
  negativeTest('Variable let scope',
      matches("Variable '$varRegexp' used out of scope\\."),
      (TestHarness test) {
    VariableDeclaration variable = test.makeVariable();
    return new LogicalExpression(new Let(variable, new VariableGet(variable)),
        '&&', new VariableGet(variable));
  });
  negativeTest('Variable redeclared',
      matches("Variable '$varRegexp' declared more than once\\."),
      (TestHarness test) {
    VariableDeclaration variable = test.makeVariable();
    return new Block([variable, variable]);
  });
  negativeTest('Member redeclared',
      "Member 'test_lib::Test::field' has been declared more than once.",
      (TestHarness test) {
    Field field = new Field(new Name('field'), initializer: new NullLiteral());
    return new Class(
        name: 'Test',
        supertype: test.objectClass.asRawSupertype,
        fields: [field, field]);
  });
  negativeTest('Class redeclared',
      "Class 'test_lib::OtherClass' declared more than once.",
      (TestHarness test) {
    return test.otherClass; // Test harness also adds otherClass to program.
  });
  negativeTest('Class type parameter redeclared',
      matches("Type parameter 'test_lib::Test::$tvarRegexp' redeclared\\."),
      (TestHarness test) {
    var parameter = test.makeTypeParameter();
    return new Class(
        name: 'Test',
        supertype: test.objectClass.asRawSupertype,
        typeParameters: [parameter, parameter]);
  });
  negativeTest('Member type parameter redeclared',
      matches("Type parameter '$tvarRegexp' redeclared\\."),
      (TestHarness test) {
    var parameter = test.makeTypeParameter();
    return new Procedure(
        new Name('bar'),
        ProcedureKind.Method,
        new FunctionNode(new ReturnStatement(new NullLiteral()),
            typeParameters: [parameter, parameter]));
  });
  negativeTest(
      'Type parameter out of scope',
      matches("Type parameter '$tvarRegexp' referenced out of scope,"
          " parent is: 'null'\\."), (TestHarness test) {
    var parameter = test.makeTypeParameter();
    return new ListLiteral([], typeArgument: new TypeParameterType(parameter));
  });
  negativeTest(
      'Class type parameter from another class',
      "Type parameter 'test_lib::OtherClass::OtherT' referenced out of scope,"
      " parent is: 'test_lib::OtherClass'.", (TestHarness test) {
    return new TypeLiteral(
        new TypeParameterType(test.otherClass.typeParameters[0]));
  });
  negativeTest(
      'Class type parameter in static method',
      "Type parameter 'test_lib::TestClass::T' referenced from static context,"
      " parent is 'test_lib::TestClass'.", (TestHarness test) {
    return new Procedure(
        new Name('bar'),
        ProcedureKind.Method,
        new FunctionNode(new ReturnStatement(
            new TypeLiteral(new TypeParameterType(test.classTypeParameter)))),
        isStatic: true);
  });
  negativeTest(
      'Class type parameter in static field',
      "Type parameter 'test_lib::TestClass::T' referenced from static context,"
      " parent is 'test_lib::TestClass'.", (TestHarness test) {
    return new Field(new Name('field'),
        initializer:
            new TypeLiteral(new TypeParameterType(test.classTypeParameter)),
        isStatic: true);
  });
  negativeTest(
      'Method type parameter out of scope',
      matches("Type parameter '$tvarRegexp' referenced out of scope,"
          " parent is: '<FunctionNode>'\\."), (TestHarness test) {
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
  negativeTest(
      'Interface type arity too low',
      "Type test_lib::OtherClass provides 0 type arguments"
      " but the class declares 1 parameters.", (TestHarness test) {
    return new TypeLiteral(new InterfaceType(test.otherClass, []));
  });
  negativeTest(
      'Interface type arity too high',
      "Type test_lib::OtherClass<dynamic, dynamic> provides 2 type arguments"
      " but the class declares 1 parameters.", (TestHarness test) {
    return new TypeLiteral(new InterfaceType(
        test.otherClass, [new DynamicType(), new DynamicType()]));
  });
  negativeTest(
      'Dangling interface type',
      matches("Dangling reference to 'null::#class[0-9]+',"
          " parent is: 'null'\\."), (TestHarness test) {
    var orphan = new Class();
    return new TypeLiteral(new InterfaceType(orphan));
  });
  negativeTest('Dangling field get',
      "Dangling reference to 'null::foo', parent is: 'null'.",
      (TestHarness test) {
    var orphan = new Field(new Name('foo'));
    return new DirectPropertyGet(new NullLiteral(), orphan);
  });
  negativeTest(
      'Missing block parent pointer',
      "Incorrect parent pointer on ReturnStatement:"
      " expected 'Block', but found: 'Null'.", (TestHarness test) {
    var block = new Block([]);
    block.statements.add(new ReturnStatement());
    return block;
  });
  negativeTest(
      'Missing function parent pointer',
      "Incorrect parent pointer on FunctionNode:"
      " expected 'Procedure', but found: 'Null'.", (TestHarness test) {
    var procedure = new Procedure(new Name('bar'), ProcedureKind.Method, null);
    procedure.function = new FunctionNode(new EmptyStatement());
    return procedure;
  });
  negativeTest('StaticGet without target', "StaticGet without target.",
      (TestHarness test) {
    return new StaticGet(null);
  });
  negativeTest('StaticSet without target', "StaticSet without target.",
      (TestHarness test) {
    return new StaticSet(null, new NullLiteral());
  });
  negativeTest(
      'StaticInvocation without target', "StaticInvocation without target.",
      (TestHarness test) {
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
  negativeTest(
      'StaticInvocation with too many parameters',
      "StaticInvocation with incompatible arguments for"
      " 'test_lib::TestClass::bar'.", (TestHarness test) {
    var method = new Procedure(new Name('bar'), ProcedureKind.Method,
        new FunctionNode(new EmptyStatement()),
        isStatic: true);
    test.enclosingClass.addMember(method);
    return new StaticInvocation(method, new Arguments([new NullLiteral()]));
  });
  negativeTest(
      'StaticInvocation with too few parameters',
      "StaticInvocation with incompatible arguments for"
      " 'test_lib::TestClass::bar'.", (TestHarness test) {
    var method = new Procedure(
        new Name('bar'),
        ProcedureKind.Method,
        new FunctionNode(new EmptyStatement(),
            positionalParameters: [new VariableDeclaration('p')]),
        isStatic: true);
    test.enclosingClass.addMember(method);
    return new StaticInvocation(method, new Arguments.empty());
  });
  negativeTest(
      'StaticInvocation with unmatched named parameter',
      "StaticInvocation with incompatible arguments for"
      " 'test_lib::TestClass::bar'.", (TestHarness test) {
    var method = new Procedure(new Name('bar'), ProcedureKind.Method,
        new FunctionNode(new EmptyStatement()),
        isStatic: true);
    test.enclosingClass.addMember(method);
    return new StaticInvocation(
        method,
        new Arguments([],
            named: [new NamedExpression('p', new NullLiteral())]));
  });
  negativeTest(
      'StaticInvocation with missing type argument',
      "StaticInvocation with wrong number of type arguments for"
      " 'test_lib::TestClass::bar'.", (TestHarness test) {
    var method = new Procedure(
        new Name('bar'),
        ProcedureKind.Method,
        new FunctionNode(new EmptyStatement(),
            typeParameters: [test.makeTypeParameter()]),
        isStatic: true);
    test.enclosingClass.addMember(method);
    return new StaticInvocation(method, new Arguments.empty());
  });
  negativeTest(
      'ConstructorInvocation with missing type argument',
      "ConstructorInvocation with wrong number of type arguments for"
      " 'test_lib::TestClass::foo'.", (TestHarness test) {
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
    var field = new Field(new Name('field'),
        type: new TypedefType(typedef_), isStatic: true);
    test.enclosingLibrary.addTypedef(typedef_);
    test.enclosingLibrary.addMember(field);
  });
  negativeTest(
      'Invalid typedef Foo = Foo',
      "The typedef 'typedef Foo = test_lib::Foo;\n'"
      " refers to itself", (TestHarness test) {
    var typedef_ = new Typedef('Foo', null);
    typedef_.type = new TypedefType(typedef_);
    test.enclosingLibrary.addTypedef(typedef_);
  });
  negativeTest(
      'Invalid typedef Foo = `(Foo) => void`',
      "The typedef 'typedef Foo = (test_lib::Foo) → void;\n'"
      " refers to itself", (TestHarness test) {
    var typedef_ = new Typedef('Foo', null);
    typedef_.type =
        new FunctionType([new TypedefType(typedef_)], const VoidType());
    test.enclosingLibrary.addTypedef(typedef_);
  });
  negativeTest(
      'Invalid typedef Foo = `() => Foo`',
      "The typedef 'typedef Foo = () → test_lib::Foo;\n'"
      " refers to itself", (TestHarness test) {
    var typedef_ = new Typedef('Foo', null);
    typedef_.type = new FunctionType([], new TypedefType(typedef_));
    test.enclosingLibrary.addTypedef(typedef_);
  });
  negativeTest(
      'Invalid typedef Foo = C<Foo>',
      "The typedef 'typedef Foo = test_lib::OtherClass<test_lib::Foo>;\n'"
      " refers to itself", (TestHarness test) {
    var typedef_ = new Typedef('Foo', null);
    typedef_.type =
        new InterfaceType(test.otherClass, [new TypedefType(typedef_)]);
    test.enclosingLibrary.addTypedef(typedef_);
  });
  negativeTest(
      'Invalid typedefs Foo = Bar, Bar = Foo',
      "The typedef 'typedef Foo = test_lib::Bar;\n'"
      " refers to itself", (TestHarness test) {
    var foo = new Typedef('Foo', null);
    var bar = new Typedef('Bar', null);
    foo.type = new TypedefType(bar);
    bar.type = new TypedefType(foo);
    test.enclosingLibrary.addTypedef(foo);
    test.enclosingLibrary.addTypedef(bar);
  });
  negativeTest(
      'Invalid typedefs Foo = Bar, Bar = C<Foo>',
      "The typedef 'typedef Foo = test_lib::Bar;\n'"
      " refers to itself", (TestHarness test) {
    var foo = new Typedef('Foo', null);
    var bar = new Typedef('Bar', null);
    foo.type = new TypedefType(bar);
    bar.type = new InterfaceType(test.otherClass, [new TypedefType(foo)]);
    test.enclosingLibrary.addTypedef(foo);
    test.enclosingLibrary.addTypedef(bar);
  });
  negativeTest(
      'Invalid typedefs Foo = C<Bar>, Bar = C<Foo>',
      "The typedef 'typedef Foo = test_lib::OtherClass<test_lib::Bar>;\n'"
      " refers to itself", (TestHarness test) {
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
  negativeTest(
      'Invalid long typedefs C20 = C19 = ... = C1 = C0 = C20',
      "The typedef 'typedef C0 = test_lib::C19;\n'"
      " refers to itself", (TestHarness test) {
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
  negativeTest(
      'Invalid typedefs Foo<T extends Bar<T>>, Bar<T extends Foo<T>>',
      "The typedef 'typedef Foo<T extends test_lib::Bar<T>> = dynamic;\n'"
      " refers to itself", (TestHarness test) {
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
  negativeTest(
      'Invalid typedef Foo<T extends Foo<dynamic> = C<T>',
      "The typedef 'typedef Foo<T extends test_lib::Foo<dynamic>> = "
      "test_lib::OtherClass<T>;\n'"
      " refers to itself", (TestHarness test) {
    var param = new TypeParameter('T', null);
    var foo = new Typedef('Foo',
        new InterfaceType(test.otherClass, [new TypeParameterType(param)]),
        typeParameters: [param]);
    param.bound = new TypedefType(foo, [const DynamicType()]);
    test.enclosingLibrary.addTypedef(foo);
  });
  negativeTest(
      'Typedef arity error',
      "The typedef type test_lib::Foo provides 0 type arguments"
      " but the typedef declares 1 parameters.", (TestHarness test) {
    var param = test.makeTypeParameter('T');
    var foo =
        new Typedef('Foo', test.otherClass.rawType, typeParameters: [param]);
    var field = new Field(new Name('field'),
        type: new TypedefType(foo, []), isStatic: true);
    test.enclosingLibrary.addTypedef(foo);
    test.enclosingLibrary.addMember(field);
  });
  negativeTest(
      'Dangling typedef reference',
      "Dangling reference to 'typedef Foo = test_lib::OtherClass<dynamic>;\n'"
      ", parent is: 'null'", (TestHarness test) {
    var foo = new Typedef('Foo', test.otherClass.rawType, typeParameters: []);
    var field = new Field(new Name('field'),
        type: new TypedefType(foo, []), isStatic: true);
    test.enclosingLibrary.addMember(field);
  });
  negativeTest('Non-static top-level field',
      "The top-level field 'field' should be static", (TestHarness test) {
    var field = new Field(new Name('field'));
    test.enclosingLibrary.addMember(field);
  });
}

checkHasError(Program program, Matcher matcher) {
  try {
    verifyProgram(program);
  } on VerificationError catch (e) {
    expect(e.details, matcher);
    return;
  }
  fail('Failed to reject invalid program:\n${programToString(program)}');
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

negativeTest(String name, matcher, TreeNode makeTestCase(TestHarness test)) {
  if (matcher is String) {
    matcher = equals(matcher);
  }
  test(name, () {
    var test = new TestHarness();
    test.addNode(makeTestCase(test));
    checkHasError(test.program, matcher);
  });
}

positiveTest(String name, TreeNode makeTestCase(TestHarness test)) {
  test(name, () {
    var test = new TestHarness();
    test.addNode(makeTestCase(test));
    verifyProgram(test.program);
  });
}
