// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:kernel/ast.dart';
import 'package:kernel/text/ast_to_text.dart';
import 'package:kernel/verifier.dart';
import 'package:test/test.dart';

/// Checks that the verifier correctly find errors in invalid components.
///
/// The frontend should never generate invalid components, so we have to test
/// these by manually constructing invalid ASTs.
///
/// We mostly test negative cases here, as we get plenty of positive cases by
/// compiling the Dart test suite with the verifier enabled.
main() {
  positiveTest(
    'Test harness has no errors',
    (TestHarness test) {
      test.addNode(NullLiteral());
    },
  );
  negative1Test(
    'VariableGet out of scope',
    (TestHarness test) {
      VariableDeclaration node = test.makeVariable();
      test.addNode(VariableGet(node));
      return node;
    },
    (Node node) => "Variable '$node' used out of scope.",
  );
  negative1Test(
    'VariableSet out of scope',
    (TestHarness test) {
      VariableDeclaration variable = test.makeVariable();
      test.addNode(VariableSet(variable, new NullLiteral()));
      return variable;
    },
    (Node node) => "Variable '$node' used out of scope.",
  );
  negative1Test(
    'Variable block scope',
    (TestHarness test) {
      VariableDeclaration variable = test.makeVariable();
      test.addNode(Block([
        new Block([variable]),
        new ReturnStatement(new VariableGet(variable))
      ]));
      return variable;
    },
    (Node node) => "Variable '$node' used out of scope.",
  );
  negative1Test(
    'Variable let scope',
    (TestHarness test) {
      VariableDeclaration variable = test.makeVariable();
      test.addNode(LogicalExpression(
          new Let(variable, new VariableGet(variable)),
          LogicalExpressionOperator.AND,
          new VariableGet(variable)));
      return variable;
    },
    (Node node) => "Variable '$node' used out of scope.",
  );
  negative1Test(
    'Variable redeclared',
    (TestHarness test) {
      VariableDeclaration variable = test.makeVariable();
      test.addNode(Block([variable, variable]));
      return variable;
    },
    (Node node) => "Variable '$node' declared more than once.",
  );
  negative1Test(
    'Member redeclared',
    (TestHarness test) {
      Field field =
          new Field(new Name('field'), initializer: new NullLiteral());
      test.addNode(Class(
          name: 'Test',
          supertype: test.objectClass.asRawSupertype,
          fields: [field, field]));
      return field;
    },
    (Node node) => "Member '$node' has been declared more than once.",
  );
  negative1Test(
    'Class redeclared',
    (TestHarness test) {
      Class otherClass = test.otherClass;
      test.addNode(
          otherClass); // Test harness also adds otherClass to component.
      return test.otherClass;
    },
    (Node node) => "Class '$node' declared more than once.",
  );
  negative1Test(
    'Class type parameter redeclared',
    (TestHarness test) {
      TypeParameter parameter = test.makeTypeParameter();
      test.addNode(Class(
          name: 'Test',
          supertype: test.objectClass.asRawSupertype,
          typeParameters: [parameter, parameter]));
      return parameter;
    },
    (Node node) => "Type parameter '$node' redeclared.",
  );
  negative1Test(
    'Member type parameter redeclared',
    (TestHarness test) {
      TypeParameter parameter = test.makeTypeParameter();
      test.addNode(Procedure(
          new Name('bar'),
          ProcedureKind.Method,
          new FunctionNode(new ReturnStatement(new NullLiteral()),
              typeParameters: [parameter, parameter])));

      return parameter;
    },
    (Node node) => "Type parameter '$node' redeclared.",
  );
  negative2Test(
    'Type parameter out of scope',
    (TestHarness test) {
      TypeParameter parameter = test.makeTypeParameter();
      test.addNode(ListLiteral([],
          typeArgument: new TypeParameterType(parameter, Nullability.legacy)));
      return [parameter, null];
    },
    (Node node, Node parent) =>
        "Type parameter '$node' referenced out of scope,"
        " parent is: '$parent'.",
  );
  negative2Test(
    'Class type parameter from another class',
    (TestHarness test) {
      TypeParameter node = test.otherClass.typeParameters[0];
      test.addNode(
          TypeLiteral(new TypeParameterType(node, Nullability.legacy)));
      return [node, test.otherClass];
    },
    (Node node, Node parent) =>
        "Type parameter '$node' referenced out of scope,"
        " parent is: '$parent'.",
  );
  negative2Test(
    'Class type parameter in static method',
    (TestHarness test) {
      TypeParameter node = test.classTypeParameter;
      test.addNode(Procedure(
          new Name('bar'),
          ProcedureKind.Method,
          new FunctionNode(new ReturnStatement(new TypeLiteral(
              new TypeParameterType(node, Nullability.legacy)))),
          isStatic: true));

      return [node, test.enclosingClass];
    },
    (Node node, Node parent) =>
        "Type parameter '$node' referenced from static context,"
        " parent is: '$parent'.",
  );
  negative2Test(
    'Class type parameter in static field',
    (TestHarness test) {
      TypeParameter node = test.classTypeParameter;
      test.addNode(Field(new Name('field'),
          initializer:
              new TypeLiteral(new TypeParameterType(node, Nullability.legacy)),
          isStatic: true));
      return [node, test.enclosingClass];
    },
    (Node node, Node parent) =>
        "Type parameter '$node' referenced from static context,"
        " parent is: '$parent'.",
  );
  negative2Test(
    'Method type parameter out of scope',
    (TestHarness test) {
      TypeParameter parameter = test.makeTypeParameter();
      FunctionNode parent =
          new FunctionNode(new EmptyStatement(), typeParameters: [parameter]);
      test.addNode(Class(
          name: 'Test',
          supertype: test.objectClass.asRawSupertype,
          procedures: [
            new Procedure(new Name('generic'), ProcedureKind.Method, parent),
            new Procedure(
                new Name('use'),
                ProcedureKind.Method,
                new FunctionNode(new ReturnStatement(new TypeLiteral(
                    new TypeParameterType(parameter, Nullability.legacy)))))
          ]));

      return [parameter, parent];
    },
    (Node node, Node parent) =>
        "Type parameter '$node' referenced out of scope,"
        " parent is: '$parent'.",
  );
  negative1Test(
    'Interface type arity too low',
    (TestHarness test) {
      InterfaceType node =
          new InterfaceType(test.otherClass, Nullability.legacy, []);
      test.addNode(TypeLiteral(node));
      return node;
    },
    (Node node) => "Type $node provides 0 type arguments,"
        " but the class declares 1 parameters.",
  );
  negative1Test(
    'Interface type arity too high',
    (TestHarness test) {
      InterfaceType node = new InterfaceType(test.otherClass,
          Nullability.legacy, [new DynamicType(), new DynamicType()]);
      test.addNode(TypeLiteral(node));
      return node;
    },
    (Node node) => "Type $node provides 2 type arguments,"
        " but the class declares 1 parameters.",
  );
  negative1Test(
    'Dangling interface type',
    (TestHarness test) {
      Class orphan = new Class();
      test.addNode(
          new TypeLiteral(new InterfaceType(orphan, Nullability.legacy)));
      return orphan;
    },
    (Node node) => "Dangling reference to '$node', parent is: 'null'.",
  );
  negative1Test(
    'Dangling field get',
    (TestHarness test) {
      Field orphan = new Field(new Name('foo'));
      test.addNode(new PropertyGet(new NullLiteral(), orphan.name, orphan));
      return orphan;
    },
    (Node node) => "Dangling reference to '$node', parent is: 'null'.",
  );
  simpleNegativeTest(
    'Missing block parent pointer',
    "Incorrect parent pointer on ReturnStatement:"
        " expected 'Block', but found: 'Null'.",
    (TestHarness test) {
      var block = new Block([]);
      block.statements.add(new ReturnStatement());
      test.addNode(block);
    },
  );
  simpleNegativeTest(
    'Missing function parent pointer',
    "Incorrect parent pointer on FunctionNode:"
        " expected 'Procedure', but found: 'Null'.",
    (TestHarness test) {
      var procedure =
          new Procedure(new Name('bar'), ProcedureKind.Method, null);
      procedure.function = new FunctionNode(new EmptyStatement());
      test.addNode(procedure);
    },
  );
  simpleNegativeTest(
    'StaticGet without target',
    "StaticGet without target.",
    (TestHarness test) {
      test.addNode(StaticGet(null));
    },
  );
  simpleNegativeTest(
    'StaticSet without target',
    "StaticSet without target.",
    (TestHarness test) {
      test.addNode(StaticSet(null, new NullLiteral()));
    },
  );
  simpleNegativeTest(
    'StaticInvocation without target',
    "StaticInvocation without target.",
    (TestHarness test) {
      test.addNode(StaticInvocation(null, new Arguments.empty()));
    },
  );
  positiveTest(
    'Correct StaticInvocation',
    (TestHarness test) {
      var method = new Procedure(
          new Name('foo'),
          ProcedureKind.Method,
          new FunctionNode(new EmptyStatement(),
              positionalParameters: [new VariableDeclaration('p')]),
          isStatic: true);
      test.enclosingClass.addProcedure(method);
      test.addNode(
          StaticInvocation(method, new Arguments([new NullLiteral()])));
    },
  );
  negative1Test(
    'StaticInvocation with too many parameters',
    (TestHarness test) {
      var method = new Procedure(new Name('bar'), ProcedureKind.Method,
          new FunctionNode(new EmptyStatement()),
          isStatic: true);
      test.enclosingClass.addProcedure(method);
      test.addNode(
          StaticInvocation(method, new Arguments([new NullLiteral()])));
      return method;
    },
    (Node node) => "StaticInvocation with incompatible arguments for"
        " '$node'.",
  );
  negative1Test(
    'StaticInvocation with too few parameters',
    (TestHarness test) {
      var method = new Procedure(
          new Name('bar'),
          ProcedureKind.Method,
          new FunctionNode(new EmptyStatement(),
              positionalParameters: [new VariableDeclaration('p')]),
          isStatic: true);
      test.enclosingClass.addProcedure(method);
      test.addNode(StaticInvocation(method, new Arguments.empty()));
      return method;
    },
    (Node node) => "StaticInvocation with incompatible arguments for '$node'.",
  );
  negative1Test(
    'StaticInvocation with unmatched named parameter',
    (TestHarness test) {
      var method = new Procedure(new Name('bar'), ProcedureKind.Method,
          new FunctionNode(new EmptyStatement()),
          isStatic: true);
      test.enclosingClass.addProcedure(method);
      test.addNode(StaticInvocation(
          method,
          new Arguments([],
              named: [new NamedExpression('p', new NullLiteral())])));
      return method;
    },
    (Node node) => "StaticInvocation with incompatible arguments for"
        " '$node'.",
  );
  negative1Test(
    'StaticInvocation with missing type argument',
    (TestHarness test) {
      Procedure method = new Procedure(
          new Name('bar'),
          ProcedureKind.Method,
          new FunctionNode(new EmptyStatement(),
              typeParameters: [test.makeTypeParameter()]),
          isStatic: true);
      test.enclosingClass.addProcedure(method);
      test.addNode(StaticInvocation(method, new Arguments.empty()));
      return method;
    },
    (Node node) => "StaticInvocation with wrong number of type arguments for"
        " '$node'.",
  );
  negative1Test(
    'ConstructorInvocation with missing type argument',
    (TestHarness test) {
      var constructor = new Constructor(new FunctionNode(new EmptyStatement()),
          name: new Name('foo'));
      test.enclosingClass.addConstructor(constructor);
      test.addNode(ConstructorInvocation(constructor, new Arguments.empty()));
      return constructor;
    },
    (Node node) =>
        "ConstructorInvocation with wrong number of type arguments for"
        " '$node'.",
  );
  positiveTest(
    'Valid typedef Foo = `(C) => void`',
    (TestHarness test) {
      var typedef_ = new Typedef(
          'Foo',
          new FunctionType(
              [test.otherLegacyRawType], const VoidType(), Nullability.legacy));
      test.addNode(typedef_);
    },
  );
  positiveTest(
    'Valid typedef Foo = C<dynamic>',
    (TestHarness test) {
      var typedef_ = new Typedef(
          'Foo',
          new InterfaceType(
              test.otherClass, Nullability.legacy, [const DynamicType()]));
      test.addNode(typedef_);
    },
  );
  positiveTest(
    'Valid typedefs Foo = Bar, Bar = C',
    (TestHarness test) {
      var foo = new Typedef('Foo', null);
      var bar = new Typedef('Bar', null);
      foo.type = new TypedefType(bar, Nullability.legacy);
      bar.type = test.otherLegacyRawType;
      test.enclosingLibrary.addTypedef(foo);
      test.enclosingLibrary.addTypedef(bar);
    },
  );
  positiveTest(
    'Valid typedefs Foo = C<Bar>, Bar = C',
    (TestHarness test) {
      var foo = new Typedef('Foo', null);
      var bar = new Typedef('Bar', null);
      foo.type = new InterfaceType(test.otherClass, Nullability.legacy,
          [new TypedefType(bar, Nullability.legacy)]);
      bar.type = test.otherLegacyRawType;
      test.enclosingLibrary.addTypedef(foo);
      test.enclosingLibrary.addTypedef(bar);
    },
  );
  positiveTest(
    'Valid typedef type in field',
    (TestHarness test) {
      var typedef_ = new Typedef(
          'Foo',
          new FunctionType(
              [test.otherLegacyRawType], const VoidType(), Nullability.legacy));
      var field = new Field(new Name('field'),
          type: new TypedefType(typedef_, Nullability.legacy), isStatic: true);
      test.enclosingLibrary.addTypedef(typedef_);
      test.enclosingLibrary.addField(field);
    },
  );
  negative1Test(
    'Invalid typedef Foo = Foo',
    (TestHarness test) {
      var typedef_ = new Typedef('Foo', null);
      typedef_.type = new TypedefType(typedef_, Nullability.legacy);
      test.addNode(typedef_);
      return typedef_;
    },
    (Node node) => "The typedef '$node' refers to itself",
  );
  negative1Test(
    'Invalid typedef Foo = `(Foo) => void`',
    (TestHarness test) {
      var typedef_ = new Typedef('Foo', null);
      typedef_.type = new FunctionType(
          [new TypedefType(typedef_, Nullability.legacy)],
          const VoidType(),
          Nullability.legacy);
      test.addNode(typedef_);
      return typedef_;
    },
    (Node node) => "The typedef '$node' refers to itself",
  );
  negative1Test(
    'Invalid typedef Foo = `() => Foo`',
    (TestHarness test) {
      var typedef_ = new Typedef('Foo', null);
      typedef_.type = new FunctionType([],
          new TypedefType(typedef_, Nullability.legacy), Nullability.legacy);
      test.addNode(typedef_);
      return typedef_;
    },
    (Node node) => "The typedef '$node' refers to itself",
  );
  negative1Test(
    'Invalid typedef Foo = C<Foo>',
    (TestHarness test) {
      var typedef_ = new Typedef('Foo', null);
      typedef_.type = new InterfaceType(test.otherClass, Nullability.legacy,
          [new TypedefType(typedef_, Nullability.legacy)]);
      test.addNode(typedef_);
      return typedef_;
    },
    (Node node) => "The typedef '$node' refers to itself",
  );
  negative1Test(
    'Invalid typedefs Foo = Bar, Bar = Foo',
    (TestHarness test) {
      var foo = new Typedef('Foo', null);
      var bar = new Typedef('Bar', null);
      foo.type = new TypedefType(bar, Nullability.legacy);
      bar.type = new TypedefType(foo, Nullability.legacy);
      test.enclosingLibrary.addTypedef(foo);
      test.enclosingLibrary.addTypedef(bar);
      return foo;
    },
    (Node foo) => "The typedef '$foo' refers to itself",
  );
  negative1Test(
    'Invalid typedefs Foo = Bar, Bar = C<Foo>',
    (TestHarness test) {
      var foo = new Typedef('Foo', null);
      var bar = new Typedef('Bar', null);
      foo.type = new TypedefType(bar, Nullability.legacy);
      bar.type = new InterfaceType(test.otherClass, Nullability.legacy,
          [new TypedefType(foo, Nullability.legacy)]);
      test.enclosingLibrary.addTypedef(foo);
      test.enclosingLibrary.addTypedef(bar);
      return foo;
    },
    (Node foo) => "The typedef '$foo' refers to itself",
  );
  negative1Test(
    'Invalid typedefs Foo = C<Bar>, Bar = C<Foo>',
    (TestHarness test) {
      var foo = new Typedef('Foo', null);
      var bar = new Typedef('Bar', null);
      foo.type = new InterfaceType(test.otherClass, Nullability.legacy,
          [new TypedefType(bar, Nullability.legacy)]);
      bar.type = new InterfaceType(test.otherClass, Nullability.legacy,
          [new TypedefType(foo, Nullability.legacy)]);
      test.enclosingLibrary.addTypedef(foo);
      test.enclosingLibrary.addTypedef(bar);
      return foo;
    },
    (Node foo) => "The typedef '$foo' refers to itself",
  );
  positiveTest(
    'Valid long typedefs C20 = C19 = ... = C1 = C0 = dynamic',
    (TestHarness test) {
      var typedef_ = new Typedef('C0', const DynamicType());
      test.enclosingLibrary.addTypedef(typedef_);
      for (int i = 1; i < 20; ++i) {
        typedef_ =
            new Typedef('C$i', new TypedefType(typedef_, Nullability.legacy));
        test.enclosingLibrary.addTypedef(typedef_);
      }
    },
  );
  negative1Test(
    'Invalid long typedefs C20 = C19 = ... = C1 = C0 = C20',
    (TestHarness test) {
      Typedef firstTypedef = new Typedef('C0', null);
      Typedef typedef_ = firstTypedef;
      test.enclosingLibrary.addTypedef(typedef_);
      var first = typedef_;
      for (int i = 1; i < 20; ++i) {
        typedef_ =
            new Typedef('C$i', new TypedefType(typedef_, Nullability.legacy));
        test.enclosingLibrary.addTypedef(typedef_);
      }
      first.type = new TypedefType(typedef_, Nullability.legacy);
      return firstTypedef;
    },
    (Node node) => "The typedef '$node' refers to itself",
  );
  positiveTest(
    'Valid typedef Foo<T extends C> = C<T>',
    (TestHarness test) {
      var param = new TypeParameter('T', test.otherLegacyRawType);
      var foo = new Typedef(
          'Foo',
          new InterfaceType(test.otherClass, Nullability.legacy,
              [new TypeParameterType(param, Nullability.legacy)]),
          typeParameters: [param]);
      test.addNode(foo);
    },
  );
  positiveTest(
    'Valid typedef Foo<T extends C<T>> = C<T>',
    (TestHarness test) {
      var param = new TypeParameter('T', test.otherLegacyRawType);
      param.bound = new InterfaceType(test.otherClass, Nullability.legacy,
          [new TypeParameterType(param, Nullability.legacy)]);
      var foo = new Typedef(
          'Foo',
          new InterfaceType(test.otherClass, Nullability.legacy,
              [new TypeParameterType(param, Nullability.legacy)]),
          typeParameters: [param]);
      test.addNode(foo);
    },
  );
  positiveTest(
    'Valid typedef Foo<T> = dynamic, Bar<T extends Foo<T>> = C<T>',
    (TestHarness test) {
      var fooParam = test.makeTypeParameter('T');
      var foo =
          new Typedef('Foo', const DynamicType(), typeParameters: [fooParam]);
      var barParam = new TypeParameter('T', null);
      barParam.bound = new TypedefType(foo, Nullability.legacy,
          [new TypeParameterType(barParam, Nullability.legacy)]);
      var bar = new Typedef(
          'Bar',
          new InterfaceType(test.otherClass, Nullability.legacy,
              [new TypeParameterType(barParam, Nullability.legacy)]),
          typeParameters: [barParam]);
      test.enclosingLibrary.addTypedef(foo);
      test.enclosingLibrary.addTypedef(bar);
    },
  );
  negative1Test(
    'Invalid typedefs Foo<T extends Bar<T>>, Bar<T extends Foo<T>>',
    (TestHarness test) {
      var fooParam = test.makeTypeParameter('T');
      var foo =
          new Typedef('Foo', const DynamicType(), typeParameters: [fooParam]);
      var barParam = new TypeParameter('T', null);
      barParam.bound = new TypedefType(foo, Nullability.legacy,
          [new TypeParameterType(barParam, Nullability.legacy)]);
      var bar = new Typedef(
          'Bar',
          new InterfaceType(test.otherClass, Nullability.legacy,
              [new TypeParameterType(barParam, Nullability.legacy)]),
          typeParameters: [barParam]);
      fooParam.bound = new TypedefType(bar, Nullability.legacy,
          [new TypeParameterType(fooParam, Nullability.legacy)]);
      test.enclosingLibrary.addTypedef(foo);
      test.enclosingLibrary.addTypedef(bar);
      return foo;
    },
    (Node foo) => "The typedef '$foo' refers to itself",
  );
  negative1Test(
    'Invalid typedef Foo<T extends Foo<dynamic> = C<T>',
    (TestHarness test) {
      var param = new TypeParameter('T', null);
      var foo = new Typedef(
          'Foo',
          new InterfaceType(test.otherClass, Nullability.legacy,
              [new TypeParameterType(param, Nullability.legacy)]),
          typeParameters: [param]);
      param.bound =
          new TypedefType(foo, Nullability.legacy, [const DynamicType()]);
      test.addNode(foo);
      return foo;
    },
    (Node foo) => "The typedef '$foo' refers to itself",
  );
  negative1Test(
    'Typedef arity error',
    (TestHarness test) {
      var param = test.makeTypeParameter('T');
      var foo =
          new Typedef('Foo', test.otherLegacyRawType, typeParameters: [param]);
      var typedefType = new TypedefType(foo, Nullability.legacy, []);
      var field =
          new Field(new Name('field'), type: typedefType, isStatic: true);
      test.enclosingLibrary.addTypedef(foo);
      test.enclosingLibrary.addField(field);
      return typedefType;
    },
    (Node typedefType) =>
        "The typedef type $typedefType provides 0 type arguments,"
        " but the typedef declares 1 parameters.",
  );
  negative1Test(
    'Dangling typedef reference',
    (TestHarness test) {
      var foo = new Typedef('Foo', test.otherLegacyRawType, typeParameters: []);
      var field = new Field(new Name('field'),
          type: new TypedefType(foo, Nullability.legacy, []), isStatic: true);
      test.enclosingLibrary.addField(field);
      return foo;
    },
    (Node foo) => "Dangling reference to '$foo', parent is: 'null'",
  );
  negative1Test(
    'Non-static top-level field',
    (TestHarness test) {
      var field = new Field(new Name('field'));
      test.enclosingLibrary.addField(field);
      return null;
    },
    (Node node) => "The top-level field 'field' should be static",
  );
}

checkHasError(Component component, Matcher matcher) {
  try {
    verifyComponent(component);
  } on VerificationError catch (e) {
    expect(e.details, matcher);
    return;
  }
  fail('Failed to reject invalid component:\n${componentToString(component)}');
}

class TestHarness {
  Component component;
  Class objectClass;
  Library stubLibrary;

  TypeParameter classTypeParameter;

  Library enclosingLibrary;
  Class enclosingClass;
  Procedure enclosingMember;

  Class otherClass;

  InterfaceType objectLegacyRawType;
  InterfaceType enclosingLegacyRawType;
  InterfaceType otherLegacyRawType;

  void addNode(TreeNode node) {
    if (node is Expression) {
      addExpression(node);
    } else if (node is Statement) {
      addStatement(node);
    } else if (node is Member) {
      addClassMember(node);
    } else if (node is Class) {
      addClass(node);
    } else if (node is Typedef) {
      addTypedef(node);
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
    if (node is Procedure) {
      enclosingClass.addProcedure(node);
    } else if (node is Field) {
      enclosingClass.addField(node);
    } else if (node is Constructor) {
      enclosingClass.addConstructor(node);
    } else if (node is RedirectingFactoryConstructor) {
      enclosingClass.addRedirectingFactoryConstructor(node);
    } else {
      throw "Unexpected class member: ${node.runtimeType}";
    }
  }

  void addTopLevelMember(Member node) {
    if (node is Procedure) {
      enclosingLibrary.addProcedure(node);
    } else if (node is Field) {
      enclosingLibrary.addField(node);
    } else {
      throw "Unexpected top level member: ${node.runtimeType}";
    }
  }

  void addClass(Class node) {
    enclosingLibrary.addClass(node);
  }

  void addTypedef(Typedef node) {
    enclosingLibrary.addTypedef(node);
  }

  VariableDeclaration makeVariable() => new VariableDeclaration(null);

  TypeParameter makeTypeParameter([String name]) {
    return new TypeParameter(name, objectLegacyRawType, const DynamicType());
  }

  TestHarness() {
    setupComponent();
  }

  void setupComponent() {
    component = new Component();
    stubLibrary = new Library(Uri.parse('dart:core'));
    component.libraries.add(stubLibrary..parent = component);
    stubLibrary.name = 'dart.core';
    objectClass = new Class(name: 'Object');
    objectLegacyRawType =
        new InterfaceType(objectClass, Nullability.legacy, const <DartType>[]);
    stubLibrary.addClass(objectClass);
    enclosingLibrary = new Library(Uri.parse('file://test.dart'));
    component.libraries.add(enclosingLibrary..parent = component);
    enclosingLibrary.name = 'test_lib';
    classTypeParameter = makeTypeParameter('T');
    enclosingClass = new Class(
        name: 'TestClass',
        typeParameters: [classTypeParameter],
        supertype: objectClass.asRawSupertype);
    enclosingLegacyRawType = new InterfaceType(enclosingClass,
        Nullability.legacy, const <DartType>[const DynamicType()]);
    enclosingLibrary.addClass(enclosingClass);
    enclosingMember = new Procedure(new Name('test'), ProcedureKind.Method,
        new FunctionNode(new EmptyStatement()));
    enclosingClass.addProcedure(enclosingMember);
    otherClass = new Class(
        name: 'OtherClass',
        typeParameters: [makeTypeParameter('OtherT')],
        supertype: objectClass.asRawSupertype);
    otherLegacyRawType = new InterfaceType(
        otherClass, Nullability.legacy, const <DartType>[const DynamicType()]);
    enclosingLibrary.addClass(otherClass);
  }
}

negative1Test(String name, Node Function(TestHarness test) nodeProvider,
    dynamic Function(Node node) matcher) {
  TestHarness testHarness = new TestHarness();
  Node node = nodeProvider(testHarness);
  test(
    name,
    () {
      dynamic matcherResult = matcher(node);
      if (matcherResult is String) {
        matcherResult = equals(matcherResult);
      }
      checkHasError(testHarness.component, matcherResult);
    },
  );
}

negative2Test(String name, List<Node> Function(TestHarness test) nodeProvider,
    dynamic Function(Node node, Node other) matcher) {
  TestHarness testHarness = new TestHarness();
  List<Node> nodes = nodeProvider(testHarness);
  if (nodes.length != 2) throw "Needs exactly 2 nodes: Node and other!";
  test(
    name,
    () {
      dynamic matcherResult = matcher(nodes[0], nodes[1]);
      if (matcherResult is String) {
        matcherResult = equals(matcherResult);
      }
      checkHasError(testHarness.component, matcherResult);
    },
  );
}

simpleNegativeTest(String name, dynamic matcher,
    void Function(TestHarness test) makeTestCase) {
  TestHarness testHarness = new TestHarness();
  test(
    name,
    () {
      makeTestCase(testHarness);
      if (matcher is String) {
        matcher = equals(matcher);
      }
      checkHasError(testHarness.component, matcher);
    },
  );
}

positiveTest(String name, void makeTestCase(TestHarness test)) {
  test(
    name,
    () {
      var test = new TestHarness();
      makeTestCase(test);
      verifyComponent(test.component);
    },
  );
}
