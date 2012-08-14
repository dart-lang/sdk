// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#import('dart:uri');

#import("../../../lib/compiler/implementation/leg.dart");
#import("../../../lib/compiler/implementation/elements/elements.dart");
#import("../../../lib/compiler/implementation/tree/tree.dart");
#import("../../../lib/compiler/implementation/scanner/scannerlib.dart");
#import("../../../lib/compiler/implementation/util/util.dart");
#import("compiler_helper.dart");
#import("mock_compiler.dart");
#import("parser_helper.dart");

Node buildIdentifier(String name) => new Identifier(scan(name));

Node buildInitialization(String name) =>
  parseBodyCode('$name = 1',
      (parser, tokens) => parser.parseOptionallyInitializedIdentifier(tokens));

createLocals(List variables) {
  var locals = [];
  for (final variable in variables) {
    String name = variable[0];
    bool init = variable[1];
    if (init) {
      locals.add(buildInitialization(name));
    } else {
      locals.add(buildIdentifier(name));
    }
  }
  var definitions = new NodeList(null, new Link.fromList(locals), null, null);
  return new VariableDefinitions(null, null, definitions, null);
}

testLocals(List variables) {
  MockCompiler compiler = new MockCompiler();
  ResolverVisitor visitor = compiler.resolverVisitor();
  Element element = visitor.visit(createLocals(variables));
  // A VariableDefinitions does not have an element.
  Expect.equals(null, element);
  Expect.equals(variables.length, map(visitor).length);

  for (final variable in variables) {
    final name = variable[0];
    Identifier id = buildIdentifier(name);
    final VariableElement variableElement = visitor.visit(id);
    MethodScope scope = visitor.scope;
    Expect.equals(variableElement, scope.elements[buildSourceString(name)]);
  }
  return compiler;
}

main() {
  testLocalsOne();
  testLocalsTwo();
  testLocalsThree();
  testLocalsFour();
  testLocalsFive();
  testParametersOne();
  testFor();
  testTypeAnnotation();
  testSuperclass();
  // testVarSuperclass(); // The parser crashes with 'class Foo extends var'.
  // testOneInterface(); // Generates unexpected error message.
  // testTwoInterfaces(); // Generates unexpected error message.
  testFunctionExpression();
  testNewExpression();
  testTopLevelFields();
  testClassHierarchy();
  testInitializers();
  testThis();
  testSuperCalls();
  testTypeVariables();
  testToString();
  testIndexedOperator();
}

testTypeVariables() {
  matchResolvedTypes(visitor, text, name, expectedElements) {
    VariableDefinitions definition = parseStatement(text);
    visitor.visit(definition.type);
    InterfaceType type = visitor.mapping.getType(definition.type);
    Expect.equals(definition.type.typeArguments.length(),
                  length(type.arguments));
    int index = 0;
    Link<Type> arguments = type.arguments;
    while (!arguments.isEmpty()) {
      Expect.equals(true, index < expectedElements.length);
      Expect.equals(expectedElements[index], arguments.head.element);
      index++;
      arguments = arguments.tail;
    }
    Expect.equals(index, expectedElements.length);
  }

  MockCompiler compiler = new MockCompiler();
  ResolverVisitor visitor = compiler.resolverVisitor();
  compiler.parseScript('class Foo<T, U> {}');
  ClassElement foo = compiler.mainApp.find(buildSourceString('Foo'));
  matchResolvedTypes(visitor, 'Foo<int, String> x;', 'Foo',
                     [compiler.intClass, compiler.stringClass]);
  matchResolvedTypes(visitor, 'Foo<Foo, Foo> x;', 'Foo',
                     [foo, foo]);

  compiler = new MockCompiler();
  compiler.parseScript('class Foo<T, U> {}');
  compiler.resolveStatement('Foo<notype, int> x;');
  Expect.equals(1, compiler.warnings.length);
  Expect.equals(MessageKind.CANNOT_RESOLVE_TYPE,
                compiler.warnings[0].message.kind);
  Expect.equals(0, compiler.errors.length);

  compiler = new MockCompiler();
  compiler.parseScript('class Foo<T, U> {}');
  compiler.resolveStatement('var x = new Foo<notype, int>();');
  Expect.equals(0, compiler.warnings.length);
  Expect.equals(1, compiler.errors.length);
  Expect.equals(MessageKind.CANNOT_RESOLVE_TYPE,
                compiler.errors[0].message.kind);

  compiler = new MockCompiler();
  compiler.parseScript('class Foo<T> {'
                       '  Foo<T> t;'
                       '  foo(Foo<T> f) {}'
                       '  bar() { g(Foo<T> f) {}; g(); }'
                       '}');
  foo = compiler.mainApp.find(buildSourceString('Foo'));
  foo.ensureResolved(compiler);
  foo.lookupLocalMember(buildSourceString('t')).computeType(compiler);;
  foo.lookupLocalMember(buildSourceString('foo')).computeType(compiler);;
  compiler.resolver.resolve(foo.lookupLocalMember(buildSourceString('bar')));
  Expect.equals(0, compiler.warnings.length);
  Expect.equals(0, compiler.errors.length);
}

testSuperCalls() {
  MockCompiler compiler = new MockCompiler();
  String script = """class A { foo() {} }
                     class B extends A { foo() => super.foo(); }""";
  compiler.parseScript(script);
  compiler.resolveStatement("B b;");

  ClassElement classB = compiler.mainApp.find(buildSourceString("B"));
  FunctionElement fooB = classB.lookupLocalMember(buildSourceString("foo"));
  ClassElement classA = compiler.mainApp.find(buildSourceString("A"));
  FunctionElement fooA = classA.lookupLocalMember(buildSourceString("foo"));

  ResolverVisitor visitor = new ResolverVisitor(compiler, fooB);
  FunctionExpression node = fooB.parseNode(compiler);
  visitor.visit(node.body);
  Map mapping = map(visitor);

  Send superCall = node.body.asReturn().expression;
  FunctionElement called = mapping[superCall];
  Expect.isTrue(called !== null);
  Expect.equals(fooA, called);
}

testThis() {
  MockCompiler compiler = new MockCompiler();
  compiler.parseScript("class Foo { foo() { return this; } }");
  compiler.resolveStatement("Foo foo;");
  ClassElement fooElement = compiler.mainApp.find(buildSourceString("Foo"));
  FunctionElement funElement =
      fooElement.lookupLocalMember(buildSourceString("foo"));
  ResolverVisitor visitor = new ResolverVisitor(compiler, funElement);
  FunctionExpression function = funElement.parseNode(compiler);
  visitor.visit(function.body);
  Map mapping = map(visitor);
  List<Element> values = mapping.getValues();
  Expect.equals(0, mapping.length);
  Expect.equals(0, compiler.warnings.length);

  compiler = new MockCompiler();
  compiler.resolveStatement("main() { return this; }");
  Expect.equals(0, compiler.warnings.length);
  Expect.equals(1, compiler.errors.length);
  Expect.equals(MessageKind.NO_INSTANCE_AVAILABLE,
                compiler.errors[0].message.kind);

  compiler = new MockCompiler();
  compiler.parseScript("class Foo { static foo() { return this; } }");
  compiler.resolveStatement("Foo foo;");
  fooElement = compiler.mainApp.find(buildSourceString("Foo"));
  funElement =
      fooElement.lookupLocalMember(buildSourceString("foo"));
  visitor = new ResolverVisitor(compiler, funElement);
  function = funElement.parseNode(compiler);
  visitor.visit(function.body);
  Expect.equals(0, compiler.warnings.length);
  Expect.equals(1, compiler.errors.length);
  Expect.equals(MessageKind.NO_INSTANCE_AVAILABLE,
                compiler.errors[0].message.kind);
}

testLocalsOne() {
  testLocals([["foo", false]]);
  testLocals([["foo", false], ["bar", false]]);
  testLocals([["foo", false], ["bar", false], ["foobar", false]]);

  testLocals([["foo", true]]);
  testLocals([["foo", false], ["bar", true]]);
  testLocals([["foo", true], ["bar", true]]);

  testLocals([["foo", false], ["bar", false], ["foobar", true]]);
  testLocals([["foo", false], ["bar", true], ["foobar", true]]);
  testLocals([["foo", true], ["bar", true], ["foobar", true]]);

  MockCompiler compiler = testLocals([["foo", false], ["foo", false]]);
  Expect.equals(1, compiler.errors.length);
  Expect.equals(
      new Message(MessageKind.DUPLICATE_DEFINITION, ['foo']),
      compiler.errors[0].message);
}


testLocalsTwo() {
  MockCompiler compiler = new MockCompiler();
  ResolverVisitor visitor = compiler.resolverVisitor();
  Node tree = parseStatement("if (true) { var a = 1; var b = 2; }");
  Element element = visitor.visit(tree);
  Expect.equals(null, element);
  BlockScope scope = visitor.scope;
  Expect.equals(0, scope.elements.length);
  Expect.equals(2, map(visitor).length);

  List<Element> elements = map(visitor).getValues();
  Expect.notEquals(elements[0], elements[1]);
}

testLocalsThree() {
  MockCompiler compiler = new MockCompiler();
  ResolverVisitor visitor = compiler.resolverVisitor();
  Node tree = parseStatement("{ var a = 1; if (true) { a; } }");
  Element element = visitor.visit(tree);
  Expect.equals(null, element);
  BlockScope scope = visitor.scope;
  Expect.equals(0, scope.elements.length);
  Expect.equals(3, map(visitor).length);
  List<Element> elements = map(visitor).getValues();
  Expect.equals(elements[0], elements[1]);
}

testLocalsFour() {
  MockCompiler compiler = new MockCompiler();
  ResolverVisitor visitor = compiler.resolverVisitor();
  Node tree = parseStatement("{ var a = 1; if (true) { var a = 1; } }");
  Element element = visitor.visit(tree);
  Expect.equals(null, element);
  BlockScope scope = visitor.scope;
  Expect.equals(0, scope.elements.length);
  Expect.equals(2, map(visitor).length);
  List<Element> elements = map(visitor).getValues();
  Expect.notEquals(elements[0], elements[1]);
}

testLocalsFive() {
  MockCompiler compiler = new MockCompiler();
  ResolverVisitor visitor = compiler.resolverVisitor();
  If tree = parseStatement("if (true) { var a = 1; a; } else { var a = 2; a;}");
  Element element = visitor.visit(tree);
  Expect.equals(null, element);
  BlockScope scope = visitor.scope;
  Expect.equals(0, scope.elements.length);
  Expect.equals(6, map(visitor).length);

  Block thenPart = tree.thenPart;
  List statements1 = thenPart.statements.nodes.toList();
  Node def1 = statements1[0].definitions.nodes.head;
  Node id1 = statements1[1].expression;
  Expect.equals(visitor.mapping[def1], visitor.mapping[id1]);

  Block elsePart = tree.elsePart;
  List statements2 = elsePart.statements.nodes.toList();
  Node def2 = statements2[0].definitions.nodes.head;
  Node id2 = statements2[1].expression;
  Expect.equals(visitor.mapping[def2], visitor.mapping[id2]);

  Expect.notEquals(visitor.mapping[def1], visitor.mapping[def2]);
  Expect.notEquals(visitor.mapping[id1], visitor.mapping[id2]);
}

testParametersOne() {
  MockCompiler compiler = new MockCompiler();
  ResolverVisitor visitor = compiler.resolverVisitor();
  FunctionExpression tree =
      parseFunction("void foo(int a) { return a; }", compiler);
  visitor.visit(tree);

  // Check that an element has been created for the parameter.
  VariableDefinitions vardef = tree.parameters.nodes.head;
  Node param = vardef.definitions.nodes.head;
  Expect.equals(ElementKind.PARAMETER, visitor.mapping[param].kind);

  // Check that 'a' in 'return a' is resolved to the parameter.
  Block body = tree.body;
  Return ret = body.statements.nodes.head;
  Send use = ret.expression;
  Expect.equals(ElementKind.PARAMETER, visitor.mapping[use].kind);
  Expect.equals(visitor.mapping[param], visitor.mapping[use]);
}

testFor() {
  MockCompiler compiler = new MockCompiler();
  ResolverVisitor visitor = compiler.resolverVisitor();
  For tree = parseStatement("for (int i = 0; i < 10; i = i + 1) { i = 5; }");
  visitor.visit(tree);

  BlockScope scope = visitor.scope;
  Expect.equals(0, scope.elements.length);
  Expect.equals(10, map(visitor).length);

  VariableDefinitions initializer = tree.initializer;
  Node iNode = initializer.definitions.nodes.head;
  Element iElement = visitor.mapping[iNode];

  // Check that we have the expected nodes. This test relies on the mapping
  // field to be a linked hash map (preserving insertion order).
  Expect.isTrue(map(visitor) is LinkedHashMap);
  List<Node> nodes = map(visitor).getKeys();
  List<Element> elements = map(visitor).getValues();


  // for (int i = 0; i < 10; i = i + 1) { i = 5; };
  //      ^^^
  Expect.isTrue(nodes[0] is TypeAnnotation);

  // for (int i = 0; i < 10; i = i + 1) { i = 5; };
  //          ^^^^^
  checkSendSet(iElement, nodes[1], elements[1]);

  // for (int i = 0; i < 10; i = i + 1) { i = 5; };
  //                 ^
  checkIdentifier(iElement, nodes[2], elements[2]);

  // for (int i = 0; i < 10; i = i + 1) { i = 5; };
  //                 ^
  checkSend(iElement, nodes[3], elements[3]);

  // for (int i = 0; i < 10; i = i + 1) { i = 5; };
  //                         ^
  checkIdentifier(iElement, nodes[4], elements[4]);

  // for (int i = 0; i < 10; i = i + 1) { i = 5; };
  //                             ^
  checkIdentifier(iElement, nodes[5], elements[5]);

  // for (int i = 0; i < 10; i = i + 1) { i = 5; };
  //                             ^
  checkSend(iElement, nodes[6], elements[6]);

  // for (int i = 0; i < 10; i = i + 1) { i = 5; };
  //                         ^^^^^^^^^
  checkSendSet(iElement, nodes[7], elements[7]);

  // for (int i = 0; i < 10; i = i + 1) { i = 5; };
  //                                      ^
  checkIdentifier(iElement, nodes[8], elements[8]);

  // for (int i = 0; i < 10; i = i + 1) { i = 5; };
  //                                      ^^^^^
  checkSendSet(iElement, nodes[9], elements[9]);
}

checkIdentifier(Element expected, Node node, Element actual) {
  Expect.isTrue(node is Identifier, node.toDebugString());
  Expect.equals(expected, actual);
}

checkSend(Element expected, Node node, Element actual) {
  Expect.isTrue(node is Send, node.toDebugString());
  Expect.isTrue(node is !SendSet, node.toDebugString());
  Expect.equals(expected, actual);
}

checkSendSet(Element expected, Node node, Element actual) {
  Expect.isTrue(node is SendSet, node.toDebugString());
  Expect.equals(expected, actual);
}

testTypeAnnotation() {
  MockCompiler compiler = new MockCompiler();
  String statement = "Foo bar;";

  // Test that we get a warning when Foo is not defined.
  Map mapping = compiler.resolveStatement(statement).map;

  Expect.equals(1, mapping.length); // bar has an element.
  Expect.equals(1, compiler.warnings.length);

  Node warningNode = compiler.warnings[0].node;

  Expect.equals(
      new Message(MessageKind.CANNOT_RESOLVE_TYPE, ['Foo']),
      compiler.warnings[0].message);
  VariableDefinitions definition = compiler.parsedTree;
  Expect.equals(warningNode, definition.type);
  compiler.clearWarnings();

  // Test that there is no warning after defining Foo.
  compiler.parseScript("class Foo {}");
  mapping = compiler.resolveStatement(statement).map;
  Expect.equals(2, mapping.length);
  Expect.equals(0, compiler.warnings.length);

  // Test that 'var' does not create a warning.
  mapping = compiler.resolveStatement("var foo;").map;
  Expect.equals(1, mapping.length);
  Expect.equals(0, compiler.warnings.length);
}

testSuperclass() {
  MockCompiler compiler = new MockCompiler();
  compiler.parseScript("class Foo extends Bar {}");
  compiler.resolveStatement("Foo bar;");
  // TODO(ahe): We get the same error twice: once from
  // ClassResolverVisitor, and once from ClassSupertypeResolver. We
  // should only the get the error once.
  Expect.equals(2, compiler.errors.length);
  var cannotResolveBar = new Message(MessageKind.CANNOT_RESOLVE_TYPE, ['Bar']);
  Expect.equals(cannotResolveBar, compiler.errors[0].message);
  Expect.equals(cannotResolveBar, compiler.errors[1].message);
  compiler.clearErrors();

  compiler = new MockCompiler();
  compiler.parseScript("class Foo extends Bar {}");
  compiler.parseScript("class Bar {}");
  Map mapping = compiler.resolveStatement("Foo bar;").map;
  Expect.equals(2, mapping.length);

  ClassElement fooElement = compiler.mainApp.find(buildSourceString('Foo'));
  ClassElement barElement = compiler.mainApp.find(buildSourceString('Bar'));
  Expect.equals(barElement.computeType(compiler),
                fooElement.supertype);
  Expect.isTrue(fooElement.interfaces.isEmpty());
  Expect.isTrue(barElement.interfaces.isEmpty());
}

testVarSuperclass() {
  MockCompiler compiler = new MockCompiler();
  compiler.parseScript("class Foo extends var {}");
  compiler.resolveStatement("Foo bar;");
  Expect.equals(1, compiler.errors.length);
  Expect.equals(
      new Message(MessageKind.CANNOT_RESOLVE_TYPE, ['var']),
      compiler.errors[0].message);
  compiler.clearErrors();
}

testOneInterface() {
  MockCompiler compiler = new MockCompiler();
  compiler.parseScript("class Foo implements Bar {}");
  compiler.resolveStatement("Foo bar;");
  Expect.equals(1, compiler.errors.length);
  Expect.equals(
      new Message(MessageKind.CANNOT_RESOLVE_TYPE, ['bar']),
      compiler.errors[0].message);
  compiler.clearErrors();

  // Add the interface to the world and make sure everything is setup correctly.
  compiler.parseScript("interface Bar {}");

  ResolverVisitor visitor = new ResolverVisitor(compiler, null);
  compiler.resolveStatement("Foo bar;");

  ClassElement fooElement = compiler.mainApp.find(buildSourceString('Foo'));
  ClassElement barElement = compiler.mainApp.find(buildSourceString('Bar'));

  Expect.equals(null, barElement.supertype);
  Expect.isTrue(barElement.interfaces.isEmpty());

  Expect.equals(barElement.computeType(compiler),
                fooElement.interfaces.head);
  Expect.equals(1, length(fooElement.interfaces));
}

testTwoInterfaces() {
  MockCompiler compiler = new MockCompiler();
  compiler.parseScript(
      "interface I1 {} interface I2 {} class C implements I1, I2 {}");
  compiler.resolveStatement("Foo bar;");

  ClassElement c = compiler.mainApp.find(buildSourceString('C'));
  Element i1 = compiler.mainApp.find(buildSourceString('I1'));
  Element i2 = compiler.mainApp.find(buildSourceString('I2'));

  Expect.equals(2, length(c.interfaces));
  Expect.equals(i1.computeType(compiler), at(c.interfaces, 0));
  Expect.equals(i2.computeType(compiler), at(c.interfaces, 1));
}

testFunctionExpression() {
  MockCompiler compiler = new MockCompiler();
  ResolverVisitor visitor = compiler.resolverVisitor();
  Map mapping = compiler.resolveStatement("int f() {}").map;
  Expect.equals(3, mapping.length);
  Element element;
  Node node;
  mapping.forEach((Node n, Element e) {
    if (n is FunctionExpression) {
      element = e;
      node = n;
    }
  });
  Expect.equals(ElementKind.FUNCTION, element.kind);
  Expect.equals(buildSourceString('f'), element.name);
  Expect.equals(element.parseNode(compiler), node);
}

testNewExpression() {
  MockCompiler compiler = new MockCompiler();
  compiler.parseScript("class A {} foo() { print(new A()); }");
  ClassElement aElement = compiler.mainApp.find(buildSourceString('A'));
  FunctionElement fooElement = compiler.mainApp.find(buildSourceString('foo'));
  Expect.isTrue(aElement !== null);
  Expect.isTrue(fooElement !== null);

  fooElement.parseNode(compiler);
  compiler.resolver.resolve(fooElement);

  TreeElements elements = compiler.resolveStatement("new A();");
  NewExpression expression =
      compiler.parsedTree.asExpressionStatement().expression;
  Element element = elements[expression.send];
  Expect.equals(ElementKind.GENERATIVE_CONSTRUCTOR, element.kind);
  Expect.isTrue(element is SynthesizedConstructorElement);
}

testTopLevelFields() {
  MockCompiler compiler = new MockCompiler();
  compiler.parseScript("int a;");
  VariableElement element = compiler.mainApp.find(buildSourceString("a"));
  Expect.equals(ElementKind.FIELD, element.kind);
  VariableDefinitions node = element.variables.parseNode(compiler);
  Identifier typeName = node.type.typeName;
  Expect.equals(typeName.source.slowToString(), 'int');

  compiler.parseScript("var b, c;");
  VariableElement bElement = compiler.mainApp.find(buildSourceString("b"));
  VariableElement cElement = compiler.mainApp.find(buildSourceString("c"));
  Expect.equals(ElementKind.FIELD, bElement.kind);
  Expect.equals(ElementKind.FIELD, cElement.kind);
  Expect.isTrue(bElement != cElement);

  VariableDefinitions bNode = bElement.variables.parseNode(compiler);
  VariableDefinitions cNode = cElement.variables.parseNode(compiler);
  Expect.equals(bNode, cNode);
  Expect.isNull(bNode.type);
  Expect.isTrue(bNode.modifiers.isVar());
}

resolveConstructor(String script, String statement, String className,
                   String constructor, int expectedElementCount,
                   [List expectedWarnings = const [],
                    List expectedErrors = const [],
                    String corelib = DEFAULT_CORELIB]) {
  MockCompiler compiler = new MockCompiler(corelib);
  compiler.parseScript(script);
  compiler.resolveStatement(statement);
  ClassElement classElement =
      compiler.mainApp.find(buildSourceString(className));
  Element element =
      classElement.lookupConstructor(buildSourceString(constructor));
  FunctionExpression tree = element.parseNode(compiler);
  ResolverVisitor visitor = new ResolverVisitor(compiler, element);
  new InitializerResolver(visitor).resolveInitializers(element, tree);
  visitor.visit(tree.body);
  Expect.equals(expectedElementCount, map(visitor).length);

  compareWarningKinds(script, expectedWarnings, compiler.warnings);
  compareWarningKinds(script, expectedErrors, compiler.errors);
}

testClassHierarchy() {
  final MAIN = buildSourceString("main");
  MockCompiler compiler = new MockCompiler();
  compiler.parseScript("""class A extends B {}
                          class B extends A {}
                          main() { return new A(); }""");
  FunctionElement mainElement = compiler.mainApp.find(MAIN);
  compiler.resolver.resolve(mainElement);
  Expect.equals(0, compiler.warnings.length);
  Expect.equals(1, compiler.errors.length);
  Expect.equals(MessageKind.CYCLIC_CLASS_HIERARCHY,
                compiler.errors[0].message.kind);

  compiler = new MockCompiler();
  compiler.parseScript("""interface A extends B {}
                          interface B extends A {}
                          class C implements A {}
                          main() { return new C(); }""");
  mainElement = compiler.mainApp.find(MAIN);
  compiler.resolver.resolve(mainElement);
  Expect.equals(0, compiler.warnings.length);
  Expect.equals(1, compiler.errors.length);
  Expect.equals(MessageKind.CYCLIC_CLASS_HIERARCHY,
                compiler.errors[0].message.kind);

  compiler = new MockCompiler();
  compiler.parseScript("""class A extends B {}
                          class B extends C {}
                          class C {}
                          main() { return new A(); }""");
  mainElement = compiler.mainApp.find(MAIN);
  compiler.resolver.resolve(mainElement);
  Expect.equals(0, compiler.warnings.length);
  Expect.equals(0, compiler.errors.length);
  ClassElement aElement = compiler.mainApp.find(buildSourceString("A"));
  Link<Type> supertypes = aElement.allSupertypes;
  Expect.equals(<String>['B', 'C', 'Object'].toString(),
                asSortedStrings(supertypes).toString());
}

testInitializers() {
  String script;
  script = """class A {
                int foo; int bar;
                A() : this.foo = 1, bar = 2;
              }""";
  resolveConstructor(script, "A a = new A();", "A", "A", 2);

  script = """class A {
                int foo; A a;
                A() : a.foo = 1;
                }""";
  resolveConstructor(script, "A a = new A();", "A", "A", 0,
                     [], [MessageKind.INVALID_RECEIVER_IN_INITIALIZER]);

  script = """class A {
                int foo;
                A() : this.foo = 1, this.foo = 2;
              }""";
  resolveConstructor(script, "A a = new A();", "A", "A", 2,
                     [MessageKind.ALREADY_INITIALIZED],
                     [MessageKind.DUPLICATE_INITIALIZER]);

  script = """class A {
                A() : this.foo = 1;
              }""";
  resolveConstructor(script, "A a = new A();", "A", "A", 0,
                     [], [MessageKind.CANNOT_RESOLVE]);

  script = """class A {
                int foo;
                int bar;
                A() : this.foo = bar;
              }""";
  resolveConstructor(script, "A a = new A();", "A", "A", 3,
                     [], [MessageKind.NO_INSTANCE_AVAILABLE]);

  script = """class A {
                int foo() => 42;
                A() : foo();
              }""";
  resolveConstructor(script, "A a = new A();", "A", "A", 0,
                     [], [MessageKind.CONSTRUCTOR_CALL_EXPECTED]);

  script = """class A {
                int i;
                A.a() : this.b(0);
                A.b(int i);
              }""";
  resolveConstructor(script, "A a = new A.a();", "A", @"A$a", 1,
                     [], []);

  script = """class A {
                int i;
                A.a() : i = 42, this(0);
                A(int i);
              }""";
  resolveConstructor(script, "A a = new A.a();", "A", @"A$a", 2,
                     [], [MessageKind.REDIRECTING_CONSTRUCTOR_HAS_INITIALIZER]);

  script = """class A {
                int i;
                A(i);
              }
              class B extends A {
                B() : super(0);
              }""";
  resolveConstructor(script, "B a = new B();", "B", "B", 1,
                     [], []);

  script = """class A {
                int i;
                A(i);
              }
              class B extends A {
                B() : super(0), super(1);
              }""";
  resolveConstructor(script, "B b = new B();", "B", "B", 2,
                     [], [MessageKind.DUPLICATE_SUPER_INITIALIZER]);

  script = "";
  final String CORELIB_WITH_INVALID_OBJECT =
      '''print(var obj) {}
         class int {}
         class double {}
         class bool {}
         class String {}
         class num {}
         class Function {}
         class List {}
         class Closure {}
         class Null {}
         class Dynamic {}
         class Object { Object() : super(); }''';
  resolveConstructor(script, "Object o = new Object();", "Object", "Object", 1,
                     [], [MessageKind.SUPER_INITIALIZER_IN_OBJECT],
                     corelib: CORELIB_WITH_INVALID_OBJECT);
}

map(ResolverVisitor visitor) {
  TreeElementMapping elements = visitor.mapping;
  return elements.map;
}

length(Link link) => link.isEmpty() ? 0 : length(link.tail) + 1;

at(Link link, int index) => (index == 0) ? link.head : at(link.tail, index - 1);

List<String> asSortedStrings(Link link) {
  List<String> result = <String>[];
  for (; !link.isEmpty(); link = link.tail) result.add(link.head.toString());
  result.sort((s1, s2) => s1.compareTo(s2));
  return result;
}

compileScript(String source) {
  Uri uri = new Uri.fromComponents(scheme: 'source');
  MockCompiler compiler = compilerFor(source, uri);
  compiler.runCompiler(uri);
  return compiler;
}

testToString() {
  final script = @"class C { toString() => 'C'; } main() { '${new C()}'; }";
  final compiler = compileScript(script);

  Element toStringMethod = findElement(compiler, 'C')
      .lookupLocalMember(buildSourceString('toString'));
  Expect.isNotNull(toStringMethod);

  Expect.isNotNull(
      compiler.enqueuer.resolution.getCachedElements(toStringMethod));
}

testIndexedOperator() {
  final script = @"""
      class C {
        operator[](ix) => ix;
        operator[]=(ix, v) {}
      }
      main() { var c = new C(); c[0]++ ; }""";
  final compiler = compileScript(script);

  operatorName(op) => Elements.constructOperatorName(
      const SourceString('operator'), new SourceString(op));

  Element indexedOperator = findElement(compiler, 'C')
      .lookupLocalMember(operatorName('[]'));
  Expect.isNotNull(indexedOperator);
  Expect.isNotNull(
      compiler.enqueuer.resolution.getCachedElements(indexedOperator));

  Element indexedSetOperator = findElement(compiler, 'C')
      .lookupLocalMember(operatorName('[]='));
  Expect.isNotNull(indexedOperator);
  Expect.isNotNull(
      compiler.enqueuer.resolution.getCachedElements(indexedSetOperator));
}
