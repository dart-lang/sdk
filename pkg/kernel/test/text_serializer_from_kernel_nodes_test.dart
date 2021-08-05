// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library kernel.text_serializer_from_kernel_nodes_test;

import 'package:kernel/ast.dart';
import 'package:kernel/text/serializer_combinators.dart';
import 'package:kernel/text/text_reader.dart';
import 'package:kernel/text/text_serializer.dart';

void main() {
  initializeSerializers();
  test();
}

class TestCase<T extends Node> {
  final String name;
  final T node;
  final SerializationState Function() makeSerializationState;
  final DeserializationState Function() makeDeserializationState;
  final String expectation;
  final TextSerializer<T> serializer;

  TestCase(
      {required this.name,
      required this.node,
      required this.expectation,
      required this.serializer,
      SerializationState Function()? makeSerializationState,
      DeserializationState Function()? makeDeserializationState})
      // ignore: unnecessary_null_comparison
      : assert(node != null),
        // ignore: unnecessary_null_comparison
        assert(expectation != null),
        // ignore: unnecessary_null_comparison
        assert(serializer != null),
        this.makeSerializationState = makeSerializationState ??
            (() => new SerializationState(new SerializationEnvironment(null))),
        this.makeDeserializationState = makeDeserializationState ??
            (() => new DeserializationState(
                new DeserializationEnvironment(null),
                new CanonicalName.root()));

  T readNode(String input, DeserializationState state) {
    TextIterator stream = new TextIterator(input, 0);
    stream.moveNext();
    T result = serializer.readFrom(stream, state);
    if (stream.moveNext()) {
      throw new StateError("Found extra tokens at the end.");
    }
    return result;
  }

  String writeNode(T node, SerializationState state) {
    StringBuffer buffer = new StringBuffer();
    serializer.writeTo(buffer, node, state);
    return buffer.toString();
  }
}

void test() {
  List<String> failures = [];
  List<TestCase> tests = <TestCase>[
    new TestCase<Statement>(
        name: 'let dynamic x = 42 in x;',
        node: () {
          VariableDeclaration x = new VariableDeclaration('x',
              type: const DynamicType(), initializer: new IntLiteral(42));
          return new ExpressionStatement(new Let(x, new VariableGet(x)));
        }(),
        expectation: ''
            '(expr (let "x^0" () (dynamic) (int 42) ()'
            ' (get-var "x^0" _)))',
        serializer: statementSerializer),
    new TestCase<Statement>(
        name: 'let dynamic x = 42 in let Null x^0 = null in x;',
        node: () {
          VariableDeclaration outerLetVar = new VariableDeclaration('x',
              type: const DynamicType(), initializer: new IntLiteral(42));
          VariableDeclaration innerLetVar = new VariableDeclaration('x',
              type: const NullType(), initializer: new NullLiteral());
          return new ExpressionStatement(new Let(
              outerLetVar, new Let(innerLetVar, new VariableGet(outerLetVar))));
        }(),
        expectation: ''
            '(expr (let "x^0" () (dynamic) (int 42) ()'
            ' (let "x^1" () (null-type) (null) ()'
            ' (get-var "x^0" _))))',
        serializer: statementSerializer),
    new TestCase<Statement>(
        name: 'let dynamic x = 42 in let Null x^0 = null in x^0;',
        node: () {
          VariableDeclaration outerLetVar = new VariableDeclaration('x',
              type: const DynamicType(), initializer: new IntLiteral(42));
          VariableDeclaration innerLetVar = new VariableDeclaration('x',
              type: const NullType(), initializer: new NullLiteral());
          return new ExpressionStatement(new Let(
              outerLetVar, new Let(innerLetVar, new VariableGet(innerLetVar))));
        }(),
        expectation: ''
            '(expr (let "x^0" () (dynamic) (int 42) ()'
            ' (let "x^1" () (null-type) (null) ()'
            ' (get-var "x^1" _))))',
        serializer: statementSerializer),
    () {
      VariableDeclaration x =
          new VariableDeclaration('x', type: const DynamicType());
      return new TestCase<Statement>(
          name: '/* suppose: dynamic x; */ x = 42;',
          node: new ExpressionStatement(new VariableSet(x, new IntLiteral(42))),
          expectation: '(expr (set-var "x^0" (int 42)))',
          makeSerializationState: () => new SerializationState(
                new SerializationEnvironment(null)
                  ..addBinder(x, nameClue: x.name)
                  ..extend(),
              ),
          makeDeserializationState: () => new DeserializationState(
              new DeserializationEnvironment(null)
                ..addBinder(x, "x^0")
                ..extend(),
              new CanonicalName.root()),
          serializer: statementSerializer);
    }(),
    () {
      Uri uri = new Uri(scheme: 'package', path: 'foo/bar.dart');
      Field field = new Field.immutable(new Name('field'),
          type: const DynamicType(), fileUri: uri);
      Library library = new Library(uri, fileUri: uri, fields: <Field>[field]);
      Component component = new Component(libraries: <Library>[library]);
      component.computeCanonicalNames();
      return new TestCase<Statement>(
          name: '/* suppose top-level: dynamic field; */ field;',
          node: new ExpressionStatement(new StaticGet(field)),
          expectation: ''
              '(expr (get-static "package:foo/bar.dart::@getters::field"))',
          makeSerializationState: () =>
              new SerializationState(new SerializationEnvironment(null)),
          makeDeserializationState: () => new DeserializationState(
              new DeserializationEnvironment(null), component.root),
          serializer: statementSerializer);
    }(),
    () {
      Uri uri = new Uri(scheme: 'package', path: 'foo/bar.dart');
      Field field = new Field.mutable(new Name('field'),
          type: const DynamicType(), fileUri: uri);
      Library library = new Library(uri, fileUri: uri, fields: <Field>[field]);
      Component component = new Component(libraries: <Library>[library]);
      component.computeCanonicalNames();
      return new TestCase<Statement>(
          name: '/* suppose top-level: dynamic field; */ field;',
          node: new ExpressionStatement(new StaticGet(field)),
          expectation: ''
              '(expr (get-static "package:foo/bar.dart::@getters::field"))',
          makeSerializationState: () =>
              new SerializationState(new SerializationEnvironment(null)),
          makeDeserializationState: () => new DeserializationState(
              new DeserializationEnvironment(null), component.root),
          serializer: statementSerializer);
    }(),
    () {
      Uri uri = new Uri(scheme: 'package', path: 'foo/bar.dart');
      Field field = new Field.mutable(new Name('field'),
          type: const DynamicType(), fileUri: uri);
      Library library = new Library(uri, fileUri: uri, fields: <Field>[field]);
      Component component = new Component(libraries: <Library>[library]);
      component.computeCanonicalNames();
      return new TestCase<Statement>(
          name: '/* suppose top-level: dynamic field; */ field = 1;',
          node:
              new ExpressionStatement(new StaticSet(field, new IntLiteral(1))),
          expectation: ''
              '(expr'
              ' (set-static "package:foo/bar.dart::@setters::field" (int 1)))',
          makeSerializationState: () =>
              new SerializationState(new SerializationEnvironment(null)),
          makeDeserializationState: () => new DeserializationState(
              new DeserializationEnvironment(null), component.root),
          serializer: statementSerializer);
    }(),
    () {
      Uri uri = new Uri(scheme: 'package', path: 'foo/bar.dart');
      Procedure topLevelProcedure = new Procedure(
          new Name('foo'),
          ProcedureKind.Method,
          new FunctionNode(null, positionalParameters: <VariableDeclaration>[
            new VariableDeclaration('x', type: const DynamicType())
          ]),
          isStatic: true,
          fileUri: uri);
      Library library = new Library(uri,
          fileUri: uri, procedures: <Procedure>[topLevelProcedure]);
      Component component = new Component(libraries: <Library>[library]);
      component.computeCanonicalNames();
      return new TestCase<Statement>(
          name: '/* suppose top-level: foo(dynamic x) {...}; */ foo(42);',
          node: new ExpressionStatement(new StaticInvocation.byReference(
              topLevelProcedure.reference,
              new Arguments(<Expression>[new IntLiteral(42)]),
              isConst: false)),
          expectation: ''
              '(expr (invoke-static "package:foo/bar.dart::@methods::foo"'
              ' () ((int 42)) ()))',
          makeSerializationState: () =>
              new SerializationState(new SerializationEnvironment(null)),
          makeDeserializationState: () => new DeserializationState(
              new DeserializationEnvironment(null), component.root),
          serializer: statementSerializer);
    }(),
    () {
      Uri uri = new Uri(scheme: 'package', path: 'foo/bar.dart');
      Procedure factoryConstructor = new Procedure(
          new Name('foo'), ProcedureKind.Factory, new FunctionNode(null),
          isStatic: true, isConst: true, fileUri: uri);
      Class klass = new Class(
          name: 'A', procedures: <Procedure>[factoryConstructor], fileUri: uri);
      Library library = new Library(uri, fileUri: uri, classes: <Class>[klass]);
      Component component = new Component(libraries: <Library>[library]);
      component.computeCanonicalNames();
      return new TestCase<Statement>(
          name: ''
              '/* suppose A { const A(); const factory A.foo() = A; } */'
              ' const A.foo();',
          node: new ExpressionStatement(new StaticInvocation.byReference(
              factoryConstructor.reference, new Arguments([]), isConst: true)),
          expectation: ''
              '(expr (invoke-const-static'
              ' "package:foo/bar.dart::A::@factories::foo"'
              ' () () ()))',
          makeSerializationState: () =>
              new SerializationState(new SerializationEnvironment(null)),
          makeDeserializationState: () => new DeserializationState(
              new DeserializationEnvironment(null), component.root),
          serializer: statementSerializer);
    }(),
    () {
      Uri uri = new Uri(scheme: 'package', path: 'foo/bar.dart');
      Field field = new Field.immutable(new Name('field'),
          type: const DynamicType(), fileUri: uri);
      Class klass = new Class(name: 'A', fields: <Field>[field], fileUri: uri);
      Library library = new Library(uri, fileUri: uri, classes: <Class>[klass]);
      Component component = new Component(libraries: <Library>[library]);
      component.computeCanonicalNames();

      VariableDeclaration x =
          new VariableDeclaration('x', type: const DynamicType());
      return new TestCase<Statement>(
          name: '/* suppose A {dynamic field;} A x; */ x.{A::field};',
          node: new ExpressionStatement(new InstanceGet.byReference(
              InstanceAccessKind.Instance, new VariableGet(x), field.name,
              interfaceTargetReference: field.getterReference,
              resultType: field.getterType)),
          expectation: ''
              '(expr (get-instance (instance) (get-var "x^0" _) '
              '(public "field") "package:foo/bar.dart::A::@getters::field" '
              '(dynamic)))',
          makeSerializationState: () =>
              new SerializationState(new SerializationEnvironment(null)
                ..addBinder(x, nameClue: 'x')
                ..extend()),
          makeDeserializationState: () => new DeserializationState(
              new DeserializationEnvironment(null)
                ..addBinder(x, "x^0")
                ..extend(),
              component.root),
          serializer: statementSerializer);
    }(),
    () {
      Uri uri = new Uri(scheme: 'package', path: 'foo/bar.dart');
      Field field = new Field.mutable(new Name('field'),
          type: const DynamicType(), fileUri: uri);
      Class klass = new Class(name: 'A', fields: <Field>[field], fileUri: uri);
      Library library = new Library(uri, fileUri: uri, classes: <Class>[klass]);
      Component component = new Component(libraries: <Library>[library]);
      component.computeCanonicalNames();

      VariableDeclaration x =
          new VariableDeclaration('x', type: const DynamicType());
      return new TestCase<Statement>(
          name: '/* suppose A {dynamic field;} A x; */ x.{A::field};',
          node: new ExpressionStatement(new InstanceGet.byReference(
              InstanceAccessKind.Instance, new VariableGet(x), field.name,
              interfaceTargetReference: field.getterReference,
              resultType: field.getterType)),
          expectation: ''
              '(expr (get-instance (instance) (get-var "x^0" _) '
              '(public "field") "package:foo/bar.dart::A::@getters::field" '
              '(dynamic)))',
          makeSerializationState: () =>
              new SerializationState(new SerializationEnvironment(null)
                ..addBinder(x, nameClue: 'x')
                ..extend()),
          makeDeserializationState: () => new DeserializationState(
              new DeserializationEnvironment(null)
                ..addBinder(x, "x^0")
                ..extend(),
              component.root),
          serializer: statementSerializer);
    }(),
    () {
      Uri uri = new Uri(scheme: 'package', path: 'foo/bar.dart');
      Field field = new Field.mutable(new Name('field'),
          type: const DynamicType(), fileUri: uri);
      Class klass = new Class(name: 'A', fields: <Field>[field], fileUri: uri);
      Library library = new Library(uri, fileUri: uri, classes: <Class>[klass]);
      Component component = new Component(libraries: <Library>[library]);
      component.computeCanonicalNames();

      VariableDeclaration x =
          new VariableDeclaration('x', type: const DynamicType());
      return new TestCase<Statement>(
          name: '/* suppose A {dynamic field;} A x; */ x.{A::field} = 42;',
          node: new ExpressionStatement(InstanceSet.byReference(
              InstanceAccessKind.Instance,
              new VariableGet(x),
              field.name,
              new IntLiteral(42),
              interfaceTargetReference: field.setterReference!)),
          expectation: ''
              '(expr (set-instance (instance) (get-var "x^0" _) '
              '(public "field") (int 42) '
              '"package:foo/bar.dart::A::@setters::field"))',
          makeSerializationState: () =>
              new SerializationState(new SerializationEnvironment(null)
                ..addBinder(x, nameClue: 'x')
                ..extend()),
          makeDeserializationState: () => new DeserializationState(
              new DeserializationEnvironment(null)
                ..addBinder(x, "x^0")
                ..extend(),
              component.root),
          serializer: statementSerializer);
    }(),
    () {
      Uri uri = new Uri(scheme: 'package', path: 'foo/bar.dart');
      Procedure method = new Procedure(
          new Name('foo'), ProcedureKind.Method, new FunctionNode(null),
          isStatic: true, isConst: true, fileUri: uri);
      Class klass =
          new Class(name: 'A', procedures: <Procedure>[method], fileUri: uri);
      Library library = new Library(uri, fileUri: uri, classes: <Class>[klass]);
      Component component = new Component(libraries: <Library>[library]);
      component.computeCanonicalNames();

      VariableDeclaration x =
          new VariableDeclaration('x', type: const DynamicType());
      return new TestCase<Statement>(
          name: '/* suppose A {foo() {...}} A x; */ x.{A::foo}();',
          node: new ExpressionStatement(new InstanceInvocation.byReference(
              InstanceAccessKind.Instance,
              new VariableGet(x),
              method.name,
              new Arguments([]),
              interfaceTargetReference: method.reference,
              functionType: method.getterType as FunctionType)),
          expectation: ''
              '(expr (invoke-instance (instance) (get-var "x^0" _) '
              '(public "foo") () () () '
              '"package:foo/bar.dart::A::@methods::foo" '
              '(-> () () () () () () (dynamic))))',
          makeSerializationState: () =>
              new SerializationState(new SerializationEnvironment(null)
                ..addBinder(x, nameClue: 'x')
                ..extend()),
          makeDeserializationState: () => new DeserializationState(
              new DeserializationEnvironment(null)
                ..addBinder(x, "x^0")
                ..extend(),
              component.root),
          serializer: statementSerializer);
    }(),
    () {
      Uri uri = new Uri(scheme: 'package', path: 'foo/bar.dart');
      Constructor constructor = new Constructor(new FunctionNode(null),
          name: new Name('foo'), fileUri: uri);
      Class klass = new Class(
          name: 'A', constructors: <Constructor>[constructor], fileUri: uri);
      Library library = new Library(uri, fileUri: uri, classes: <Class>[klass]);
      Component component = new Component(libraries: <Library>[library]);
      component.computeCanonicalNames();
      return new TestCase<Statement>(
          name: '/* suppose A {A.foo();} */ new A();',
          node: new ExpressionStatement(new ConstructorInvocation.byReference(
              constructor.reference, new Arguments([]))),
          expectation: ''
              '(expr (invoke-constructor'
              ' "package:foo/bar.dart::A::@constructors::foo"'
              ' () () ()))',
          makeSerializationState: () =>
              new SerializationState(new SerializationEnvironment(null)),
          makeDeserializationState: () => new DeserializationState(
              new DeserializationEnvironment(null), component.root),
          serializer: statementSerializer);
    }(),
    () {
      Uri uri = new Uri(scheme: 'package', path: 'foo/bar.dart');
      Constructor constructor = new Constructor(new FunctionNode(null),
          name: new Name('foo'), isConst: true, fileUri: uri);
      Class klass = new Class(
          name: 'A', constructors: <Constructor>[constructor], fileUri: uri);
      Library library = new Library(uri, fileUri: uri, classes: <Class>[klass]);
      Component component = new Component(libraries: <Library>[library]);
      component.computeCanonicalNames();
      return new TestCase<Statement>(
          name: '/* suppose A {const A.foo();} */ const A();',
          node: new ExpressionStatement(new ConstructorInvocation.byReference(
              constructor.reference, new Arguments([]), isConst: true)),
          expectation: ''
              '(expr (invoke-const-constructor'
              ' "package:foo/bar.dart::A::@constructors::foo"'
              ' () () ()))',
          makeSerializationState: () =>
              new SerializationState(new SerializationEnvironment(null)),
          makeDeserializationState: () => new DeserializationState(
              new DeserializationEnvironment(null), component.root),
          serializer: statementSerializer);
    }(),
    () {
      TypeParameter outerParam =
          new TypeParameter('T', const DynamicType(), const DynamicType());
      TypeParameter innerParam =
          new TypeParameter('T', const DynamicType(), const DynamicType());
      return new TestCase<Statement>(
          name: '/* T Function<T>(T Function<T>()); */',
          node: new ExpressionStatement(new TypeLiteral(new FunctionType(
              [
                new FunctionType(
                    [],
                    new TypeParameterType(innerParam, Nullability.legacy),
                    Nullability.legacy,
                    typeParameters: [innerParam])
              ],
              new TypeParameterType(outerParam, Nullability.legacy),
              Nullability.legacy,
              typeParameters: [outerParam]))),
          expectation: ''
              '(expr (type (-> ("T^0") ((dynamic)) ((dynamic)) '
              '((-> ("T^1") ((dynamic)) ((dynamic)) () () () '
              '(par "T^1" _))) () () (par "T^0" _))))',
          makeSerializationState: () =>
              new SerializationState(new SerializationEnvironment(null)),
          makeDeserializationState: () => new DeserializationState(
              new DeserializationEnvironment(null), new CanonicalName.root()),
          serializer: statementSerializer);
    }(),
    () {
      TypeParameter t =
          new TypeParameter('T', const DynamicType(), const DynamicType());
      VariableDeclaration t1 = new VariableDeclaration('t1',
          type: new TypeParameterType(t, Nullability.legacy));
      VariableDeclaration t2 = new VariableDeclaration('t2',
          type: new TypeParameterType(t, Nullability.legacy));
      return new TestCase<Statement>(
          name: '/* <T>(T t1, [T t2]) => t1; */',
          node: new ExpressionStatement(new FunctionExpression(new FunctionNode(
              new ReturnStatement(new VariableGet(t1)),
              typeParameters: [t],
              positionalParameters: [t1, t2],
              requiredParameterCount: 1,
              namedParameters: [],
              returnType: new TypeParameterType(t, Nullability.legacy),
              asyncMarker: AsyncMarker.Sync))),
          expectation: ''
              '(expr (fun (sync) ("T^0") ((dynamic)) ((dynamic)) ("t1^1" '
              '() (par "T^0" _) _ ()) ("t2^2" () (par "T^0" _) '
              '_ ()) () (par "T^0" _) _ (ret (get-var "t1^1" _))))',
          makeSerializationState: () =>
              new SerializationState(new SerializationEnvironment(null)),
          makeDeserializationState: () => new DeserializationState(
              new DeserializationEnvironment(null), new CanonicalName.root()),
          serializer: statementSerializer);
    }(),
    () {
      Uri uri = Uri(scheme: 'package', path: 'foo/bar.dart');
      VariableDeclaration x = VariableDeclaration('x', type: DynamicType());
      Procedure foo = Procedure(
          Name('foo'),
          ProcedureKind.Method,
          FunctionNode(ReturnStatement(VariableGet(x)),
              positionalParameters: [x]),
          isStatic: true,
          fileUri: uri);
      Library library = Library(uri, fileUri: uri, procedures: [foo]);
      Component component = Component(libraries: [library]);
      component.computeCanonicalNames();
      return new TestCase<Member>(
          name: 'foo(x) => x;',
          node: foo,
          expectation: ''
              '(method (public "foo") ((static))'
              ' (sync) () () () ("x^0" () (dynamic) _ ()) () ()'
              ' (dynamic) _ (ret (get-var "x^0" _))'
              ' "package:foo/bar.dart")',
          makeSerializationState: () =>
              new SerializationState(new SerializationEnvironment(null)),
          makeDeserializationState: () => new DeserializationState(
              new DeserializationEnvironment(null), component.root),
          serializer: memberSerializer);
    }(),
    () {
      Uri uri = Uri(scheme: 'package', path: 'foo/bar.dart');
      VariableDeclaration x1 = VariableDeclaration('x', type: DynamicType());
      VariableDeclaration x2 = VariableDeclaration('x', type: DynamicType());
      Procedure foo = Procedure(
          Name('foo'),
          ProcedureKind.Method,
          FunctionNode(ReturnStatement(VariableGet(x1)),
              positionalParameters: [x1]),
          isStatic: true,
          fileUri: uri);
      Procedure bar = Procedure(
          Name('bar'),
          ProcedureKind.Method,
          FunctionNode(
              ReturnStatement(
                  StaticInvocation(foo, Arguments([VariableGet(x2)]))),
              positionalParameters: [x2]),
          isStatic: true,
          fileUri: uri);
      Library library = Library(uri, fileUri: uri, procedures: [foo, bar]);
      Component component = Component(libraries: [library]);
      component.computeCanonicalNames();
      return new TestCase<Library>(
          name: 'foo(x) => x; bar(x) => foo(x);',
          node: library,
          expectation: ''
              '"package:foo/bar.dart" () ()'
              ''
              ' ((method (public "foo") ((static))'
              ' (sync) () () () ("x^0" () (dynamic) _ ()) () () (dynamic)'
              ' _ (ret (get-var "x^0" _))'
              ' "package:foo/bar.dart")'
              ''
              ' (method (public "bar") ((static))'
              ' (sync) () () () ("x^0" () (dynamic) _ ()) () () (dynamic)'
              ' _ (ret'
              ' (invoke-static "package:foo/bar.dart::@methods::foo"'
              ' () ((get-var "x^0" _)) ()))'
              ' "package:foo/bar.dart"))'
              ''
              ' ()'
              ''
              ' ()'
              ''
              ' ()'
              ''
              ' "package:foo/bar.dart"',
          makeSerializationState: () =>
              new SerializationState(new SerializationEnvironment(null)),
          makeDeserializationState: () => new DeserializationState(
              new DeserializationEnvironment(null), new CanonicalName.root()),
          serializer: librarySerializer);
    }(),
    () {
      Uri uri = Uri(scheme: "package", path: "foo/bar.dart");
      Class a = Class(name: "A", fileUri: uri);
      Procedure foo = Procedure(
          Name("foo"),
          ProcedureKind.Method,
          FunctionNode(ReturnStatement(NullLiteral()),
              returnType: InterfaceType(a, Nullability.legacy)),
          isStatic: true,
          fileUri: uri);
      Library library =
          Library(uri, fileUri: uri, classes: [a], procedures: [foo]);
      Component component = Component(libraries: [library]);
      component.computeCanonicalNames();
      return new TestCase<Library>(
          name: 'class A{} A foo() => null;',
          node: library,
          expectation: ''
              '"package:foo/bar.dart" () ()'
              ''
              ' ((method (public "foo") ((static))'
              ' (sync) () () () () () () (interface "package:foo/bar.dart::A" ())'
              ' _ (ret (null))'
              ' "package:foo/bar.dart"))'
              ''
              ' ("A" () "package:foo/bar.dart" () () () _ _ () ())'
              ''
              ' ()'
              ''
              ' ()'
              ''
              ' "package:foo/bar.dart"',
          makeSerializationState: () =>
              new SerializationState(new SerializationEnvironment(null)),
          makeDeserializationState: () => new DeserializationState(
              new DeserializationEnvironment(null), component.root),
          serializer: librarySerializer);
    }(),
    () {
      return new TestCase<Statement>(
          name: 'dynamic x;',
          node: VariableDeclaration('x', type: const DynamicType()),
          expectation: '(local "x^0" () (dynamic) _ ())',
          makeSerializationState: () =>
              new SerializationState(new SerializationEnvironment(null)),
          makeDeserializationState: () => new DeserializationState(
              new DeserializationEnvironment(null), new CanonicalName.root()),
          serializer: statementSerializer);
    }(),
  ];
  for (TestCase testCase in tests) {
    String roundTripInput =
        testCase.writeNode(testCase.node, testCase.makeSerializationState());
    if (roundTripInput != testCase.expectation) {
      failures.add(''
          "* initial serialization for test '${testCase.name}'"
          " gave output:\n    ${roundTripInput}\n"
          "  but expected:\n    ${testCase.expectation}");
    }

    Node deserialized =
        testCase.readNode(roundTripInput, testCase.makeDeserializationState());
    String roundTripOutput =
        testCase.writeNode(deserialized, testCase.makeSerializationState());
    if (roundTripOutput != roundTripInput) {
      failures.add(''
          "* input '${testCase.name}' gave output '${roundTripOutput}'");
    }
  }
  if (failures.isNotEmpty) {
    print('Round trip failures:');
    failures.forEach(print);
    throw StateError('Round trip failures');
  }
}
