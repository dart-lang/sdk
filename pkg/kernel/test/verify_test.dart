// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:kernel/ast.dart';
import 'package:kernel/target/targets.dart';
import 'package:kernel/text/ast_to_text.dart';
import 'package:kernel/verifier.dart';
import 'package:test/test.dart';

const int dummyFileOffset = 4312;

String errorPrefix =
    'Target=none, VerificationStage.afterModularTransformations: ';

/// Checks that the verifier correctly find errors in invalid components.
///
/// The frontend should never generate invalid components, so we have to test
/// these by manually constructing invalid ASTs.
///
/// We mostly test negative cases here, as we get plenty of positive cases by
/// compiling the Dart test suite with the verifier enabled.
void main() {
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
    (Node? node) => "${errorPrefix}Variable '$node' used out of scope.",
  );
  negative1Test(
    'VariableSet out of scope',
    (TestHarness test) {
      VariableDeclaration variable = test.makeVariable();
      test.addNode(VariableSet(variable, new NullLiteral()));
      return variable;
    },
    (Node? node) => "${errorPrefix}Variable '$node' used out of scope.",
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
    (Node? node) => "${errorPrefix}Variable '$node' used out of scope.",
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
    (Node? node) => "${errorPrefix}Variable '$node' used out of scope.",
  );
  negative1Test(
    'Variable redeclared',
    (TestHarness test) {
      VariableDeclaration variable = test.makeVariable();
      test.addNode(Block([variable, variable]));
      return variable;
    },
    (Node? node) => "${errorPrefix}Variable '$node' declared more than once.",
  );
  negative1Test(
    'Member redeclared',
    (TestHarness test) {
      Field field = new Field.mutable(new Name('field'),
          initializer: new NullLiteral(), fileUri: dummyUri);
      test.addNode(Class(
          name: 'Test',
          supertype: test.objectClass.asRawSupertype,
          fields: [field, field],
          fileUri: dummyUri)
        ..fileOffset = dummyFileOffset);
      return field;
    },
    (Node? node) =>
        "${errorPrefix}Member '$node' has been declared more than once.",
  );
  negative1Test(
    'Class redeclared',
    (TestHarness test) {
      Class otherClass = test.otherClass;
      test.addNode(
          otherClass); // Test harness also adds otherClass to component.
      return test.otherClass;
    },
    (Node? node) => "${errorPrefix}Class '$node' declared more than once.",
  );
  negative1Test(
    'Class type parameter redeclared',
    (TestHarness test) {
      TypeParameter parameter = test.makeTypeParameter();
      test.addNode(Class(
          name: 'Test',
          supertype: test.objectClass.asRawSupertype,
          typeParameters: [parameter, parameter],
          fileUri: dummyUri)
        ..fileOffset = dummyFileOffset);
      return parameter;
    },
    (Node? node) => "${errorPrefix}Type parameter '$node' redeclared.",
  );
  negative1Test(
    'Member type parameter redeclared',
    (TestHarness test) {
      TypeParameter parameter = test.makeTypeParameter();
      test.addNode(Procedure(
          new Name('bar'),
          ProcedureKind.Method,
          new FunctionNode(new ReturnStatement(new NullLiteral()),
              typeParameters: [parameter, parameter]),
          fileUri: dummyUri)
        ..fileOffset = dummyFileOffset);

      return parameter;
    },
    (Node? node) => "${errorPrefix}Type parameter '$node' redeclared.",
  );
  negative2Test(
    'Type parameter out of scope',
    (TestHarness test) {
      TypeParameter parameter = test.makeTypeParameter();
      test.addNode(ListLiteral([],
          typeArgument: new TypeParameterType(parameter, Nullability.legacy)));
      return [parameter, null];
    },
    (Node? node, Node? parent) =>
        "${errorPrefix}Type parameter '$node' referenced out of scope,"
        " owner is: '$parent'.",
  );
  negative2Test(
    'Class type parameter from another class',
    (TestHarness test) {
      TypeParameter node = test.otherClass.typeParameters[0];
      test.addNode(
          TypeLiteral(new TypeParameterType(node, Nullability.legacy)));
      return [node, test.otherClass];
    },
    (Node? node, Node? parent) =>
        "${errorPrefix}Type parameter '$node' referenced out of scope,"
        " owner is: '$parent'.",
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
          isStatic: true,
          fileUri: dummyUri)
        ..fileOffset = dummyFileOffset);

      return [node, test.enclosingClass];
    },
    (Node? node, Node? parent) =>
        "${errorPrefix}Type parameter '$node' referenced from static context,"
        " parent is: '$parent'.",
  );
  negative2Test(
    'Class type parameter in static field',
    (TestHarness test) {
      TypeParameter node = test.classTypeParameter;
      test.addNode(Field.mutable(new Name('field'),
          initializer:
              new TypeLiteral(new TypeParameterType(node, Nullability.legacy)),
          isStatic: true,
          fileUri: dummyUri)
        ..fileOffset = dummyFileOffset);
      return [node, test.enclosingClass];
    },
    (Node? node, Node? parent) =>
        "${errorPrefix}Type parameter '$node' referenced from static context,"
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
            new Procedure(new Name('generic'), ProcedureKind.Method, parent,
                fileUri: dummyUri)
              ..fileOffset = dummyFileOffset,
            new Procedure(
                new Name('use'),
                ProcedureKind.Method,
                new FunctionNode(new ReturnStatement(new TypeLiteral(
                    new TypeParameterType(parameter, Nullability.legacy)))),
                fileUri: dummyUri)
              ..fileOffset = dummyFileOffset
          ],
          fileUri: dummyUri)
        ..fileOffset = dummyFileOffset);

      return [parameter, parent];
    },
    (Node? node, Node? parent) =>
        "${errorPrefix}Type parameter '$node' referenced out of scope,"
        " owner is: '${(parent as TreeNode).parent}'.",
  );
  negative1Test(
    'Interface type arity too low',
    (TestHarness test) {
      InterfaceType node =
          new InterfaceType(test.otherClass, Nullability.legacy, []);
      test.addNode(TypeLiteral(node));
      return node;
    },
    (Node? node) => "${errorPrefix}Type $node provides 0 type arguments,"
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
    (Node? node) => "${errorPrefix}Type $node provides 2 type arguments,"
        " but the class declares 1 parameters.",
  );
  negative1Test(
    'Dangling interface type',
    (TestHarness test) {
      Class orphan = new Class(name: 'Class', fileUri: dummyUri)
        ..fileOffset = dummyFileOffset;
      test.addNode(
          new TypeLiteral(new InterfaceType(orphan, Nullability.legacy)));
      return orphan;
    },
    (Node? node) =>
        "${errorPrefix}Dangling reference to '$node', parent is: 'null'.",
  );
  negative1Test(
    'Dangling field get',
    (TestHarness test) {
      Field orphan = new Field.mutable(new Name('foo'), fileUri: dummyUri)
        ..fileOffset = dummyFileOffset;
      test.addNode(new InstanceGet(
          InstanceAccessKind.Instance, new NullLiteral(), orphan.name,
          interfaceTarget: orphan, resultType: orphan.getterType));
      return orphan;
    },
    (Node? node) =>
        "${errorPrefix}Dangling reference to '$node', parent is: 'null'.",
  );
  simpleNegativeTest(
    'Missing block parent pointer',
    "${errorPrefix}Incorrect parent pointer on ReturnStatement(return;):"
        """ expected Block({
  return;
}), but found: null.""",
    (TestHarness test) {
      var block = new Block([]);
      block.statements.add(new ReturnStatement());
      test.addNode(block);
    },
  );
  simpleNegativeTest(
    'Missing function parent pointer',
    "${errorPrefix}Incorrect parent pointer on FunctionNode():"
        " expected TestClass.bar, but found: null.",
    (TestHarness test) {
      var procedure = new Procedure(
          new Name('bar'), ProcedureKind.Method, dummyFunctionNode,
          fileUri: dummyUri)
        ..fileOffset = dummyFileOffset;
      procedure.function = new FunctionNode(new EmptyStatement());
      test.addNode(procedure);
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
          isStatic: true,
          fileUri: dummyUri)
        ..fileOffset = dummyFileOffset;
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
          isStatic: true, fileUri: dummyUri)
        ..fileOffset = dummyFileOffset;
      test.enclosingClass.addProcedure(method);
      test.addNode(
          StaticInvocation(method, new Arguments([new NullLiteral()])));
      return method;
    },
    (Node? node) =>
        "${errorPrefix}StaticInvocation with incompatible arguments for"
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
          isStatic: true,
          fileUri: dummyUri)
        ..fileOffset = dummyFileOffset;
      test.enclosingClass.addProcedure(method);
      test.addNode(StaticInvocation(method, new Arguments.empty()));
      return method;
    },
    (Node? node) =>
        "${errorPrefix}StaticInvocation with incompatible arguments for "
        "'$node'.",
  );
  negative1Test(
    'StaticInvocation with unmatched named parameter',
    (TestHarness test) {
      var method = new Procedure(new Name('bar'), ProcedureKind.Method,
          new FunctionNode(new EmptyStatement()),
          isStatic: true, fileUri: dummyUri)
        ..fileOffset = dummyFileOffset;
      test.enclosingClass.addProcedure(method);
      test.addNode(StaticInvocation(
          method,
          new Arguments([],
              named: [new NamedExpression('p', new NullLiteral())])));
      return method;
    },
    (Node? node) =>
        "${errorPrefix}StaticInvocation with incompatible arguments for"
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
          isStatic: true,
          fileUri: dummyUri)
        ..fileOffset = dummyFileOffset;
      test.enclosingClass.addProcedure(method);
      test.addNode(StaticInvocation(method, new Arguments.empty()));
      return method;
    },
    (Node? node) =>
        "${errorPrefix}StaticInvocation with wrong number of type arguments for"
        " '$node'.",
  );
  negative1Test(
    'ConstructorInvocation with missing type argument',
    (TestHarness test) {
      var constructor = new Constructor(new FunctionNode(new EmptyStatement()),
          name: new Name('foo'), fileUri: dummyUri)
        ..fileOffset = dummyFileOffset;
      test.enclosingClass.addConstructor(constructor);
      test.addNode(ConstructorInvocation(constructor, new Arguments.empty()));
      return constructor;
    },
    (Node? node) =>
        "${errorPrefix}ConstructorInvocation with wrong number of type "
        "arguments for '$node'.",
  );
  positiveTest(
    'Valid typedef Foo = `(C) => void`',
    (TestHarness test) {
      var typedef_ = new Typedef(
          'Foo',
          new FunctionType(
              [test.otherLegacyRawType], const VoidType(), Nullability.legacy),
          fileUri: dummyUri)
        ..fileOffset = dummyFileOffset;
      test.addNode(typedef_);
    },
  );
  positiveTest(
    'Valid typedef Foo = C<dynamic>',
    (TestHarness test) {
      var typedef_ = new Typedef(
          'Foo',
          new InterfaceType(
              test.otherClass, Nullability.legacy, [const DynamicType()]),
          fileUri: dummyUri)
        ..fileOffset = dummyFileOffset;
      test.addNode(typedef_);
    },
  );
  positiveTest(
    'Valid typedefs Foo = Bar, Bar = C',
    (TestHarness test) {
      var foo = new Typedef('Foo', null, fileUri: dummyUri)
        ..fileOffset = dummyFileOffset;
      var bar = new Typedef('Bar', null, fileUri: dummyUri)
        ..fileOffset = dummyFileOffset;
      foo.type = new TypedefType(bar, Nullability.legacy);
      bar.type = test.otherLegacyRawType;
      test.enclosingLibrary.addTypedef(foo);
      test.enclosingLibrary.addTypedef(bar);
    },
  );
  positiveTest(
    'Valid typedefs Foo = C<Bar>, Bar = C',
    (TestHarness test) {
      var foo = new Typedef('Foo', null, fileUri: dummyUri)
        ..fileOffset = dummyFileOffset;
      var bar = new Typedef('Bar', null, fileUri: dummyUri)
        ..fileOffset = dummyFileOffset;
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
              [test.otherLegacyRawType], const VoidType(), Nullability.legacy),
          fileUri: dummyUri)
        ..fileOffset = dummyFileOffset;
      var field = new Field.mutable(new Name('field'),
          type: new TypedefType(typedef_, Nullability.legacy),
          isStatic: true,
          fileUri: dummyUri)
        ..fileOffset = dummyFileOffset;
      test.enclosingLibrary.addTypedef(typedef_);
      test.enclosingLibrary.addField(field);
    },
  );
  negative1Test(
    'Invalid typedef Foo = Foo',
    (TestHarness test) {
      var typedef_ = new Typedef('Foo', null, fileUri: dummyUri)
        ..fileOffset = dummyFileOffset;
      typedef_.type = new TypedefType(typedef_, Nullability.legacy);
      test.addNode(typedef_);
      return typedef_;
    },
    (Node? node) => "${errorPrefix}The typedef '$node' refers to itself",
  );
  negative1Test(
    'Invalid typedef Foo = `(Foo) => void`',
    (TestHarness test) {
      var typedef_ = new Typedef('Foo', null, fileUri: dummyUri)
        ..fileOffset = dummyFileOffset;
      typedef_.type = new FunctionType(
          [new TypedefType(typedef_, Nullability.legacy)],
          const VoidType(),
          Nullability.legacy);
      test.addNode(typedef_);
      return typedef_;
    },
    (Node? node) => "${errorPrefix}The typedef '$node' refers to itself",
  );
  negative1Test(
    'Invalid typedef Foo = `() => Foo`',
    (TestHarness test) {
      var typedef_ = new Typedef('Foo', null, fileUri: dummyUri)
        ..fileOffset = dummyFileOffset;
      typedef_.type = new FunctionType([],
          new TypedefType(typedef_, Nullability.legacy), Nullability.legacy);
      test.addNode(typedef_);
      return typedef_;
    },
    (Node? node) => "${errorPrefix}The typedef '$node' refers to itself",
  );
  negative1Test(
    'Invalid typedef Foo = C<Foo>',
    (TestHarness test) {
      var typedef_ = new Typedef('Foo', null, fileUri: dummyUri)
        ..fileOffset = dummyFileOffset;
      typedef_.type = new InterfaceType(test.otherClass, Nullability.legacy,
          [new TypedefType(typedef_, Nullability.legacy)]);
      test.addNode(typedef_);
      return typedef_;
    },
    (Node? node) => "${errorPrefix}The typedef '$node' refers to itself",
  );
  negative1Test(
    'Invalid typedefs Foo = Bar, Bar = Foo',
    (TestHarness test) {
      var foo = new Typedef('Foo', null, fileUri: dummyUri)
        ..fileOffset = dummyFileOffset;
      var bar = new Typedef('Bar', null, fileUri: dummyUri)
        ..fileOffset = dummyFileOffset;
      foo.type = new TypedefType(bar, Nullability.legacy);
      bar.type = new TypedefType(foo, Nullability.legacy);
      test.enclosingLibrary.addTypedef(foo);
      test.enclosingLibrary.addTypedef(bar);
      return foo;
    },
    (Node? foo) => "${errorPrefix}The typedef '$foo' refers to itself",
  );
  negative1Test(
    'Invalid typedefs Foo = Bar, Bar = C<Foo>',
    (TestHarness test) {
      var foo = new Typedef('Foo', null, fileUri: dummyUri)
        ..fileOffset = dummyFileOffset;
      var bar = new Typedef('Bar', null, fileUri: dummyUri)
        ..fileOffset = dummyFileOffset;
      foo.type = new TypedefType(bar, Nullability.legacy);
      bar.type = new InterfaceType(test.otherClass, Nullability.legacy,
          [new TypedefType(foo, Nullability.legacy)]);
      test.enclosingLibrary.addTypedef(foo);
      test.enclosingLibrary.addTypedef(bar);
      return foo;
    },
    (Node? foo) => "${errorPrefix}The typedef '$foo' refers to itself",
  );
  negative1Test(
    'Invalid typedefs Foo = C<Bar>, Bar = C<Foo>',
    (TestHarness test) {
      var foo = new Typedef('Foo', null, fileUri: dummyUri)
        ..fileOffset = dummyFileOffset;
      var bar = new Typedef('Bar', null, fileUri: dummyUri)
        ..fileOffset = dummyFileOffset;
      foo.type = new InterfaceType(test.otherClass, Nullability.legacy,
          [new TypedefType(bar, Nullability.legacy)]);
      bar.type = new InterfaceType(test.otherClass, Nullability.legacy,
          [new TypedefType(foo, Nullability.legacy)]);
      test.enclosingLibrary.addTypedef(foo);
      test.enclosingLibrary.addTypedef(bar);
      return foo;
    },
    (Node? foo) => "${errorPrefix}The typedef '$foo' refers to itself",
  );
  positiveTest(
    'Valid long typedefs C20 = C19 = ... = C1 = C0 = dynamic',
    (TestHarness test) {
      var typedef_ = new Typedef('C0', const DynamicType(), fileUri: dummyUri)
        ..fileOffset = dummyFileOffset;
      test.enclosingLibrary.addTypedef(typedef_);
      for (int i = 1; i < 20; ++i) {
        typedef_ = new Typedef(
            'C$i', new TypedefType(typedef_, Nullability.legacy),
            fileUri: dummyUri)
          ..fileOffset = dummyFileOffset;
        test.enclosingLibrary.addTypedef(typedef_);
      }
    },
  );
  negative1Test(
    'Invalid long typedefs C20 = C19 = ... = C1 = C0 = C20',
    (TestHarness test) {
      Typedef firstTypedef = new Typedef('C0', null, fileUri: dummyUri)
        ..fileOffset = dummyFileOffset;
      Typedef typedef_ = firstTypedef;
      test.enclosingLibrary.addTypedef(typedef_);
      var first = typedef_;
      for (int i = 1; i < 20; ++i) {
        typedef_ = new Typedef(
            'C$i', new TypedefType(typedef_, Nullability.legacy),
            fileUri: dummyUri)
          ..fileOffset = dummyFileOffset;
        test.enclosingLibrary.addTypedef(typedef_);
      }
      first.type = new TypedefType(typedef_, Nullability.legacy);
      return firstTypedef;
    },
    (Node? node) => "${errorPrefix}The typedef '$node' refers to itself",
  );
  positiveTest(
    'Valid typedef Foo<T extends C> = C<T>',
    (TestHarness test) {
      var param = new TypeParameter(
          'T', test.otherLegacyRawType, test.otherLegacyRawType);
      var foo = new Typedef(
          'Foo',
          new InterfaceType(test.otherClass, Nullability.legacy,
              [new TypeParameterType(param, Nullability.legacy)]),
          typeParameters: [param],
          fileUri: dummyUri)
        ..fileOffset = dummyFileOffset;
      test.addNode(foo);
    },
  );
  positiveTest(
    'Valid typedef Foo<T extends C<T>> = C<T>',
    (TestHarness test) {
      var param = new TypeParameter(
          'T', test.otherLegacyRawType, test.otherLegacyRawType);
      param.bound = new InterfaceType(test.otherClass, Nullability.legacy,
          [new TypeParameterType(param, Nullability.legacy)]);
      var foo = new Typedef(
          'Foo',
          new InterfaceType(test.otherClass, Nullability.legacy,
              [new TypeParameterType(param, Nullability.legacy)]),
          typeParameters: [param],
          fileUri: dummyUri)
        ..fileOffset = dummyFileOffset;
      test.addNode(foo);
    },
  );
  positiveTest(
    'Valid typedef Foo<T> = dynamic, Bar<T extends Foo<T>> = C<T>',
    (TestHarness test) {
      var fooParam = test.makeTypeParameter('T');
      var foo = new Typedef('Foo', const DynamicType(),
          typeParameters: [fooParam], fileUri: dummyUri)
        ..fileOffset = dummyFileOffset;
      var barParam = new TypeParameter('T', null);
      barParam.bound = new TypedefType(foo, Nullability.legacy,
          [new TypeParameterType(barParam, Nullability.legacy)]);
      barParam.defaultType = const DynamicType();
      var bar = new Typedef(
          'Bar',
          new InterfaceType(test.otherClass, Nullability.legacy,
              [new TypeParameterType(barParam, Nullability.legacy)]),
          typeParameters: [barParam],
          fileUri: dummyUri)
        ..fileOffset = dummyFileOffset;
      test.enclosingLibrary.addTypedef(foo);
      test.enclosingLibrary.addTypedef(bar);
    },
  );
  negative1Test(
    'Invalid typedefs Foo<T extends Bar<T>>, Bar<T extends Foo<T>>',
    (TestHarness test) {
      var fooParam = test.makeTypeParameter('T');
      var foo = new Typedef('Foo', const DynamicType(),
          typeParameters: [fooParam], fileUri: dummyUri)
        ..fileOffset = dummyFileOffset;
      var barParam = new TypeParameter('T', null);
      barParam.bound = new TypedefType(foo, Nullability.legacy,
          [new TypeParameterType(barParam, Nullability.legacy)]);
      barParam.defaultType = const DynamicType();
      var bar = new Typedef(
          'Bar',
          new InterfaceType(test.otherClass, Nullability.legacy,
              [new TypeParameterType(barParam, Nullability.legacy)]),
          typeParameters: [barParam],
          fileUri: dummyUri);
      fooParam.bound = new TypedefType(bar, Nullability.legacy,
          [new TypeParameterType(fooParam, Nullability.legacy)]);
      fooParam.defaultType = const DynamicType();
      test.enclosingLibrary.addTypedef(foo);
      test.enclosingLibrary.addTypedef(bar);
      return foo;
    },
    (Node? foo) => "${errorPrefix}The typedef '$foo' refers to itself",
  );
  negative1Test(
    'Invalid typedef Foo<T extends Foo<dynamic> = C<T>',
    (TestHarness test) {
      var param = new TypeParameter('T', null);
      var foo = new Typedef(
          'Foo',
          new InterfaceType(test.otherClass, Nullability.legacy,
              [new TypeParameterType(param, Nullability.legacy)]),
          typeParameters: [param],
          fileUri: dummyUri)
        ..fileOffset = dummyFileOffset;
      param.bound =
          new TypedefType(foo, Nullability.legacy, [const DynamicType()]);
      param.defaultType = const DynamicType();
      test.addNode(foo);
      return foo;
    },
    (Node? foo) => "${errorPrefix}The typedef '$foo' refers to itself",
  );
  negative1Test(
    'Typedef arity error',
    (TestHarness test) {
      var param = test.makeTypeParameter('T');
      var foo = new Typedef('Foo', test.otherLegacyRawType,
          typeParameters: [param], fileUri: dummyUri)
        ..fileOffset = dummyFileOffset;
      var typedefType = new TypedefType(foo, Nullability.legacy, []);
      var field = new Field.mutable(new Name('field'),
          type: typedefType, isStatic: true, fileUri: dummyUri)
        ..fileOffset = dummyFileOffset;
      test.enclosingLibrary.addTypedef(foo);
      test.enclosingLibrary.addField(field);
      return typedefType;
    },
    (Node? typedefType) =>
        "${errorPrefix}The typedef type $typedefType provides 0 type arguments,"
        " but the typedef declares 1 parameters.",
  );
  negative1Test(
    'Dangling typedef reference',
    (TestHarness test) {
      var foo = new Typedef('Foo', test.otherLegacyRawType,
          typeParameters: [], fileUri: dummyUri)
        ..fileOffset = dummyFileOffset;
      var field = new Field.mutable(new Name('field'),
          type: new TypedefType(foo, Nullability.legacy, []),
          isStatic: true,
          fileUri: dummyUri)
        ..fileOffset = dummyFileOffset;
      test.enclosingLibrary.addField(field);
      return foo;
    },
    (Node? foo) =>
        "${errorPrefix}Dangling reference to '$foo', parent is: 'null'",
  );
  negative1Test(
    'Unset bound typedef Foo<T> = dynamic',
    (TestHarness test) {
      var param = new TypeParameter('T', null);
      var foo = new Typedef('Foo', const DynamicType(),
          typeParameters: [param], fileUri: dummyUri)
        ..fileOffset = dummyFileOffset;
      param.defaultType = const DynamicType();
      test.addNode(foo);
      return foo;
    },
    (Node? foo) => "${errorPrefix}"
        "Unset bound on type parameter TypeParameter(T)",
  );
  negative1Test(
    'Unset default type typedef Foo<T> = dynamic',
    (TestHarness test) {
      var param = new TypeParameter('T', null);
      var foo = new Typedef('Foo', const DynamicType(),
          typeParameters: [param], fileUri: dummyUri)
        ..fileOffset = dummyFileOffset;
      param.bound = const DynamicType();
      test.addNode(foo);
      return foo;
    },
    (Node? foo) => "${errorPrefix}"
        "Unset default type on type parameter TypeParameter(T)",
  );
  negative1Test(
    'Non-static top-level field',
    (TestHarness test) {
      var field = new Field.mutable(new Name('field'), fileUri: dummyUri)
        ..fileOffset = dummyFileOffset;
      test.enclosingLibrary.addField(field);
      return null;
    },
    (Node? node) =>
        "${errorPrefix}The top-level field 'field' should be static",
  );
  positiveTest('No library file offset', (TestHarness test) {
    var library = new Library(dummyUri, fileUri: dummyUri)
      ..parent = test.component;
    test.component.libraries.add(library);
    return null;
  });
  negative1Test(
    'Class file offset',
    (TestHarness test) {
      var cls = new Class(name: 'Class', fileUri: dummyUri);
      test.enclosingLibrary.addClass(cls);
      return null;
    },
    (Node? node) => "${errorPrefix}'Class' has no fileOffset",
  );
  negative1Test(
    'Extension file offset',
    (TestHarness test) {
      var extension = new Extension(name: 'Extension', fileUri: dummyUri);
      test.enclosingLibrary.addExtension(extension);
      return null;
    },
    (Node? node) => "${errorPrefix}'Extension' has no fileOffset",
  );
  negative1Test(
    'Procedure file offset',
    (TestHarness test) {
      var method = new Procedure(
          new Name('method'), ProcedureKind.Method, new FunctionNode(null),
          fileUri: dummyUri);
      test.enclosingClass.addProcedure(method);
      return null;
    },
    (Node? node) => "${errorPrefix}'method' has no fileOffset",
  );
  negative1Test(
    'Field file offset',
    (TestHarness test) {
      var field = new Field.mutable(new Name('field'), fileUri: dummyUri);
      test.enclosingClass.addField(field);
      return null;
    },
    (Node? node) => "${errorPrefix}'field' has no fileOffset",
  );
}

void checkHasError(Target target, Component component, Matcher matcher) {
  try {
    verifyComponent(
        target, VerificationStage.afterModularTransformations, component);
  } on VerificationError catch (e) {
    expect(e.details, matcher);
    return;
  }
  fail('Failed to reject invalid component:\n${componentToString(component)}');
}

class TestHarness {
  late Target target;
  late Component component;
  late Class objectClass;
  late Library stubLibrary;

  late TypeParameter classTypeParameter;

  late Library enclosingLibrary;
  late Class enclosingClass;
  late Procedure enclosingMember;

  late Class otherClass;

  late InterfaceType objectLegacyRawType;
  late InterfaceType enclosingLegacyRawType;
  late InterfaceType otherLegacyRawType;

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

  VariableDeclaration makeVariable() =>
      new VariableDeclaration(null, isSynthesized: true);

  TypeParameter makeTypeParameter([String? name]) {
    return new TypeParameter(name, objectLegacyRawType, const DynamicType());
  }

  TestHarness() {
    setupComponent();
  }

  void setupComponent() {
    target = new NoneTarget(new TargetFlags());
    component = new Component();
    Uri dartCoreUri = Uri.parse('dart:core');
    stubLibrary = new Library(dartCoreUri, fileUri: dartCoreUri);
    component.libraries.add(stubLibrary..parent = component);
    stubLibrary.name = 'dart.core';
    objectClass = new Class(name: 'Object', fileUri: dartCoreUri)
      ..fileOffset = dummyFileOffset;
    objectLegacyRawType =
        new InterfaceType(objectClass, Nullability.legacy, const <DartType>[]);
    stubLibrary.addClass(objectClass);
    Uri testUri = Uri.parse('file://test.dart');
    enclosingLibrary = new Library(testUri, fileUri: testUri);
    component.libraries.add(enclosingLibrary..parent = component);
    enclosingLibrary.name = 'test_lib';
    classTypeParameter = makeTypeParameter('T');
    enclosingClass = new Class(
        name: 'TestClass',
        typeParameters: [classTypeParameter],
        supertype: objectClass.asRawSupertype,
        fileUri: testUri)
      ..fileOffset = dummyFileOffset;
    enclosingLegacyRawType = new InterfaceType(enclosingClass,
        Nullability.legacy, const <DartType>[const DynamicType()]);
    enclosingLibrary.addClass(enclosingClass);
    enclosingMember = new Procedure(new Name('test'), ProcedureKind.Method,
        new FunctionNode(new EmptyStatement()),
        fileUri: dummyUri)
      ..fileOffset = dummyFileOffset;
    enclosingClass.addProcedure(enclosingMember);
    otherClass = new Class(
        name: 'OtherClass',
        typeParameters: [makeTypeParameter('OtherT')],
        supertype: objectClass.asRawSupertype,
        fileUri: testUri)
      ..fileOffset = dummyFileOffset;
    otherLegacyRawType = new InterfaceType(
        otherClass, Nullability.legacy, const <DartType>[const DynamicType()]);
    enclosingLibrary.addClass(otherClass);
  }
}

void negative1Test(String name, Node? Function(TestHarness test) nodeProvider,
    dynamic Function(Node? node) matcher) {
  TestHarness testHarness = new TestHarness();
  Node? node = nodeProvider(testHarness);
  test(
    name,
    () {
      dynamic matcherResult = matcher(node);
      if (matcherResult is String) {
        matcherResult = equals(matcherResult);
      }
      checkHasError(testHarness.target, testHarness.component, matcherResult);
    },
  );
}

void negative2Test(
    String name,
    List<Node?> Function(TestHarness test) nodeProvider,
    dynamic Function(Node? node, Node? other) matcher) {
  TestHarness testHarness = new TestHarness();
  List<Node?> nodes = nodeProvider(testHarness);
  if (nodes.length != 2) throw "Needs exactly 2 nodes: Node and other!";
  test(
    name,
    () {
      dynamic matcherResult = matcher(nodes[0], nodes[1]);
      if (matcherResult is String) {
        matcherResult = equals(matcherResult);
      }
      checkHasError(testHarness.target, testHarness.component, matcherResult);
    },
  );
}

void simpleNegativeTest(String name, dynamic matcher,
    void Function(TestHarness test) makeTestCase) {
  TestHarness testHarness = new TestHarness();
  test(
    name,
    () {
      makeTestCase(testHarness);
      if (matcher is String) {
        matcher = equals(matcher);
      }
      checkHasError(testHarness.target, testHarness.component, matcher);
    },
  );
}

void positiveTest(String name, void makeTestCase(TestHarness test)) {
  test(
    name,
    () {
      var test = new TestHarness();
      makeTestCase(test);
      verifyComponent(test.target,
          VerificationStage.afterModularTransformations, test.component);
    },
  );
}
