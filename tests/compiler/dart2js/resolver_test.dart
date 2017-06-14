// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';
import 'dart:collection';

import 'package:async_helper/async_helper.dart';
import 'package:expect/expect.dart';
import 'package:compiler/src/constants/expressions.dart';
import 'package:compiler/src/elements/modelx.dart';
import 'package:compiler/src/elements/resolution_types.dart';
import 'package:compiler/src/elements/types.dart';
import 'package:compiler/src/resolution/constructors.dart';
import 'package:compiler/src/resolution/members.dart';
import 'package:compiler/src/resolution/registry.dart';
import 'package:compiler/src/resolution/resolution_result.dart';
import 'package:compiler/src/resolution/scope.dart';
import 'package:compiler/src/resolution/tree_elements.dart';
import 'package:compiler/src/universe/use.dart';
import 'package:compiler/src/universe/world_impact.dart';

import 'compiler_helper.dart';
import 'link_helper.dart';
import 'parser_helper.dart';

Node buildIdentifier(String name) => new Identifier(scan(name));

Node buildInitialization(String name) => parseBodyCode('$name = 1',
    (parser, tokens) => parser.parseOptionallyInitializedIdentifier(tokens));

createLocals(List variables) {
  var locals = <Node>[];
  for (final variable in variables) {
    String name = variable[0];
    bool init = variable[1];
    if (init) {
      locals.add(buildInitialization(name));
    } else {
      locals.add(buildIdentifier(name));
    }
  }
  var definitions = new NodeList(null, LinkFromList(locals), null, null);
  return new VariableDefinitions(null, Modifiers.EMPTY, definitions);
}

Future testLocals(List variables) {
  return MockCompiler.create((MockCompiler compiler) {
    ResolverVisitor visitor = compiler.resolverVisitor();
    ResolutionResult result = visitor.visit(createLocals(variables));
    // A VariableDefinitions does not have an element.
    Expect.equals(const NoneResult(), result);
    Expect.equals(variables.length, map(visitor).length);

    for (final variable in variables) {
      final name = variable[0];
      Identifier id = buildIdentifier(name);
      ResolutionResult result = visitor.visit(id);
      final VariableElement variableElement = result.element;
      MethodScope scope = visitor.scope;
      Expect.equals(variableElement, scope.elements[name]);
    }
    return compiler;
  });
}

main() {
  asyncTest(() => Future.forEach([
        testLocalsOne,
        testLocalsTwo,
        testLocalsThree,
        testLocalsFour,
        testLocalsFive,
        testParametersOne,
        testFor,
        testTypeAnnotation,
        testSuperclass,
        // testVarSuperclass, // The parser crashes with 'class Foo extends var'.
        // testOneInterface, // Generates unexpected error message.
        // testTwoInterfaces, // Generates unexpected error message.
        testFunctionExpression,
        testNewExpression,
        testTopLevelFields,
        testClassHierarchy,
        testEnumDeclaration,
        testInitializers,
        testThis,
        testSuperCalls,
        testSwitch,
        testTypeVariables,
        testToString,
        testIndexedOperator,
        testIncrementsAndDecrements,
        testOverrideHashCodeCheck,
        testSupertypeOrder,
        testConstConstructorAndNonFinalFields,
        testCantAssignMethods,
        testCantAssignFinalAndConsts,
        testAwaitHint,
        testConstantExpressions,
      ], (f) => f()));
}

Future testSupertypeOrder() {
  return Future.wait([
    MockCompiler.create((MockCompiler compiler) {
      compiler.parseScript("""
class I1 {}
class I2 {}
class J1 extends K1 {}
class J2 implements K2 {}
class K1 {}
class K2 {}
class L1 {}
class A implements I1, I2 {}
class B extends A implements J1, J2 {}
class C extends B implements L1 {}
""");
      compiler.resolveStatement("C c;");
      LibraryElement mainApp = compiler.mainApp;
      ClassElement classA = mainApp.find("A");
      ClassElement classB = mainApp.find("B");
      ClassElement classC = mainApp.find("C");
      Expect.equals('[ I2, I1, Object ]', classA.allSupertypes.toString());
      Expect.equals('[ A, J2, J1, I2, I1, K2, K1, Object ]',
          classB.allSupertypes.toString());
      Expect.equals('[ B, L1, A, J2, J1, I2, I1, K2, K1, Object ]',
          classC.allSupertypes.toString());
    }),
    MockCompiler.create((MockCompiler compiler) {
      compiler.parseScript("""
class X<T> {}
class Foo extends X<Foo> {}
class Bar extends Foo implements X<Bar> {}
""");
      compiler.resolveStatement("Bar bar;");
      LibraryElement mainApp = compiler.mainApp;
      ClassElement classBar = mainApp.find("Bar");
      DiagnosticCollector collector = compiler.diagnosticCollector;
      Expect.equals(0, collector.warnings.length);
      Expect.equals(1, collector.errors.length);
      Expect.equals(
          MessageKind.MULTI_INHERITANCE, collector.errors.first.message.kind);
      Expect.equals(0, collector.crashes.length);
    }),
  ]);
}

Future testTypeVariables() {
  matchResolvedTypes(visitor, text, name, expectedElements) {
    VariableDefinitions definition = parseStatement(text);
    visitor.visit(definition.type);
    ResolutionInterfaceType type =
        visitor.registry.mapping.getType(definition.type);
    NominalTypeAnnotation annotation = definition.type;
    Expect.equals(
        annotation.typeArguments.slowLength(), type.typeArguments.length);
    int index = 0;
    for (ResolutionDartType argument in type.typeArguments) {
      Expect.equals(true, index < expectedElements.length);
      Expect.equals(expectedElements[index], argument.element);
      index++;
    }
    Expect.equals(index, expectedElements.length);
  }

  return Future.wait([
    MockCompiler.create((MockCompiler compiler) {
      ResolverVisitor visitor = compiler.resolverVisitor();
      compiler.parseScript('class Foo<T, U> {}');
      LibraryElement mainApp = compiler.mainApp;
      ClassElement foo = mainApp.find('Foo');
      matchResolvedTypes(visitor, 'Foo<int, String> x;', 'Foo', [
        compiler.resolution.commonElements.intClass,
        compiler.resolution.commonElements.stringClass
      ]);
      matchResolvedTypes(visitor, 'Foo<Foo, Foo> x;', 'Foo', [foo, foo]);
    }),
    MockCompiler.create((MockCompiler compiler) {
      compiler.parseScript('class Foo<T, U> {}');
      compiler.resolveStatement('Foo<notype, int> x;');
      DiagnosticCollector collector = compiler.diagnosticCollector;
      Expect.equals(1, collector.warnings.length);
      Expect.equals(MessageKind.CANNOT_RESOLVE_TYPE,
          collector.warnings.first.message.kind);
      Expect.equals(0, collector.errors.length);
    }),
    MockCompiler.create((MockCompiler compiler) {
      compiler.parseScript('class Foo<T, U> {}');
      compiler.resolveStatement('var x = new Foo<notype, int>();');
      DiagnosticCollector collector = compiler.diagnosticCollector;
      Expect.equals(1, collector.warnings.length);
      Expect.equals(0, collector.errors.length);
      Expect.equals(MessageKind.CANNOT_RESOLVE_TYPE,
          collector.warnings.first.message.kind);
    }),
    MockCompiler.create((MockCompiler compiler) {
      compiler.parseScript('class Foo<T> {'
          '  Foo<T> t;'
          '  foo(Foo<T> f) {}'
          '  bar() { g(Foo<T> f) {}; g(); }'
          '}');
      LibraryElement mainApp = compiler.mainApp;
      ClassElement foo = mainApp.find('Foo');
      foo.ensureResolved(compiler.resolution);
      MemberElement tMember = foo.lookupLocalMember('t');
      tMember.computeType(compiler.resolution);
      MemberElement fooMember = foo.lookupLocalMember('foo');
      fooMember.computeType(compiler.resolution);
      compiler.resolver.resolve(foo.lookupLocalMember('bar'));
      DiagnosticCollector collector = compiler.diagnosticCollector;
      Expect.equals(0, collector.warnings.length);
      Expect.equals(0, collector.errors.length);
    }),
  ]);
}

Future testSuperCalls() {
  return MockCompiler.create((MockCompiler compiler) {
    String script = """class A { foo() {} }
                       class B extends A { foo() => super.foo(); }""";
    compiler.parseScript(script);
    compiler.resolveStatement("B b;");

    LibraryElement mainApp = compiler.mainApp;
    ClassElement classB = mainApp.find("B");
    FunctionElement fooB = classB.lookupLocalMember("foo");
    ClassElement classA = mainApp.find("A");
    FunctionElement fooA = classA.lookupLocalMember("foo");

    ResolverVisitor visitor = new ResolverVisitor(
        compiler.resolution,
        fooB,
        new ResolutionRegistry(
            compiler.backend.target, new CollectingTreeElements(fooB)),
        scope: new MockTypeVariablesScope(classB.buildScope()));
    FunctionExpression node =
        (fooB as FunctionElementX).parseNode(compiler.parsingContext);
    visitor.visit(node.body);
    Map mapping = map(visitor);

    Send superCall = node.body.asReturn().expression;
    FunctionElement called = mapping[superCall];
    Expect.isNotNull(called);
    Expect.equals(fooA, called);
  });
}

Future testSwitch() {
  return MockCompiler.create((MockCompiler compiler) {
    compiler.parseScript("class Foo { foo() {"
        "switch (null) { case '': break; case 2: break; } } }");
    compiler.resolveStatement("Foo foo;");
    LibraryElement mainApp = compiler.mainApp;
    ClassElement fooElement = mainApp.find("Foo");
    MethodElement funElement = fooElement.lookupLocalMember("foo");
    compiler.enqueuer.resolution.applyImpact(new WorldImpactBuilderImpl()
      ..registerStaticUse(new StaticUse.implicitInvoke(funElement)));
    compiler.processQueue(
        compiler.enqueuer.resolution, null, compiler.libraryLoader.libraries);
    DiagnosticCollector collector = compiler.diagnosticCollector;
    Expect.equals(0, collector.warnings.length);
    Expect.equals(1, collector.errors.length);
    Expect.equals(MessageKind.SWITCH_CASE_TYPES_NOT_EQUAL,
        collector.errors.first.message.kind);
    Expect.equals(2, collector.infos.length);
    Expect.equals(MessageKind.SWITCH_CASE_TYPES_NOT_EQUAL_CASE,
        collector.infos.first.message.kind);
    Expect.equals(MessageKind.SWITCH_CASE_TYPES_NOT_EQUAL_CASE,
        collector.infos.elementAt(1).message.kind);
  });
}

Future testThis() {
  return Future.wait([
    MockCompiler.create((MockCompiler compiler) {
      compiler.parseScript("class Foo { foo() { return this; } }");
      compiler.resolveStatement("Foo foo;");
      LibraryElement mainApp = compiler.mainApp;
      ClassElement fooElement = mainApp.find("Foo");
      FunctionElement funElement = fooElement.lookupLocalMember("foo");
      ResolverVisitor visitor = new ResolverVisitor(
          compiler.resolution,
          funElement,
          new ResolutionRegistry(
              compiler.backend.target, new CollectingTreeElements(funElement)),
          scope: new MockTypeVariablesScope(fooElement.buildScope()));
      FunctionExpression function =
          (funElement as FunctionElementX).parseNode(compiler.parsingContext);
      visitor.visit(function.body);
      Map mapping = map(visitor);
      List<Element> values = mapping.values.toList();
      DiagnosticCollector collector = compiler.diagnosticCollector;
      Expect.equals(0, mapping.length);
      Expect.equals(0, collector.warnings.length);
    }),
    MockCompiler.create((MockCompiler compiler) {
      compiler.resolveStatement("main() { return this; }");
      DiagnosticCollector collector = compiler.diagnosticCollector;
      Expect.equals(0, collector.warnings.length);
      Expect.equals(1, collector.errors.length);
      Expect.equals(MessageKind.NO_INSTANCE_AVAILABLE,
          collector.errors.first.message.kind);
    }),
    MockCompiler.create((MockCompiler compiler) {
      compiler.parseScript("class Foo { static foo() { return this; } }");
      compiler.resolveStatement("Foo foo;");
      LibraryElement mainApp = compiler.mainApp;
      ClassElement fooElement = mainApp.find("Foo");
      FunctionElement funElement = fooElement.lookupLocalMember("foo");
      ResolverVisitor visitor = new ResolverVisitor(
          compiler.resolution,
          funElement,
          new ResolutionRegistry(
              compiler.backend.target, new CollectingTreeElements(funElement)),
          scope: new MockTypeVariablesScope(fooElement.buildScope()));
      FunctionExpression function =
          (funElement as FunctionElementX).parseNode(compiler.parsingContext);
      visitor.visit(function.body);
      DiagnosticCollector collector = compiler.diagnosticCollector;
      Expect.equals(0, collector.warnings.length);
      Expect.equals(1, collector.errors.length);
      Expect.equals(MessageKind.NO_INSTANCE_AVAILABLE,
          collector.errors.first.message.kind);
    }),
  ]);
}

Future testLocalsOne() {
  return Future.forEach([
    () => testLocals([
          ["foo", false]
        ]),
    () => testLocals([
          ["foo", false],
          ["bar", false]
        ]),
    () => testLocals([
          ["foo", false],
          ["bar", false],
          ["foobar", false]
        ]),
    () => testLocals([
          ["foo", true]
        ]),
    () => testLocals([
          ["foo", false],
          ["bar", true]
        ]),
    () => testLocals([
          ["foo", true],
          ["bar", true]
        ]),
    () => testLocals([
          ["foo", false],
          ["bar", false],
          ["foobar", true]
        ]),
    () => testLocals([
          ["foo", false],
          ["bar", true],
          ["foobar", true]
        ]),
    () => testLocals([
          ["foo", true],
          ["bar", true],
          ["foobar", true]
        ]),
    () => testLocals([
          ["foo", false],
          ["foo", false]
        ]).then((MockCompiler compiler) {
          DiagnosticCollector collector = compiler.diagnosticCollector;
          Expect.equals(1, collector.errors.length);
          Expect.equals(
              new Message(
                  MessageTemplate.TEMPLATES[MessageKind.DUPLICATE_DEFINITION],
                  {'name': 'foo'},
                  false),
              collector.errors.first.message);
        })
  ], (f) => f());
}

Future testLocalsTwo() {
  return MockCompiler.create((MockCompiler compiler) {
    ResolverVisitor visitor = compiler.resolverVisitor();
    Node tree = parseStatement("if (true) { var a = 1; var b = 2; }");
    ResolutionResult result = visitor.visit(tree);
    Expect.equals(const NoneResult(), result);
    MethodScope scope = visitor.scope;
    Expect.equals(0, scope.elements.length);
    Expect.equals(2, map(visitor).length);

    List<Element> elements = new List<Element>.from(map(visitor).values);
    Expect.notEquals(elements[0], elements[1]);
  });
}

Future testLocalsThree() {
  return MockCompiler.create((MockCompiler compiler) {
    ResolverVisitor visitor = compiler.resolverVisitor();
    Node tree = parseStatement("{ var a = 1; if (true) { a; } }");
    ResolutionResult result = visitor.visit(tree);
    Expect.equals(const NoneResult(), result);
    MethodScope scope = visitor.scope;
    Expect.equals(0, scope.elements.length);
    Expect.equals(2, map(visitor).length);
    List<Element> elements = map(visitor).values.toList();
    Expect.equals(elements[0], elements[1]);
  });
}

Future testLocalsFour() {
  return MockCompiler.create((MockCompiler compiler) {
    ResolverVisitor visitor = compiler.resolverVisitor();
    Node tree = parseStatement("{ var a = 1; if (true) { var a = 1; } }");
    ResolutionResult result = visitor.visit(tree);
    Expect.equals(const NoneResult(), result);
    MethodScope scope = visitor.scope;
    Expect.equals(0, scope.elements.length);
    Expect.equals(2, map(visitor).length);
    List<Element> elements = map(visitor).values.toList();
    Expect.notEquals(elements[0], elements[1]);
  });
}

Future testLocalsFive() {
  return MockCompiler.create((MockCompiler compiler) {
    ResolverVisitor visitor = compiler.resolverVisitor();
    If tree =
        parseStatement("if (true) { var a = 1; a; } else { var a = 2; a;}");
    ResolutionResult result = visitor.visit(tree);
    Expect.equals(const NoneResult(), result);
    MethodScope scope = visitor.scope;
    Expect.equals(0, scope.elements.length);
    Expect.equals(4, map(visitor).length);

    Block thenPart = tree.thenPart;
    List statements1 = thenPart.statements.nodes.toList();
    Node def1 = statements1[0].definitions.nodes.head;
    Node id1 = statements1[1].expression;
    Expect.equals(
        visitor.registry.mapping[def1], visitor.registry.mapping[id1]);

    Block elsePart = tree.elsePart;
    List statements2 = elsePart.statements.nodes.toList();
    Node def2 = statements2[0].definitions.nodes.head;
    Node id2 = statements2[1].expression;
    Expect.equals(
        visitor.registry.mapping[def2], visitor.registry.mapping[id2]);

    Expect.notEquals(
        visitor.registry.mapping[def1], visitor.registry.mapping[def2]);
    Expect.notEquals(
        visitor.registry.mapping[id1], visitor.registry.mapping[id2]);
  });
}

Future testParametersOne() {
  return MockCompiler.create((MockCompiler compiler) {
    ResolverVisitor visitor = compiler.resolverVisitor();
    FunctionExpression tree =
        parseFunction("void foo(int a) { return a; }", compiler);
    visitor.visit(tree);

    // Check that an element has been created for the parameter.
    VariableDefinitions vardef = tree.parameters.nodes.head;
    Node param = vardef.definitions.nodes.head;
    Expect.equals(ElementKind.PARAMETER, visitor.registry.mapping[param].kind);

    // Check that 'a' in 'return a' is resolved to the parameter.
    Block body = tree.body;
    Return ret = body.statements.nodes.head;
    Send use = ret.expression;
    Expect.equals(ElementKind.PARAMETER, visitor.registry.mapping[use].kind);
    Expect.equals(
        visitor.registry.mapping[param], visitor.registry.mapping[use]);
  });
}

Future testFor() {
  return MockCompiler.create((MockCompiler compiler) {
    ResolverVisitor visitor = compiler.resolverVisitor();
    For tree = parseStatement("for (int i = 0; i < 10; i = i + 1) { i = 5; }");
    visitor.visit(tree);

    MethodScope scope = visitor.scope;
    Expect.equals(0, scope.elements.length);
    Expect.equals(5, map(visitor).length);

    VariableDefinitions initializer = tree.initializer;
    Node iNode = initializer.definitions.nodes.head;
    Element iElement = visitor.registry.mapping[iNode];

    // Check that we have the expected nodes. This test relies on the mapping
    // field to be a linked hash map (preserving insertion order).
    Expect.isTrue(map(visitor) is LinkedHashMap);
    List<Node> nodes = map(visitor).keys.toList();
    List<Element> elements = map(visitor).values.toList();

    // for (int i = 0; i < 10; i = i + 1) { i = 5; };
    //          ^^^^^
    checkSendSet(iElement, nodes[0], elements[0]);

    // for (int i = 0; i < 10; i = i + 1) { i = 5; };
    //                 ^
    checkSend(iElement, nodes[1], elements[1]);

    // for (int i = 0; i < 10; i = i + 1) { i = 5; };
    //                             ^
    checkSend(iElement, nodes[2], elements[2]);

    // for (int i = 0; i < 10; i = i + 1) { i = 5; };
    //                         ^^^^^^^^^
    checkSendSet(iElement, nodes[3], elements[3]);

    // for (int i = 0; i < 10; i = i + 1) { i = 5; };
    //                                      ^^^^^
    checkSendSet(iElement, nodes[4], elements[4]);
  });
}

checkIdentifier(Element expected, Node node, Element actual) {
  Expect.isTrue(node is Identifier, node.toDebugString());
  Expect.equals(expected, actual);
}

checkSend(Element expected, Node node, Element actual) {
  Expect.isTrue(node is Send, node.toDebugString());
  Expect.isTrue(node is! SendSet, node.toDebugString());
  Expect.equals(expected, actual);
}

checkSendSet(Element expected, Node node, Element actual) {
  Expect.isTrue(node is SendSet, node.toDebugString());
  Expect.equals(expected, actual);
}

Future testTypeAnnotation() {
  return MockCompiler.create((MockCompiler compiler) {
    String statement = "Foo bar;";

    // Test that we get a warning when Foo is not defined.
    Map mapping = compiler.resolveStatement(statement).map;

    Expect.equals(1, mapping.length); // Only [bar] has an element.
    DiagnosticCollector collector = compiler.diagnosticCollector;
    Expect.equals(1, collector.warnings.length);

    Expect.equals(
        new Message(MessageTemplate.TEMPLATES[MessageKind.CANNOT_RESOLVE_TYPE],
            {'typeName': 'Foo'}, false),
        collector.warnings.first.message);
    collector.clear();

    // Test that there is no warning after defining Foo.
    compiler.parseScript("class Foo {}");
    mapping = compiler.resolveStatement(statement).map;
    Expect.equals(1, mapping.length);
    Expect.equals(0, collector.warnings.length);

    // Test that 'var' does not create a warning.
    mapping = compiler.resolveStatement("var foo;").map;
    Expect.equals(1, mapping.length);
    Expect.equals(0, collector.warnings.length);
  });
}

Future testSuperclass() {
  return Future.wait([
    MockCompiler.create((MockCompiler compiler) {
      compiler.parseScript("class Foo extends Bar {}");
      compiler.resolveStatement("Foo bar;");
      DiagnosticCollector collector = compiler.diagnosticCollector;
      Expect.equals(1, collector.errors.length);
      var cannotResolveBar = new Message(
          MessageTemplate.TEMPLATES[MessageKind.CANNOT_EXTEND_MALFORMED],
          {'className': 'Foo', 'malformedType': 'Bar'},
          false);
      Expect.equals(cannotResolveBar, collector.errors.first.message);
      collector.clear();
    }),
    MockCompiler.create((MockCompiler compiler) {
      compiler.parseScript("class Foo extends Bar {}");
      compiler.parseScript("class Bar {}");
      Map mapping = compiler.resolveStatement("Foo bar;").map;
      Expect.equals(1, mapping.length);

      LibraryElement mainApp = compiler.mainApp;
      ClassElement fooElement = mainApp.find('Foo');
      ClassElement barElement = mainApp.find('Bar');
      Expect.equals(
          barElement.computeType(compiler.resolution), fooElement.supertype);
      Expect.isTrue(fooElement.interfaces.isEmpty);
      Expect.isTrue(barElement.interfaces.isEmpty);
    }),
  ]);
}

Future testVarSuperclass() {
  return MockCompiler.create((MockCompiler compiler) {
    compiler.parseScript("class Foo extends var {}");
    compiler.resolveStatement("Foo bar;");
    DiagnosticCollector collector = compiler.diagnosticCollector;
    Expect.equals(1, collector.errors.length);
    Expect.equals(
        new Message(MessageTemplate.TEMPLATES[MessageKind.CANNOT_RESOLVE_TYPE],
            {'typeName': 'var'}, false),
        collector.errors.first.message);
    collector.clear();
  });
}

Future testOneInterface() {
  return MockCompiler.create((MockCompiler compiler) {
    compiler.parseScript("class Foo implements Bar {}");
    compiler.resolveStatement("Foo bar;");
    DiagnosticCollector collector = compiler.diagnosticCollector;
    Expect.equals(1, collector.errors.length);
    Expect.equals(
        new Message(MessageTemplate.TEMPLATES[MessageKind.CANNOT_RESOLVE_TYPE],
            {'typeName': 'bar'}, false),
        collector.errors.first.message);
    collector.clear();

    // Add the abstract class to the world and make sure everything is setup
    // correctly.
    compiler.parseScript("abstract class Bar {}");

    ResolverVisitor visitor = new ResolverVisitor(
        compiler.resolution,
        null,
        new ResolutionRegistry(
            compiler.backend.target, new CollectingTreeElements(null)));
    compiler.resolveStatement("Foo bar;");

    LibraryElement mainApp = compiler.mainApp;
    ClassElement fooElement = mainApp.find('Foo');
    ClassElement barElement = mainApp.find('Bar');

    Expect.equals(null, barElement.supertype);
    Expect.isTrue(barElement.interfaces.isEmpty);

    Expect.equals(barElement.computeType(compiler.resolution),
        fooElement.interfaces.head);
    Expect.equals(1, length(fooElement.interfaces));
  });
}

Future testTwoInterfaces() {
  return MockCompiler.create((MockCompiler compiler) {
    compiler.parseScript("""abstract class I1 {}
           abstract class I2 {}
           class C implements I1, I2 {}""");
    compiler.resolveStatement("Foo bar;");

    LibraryElement mainApp = compiler.mainApp;
    ClassElement c = mainApp.find('C');
    ClassElement i1 = mainApp.find('I1');
    ClassElement i2 = mainApp.find('I2');

    Expect.equals(2, length(c.interfaces));
    Expect.equals(i1.computeType(compiler.resolution), at(c.interfaces, 0));
    Expect.equals(i2.computeType(compiler.resolution), at(c.interfaces, 1));
  });
}

Future testFunctionExpression() {
  return MockCompiler.create((MockCompiler compiler) {
    Map mapping = compiler.resolveStatement("int f() {}").map;
    Expect.equals(2, mapping.length);
    Element element;
    Node node;
    mapping.forEach((Node n, Element e) {
      if (n is FunctionExpression) {
        element = e;
        node = n;
      }
    });
    Expect.equals(ElementKind.FUNCTION, element.kind);
    Expect.equals('f', element.name);
    Expect.equals((element as FunctionElement).node, node);
  });
}

Future testNewExpression() {
  return MockCompiler.create((MockCompiler compiler) {
    compiler.parseScript("class A {} foo() { print(new A()); }");
    LibraryElement mainApp = compiler.mainApp;
    ClassElement aElement = mainApp.find('A');

    FunctionElement fooElement = mainApp.find('foo');
    compiler.resolver.resolve(fooElement);

    Expect.isNotNull(aElement);
    Expect.isNotNull(fooElement);

    fooElement.node;
    compiler.resolver.resolve(fooElement);

    TreeElements elements = compiler.resolveStatement("new A();");
    NewExpression expression =
        compiler.parsedTree.asExpressionStatement().expression;
    Element element = elements[expression.send];
    Expect.equals(ElementKind.GENERATIVE_CONSTRUCTOR, element.kind);
    Expect.isTrue(element.isSynthesized);
  });
}

Future testTopLevelFields() {
  return MockCompiler.create((MockCompiler compiler) {
    compiler.parseScript("int a;");
    LibraryElement mainApp = compiler.mainApp;
    VariableElementX element = mainApp.find("a");
    Expect.equals(ElementKind.FIELD, element.kind);
    VariableDefinitions node =
        element.variables.parseNode(element, compiler.parsingContext);
    NominalTypeAnnotation annotation = node.type;
    Identifier typeName = annotation.typeName;
    Expect.equals(typeName.source, 'int');

    compiler.parseScript("var b, c;");
    VariableElementX bElement = mainApp.find("b");
    VariableElementX cElement = mainApp.find("c");
    Expect.equals(ElementKind.FIELD, bElement.kind);
    Expect.equals(ElementKind.FIELD, cElement.kind);
    Expect.isTrue(bElement != cElement);

    VariableDefinitions bNode =
        bElement.variables.parseNode(bElement, compiler.parsingContext);
    VariableDefinitions cNode =
        cElement.variables.parseNode(cElement, compiler.parsingContext);
    Expect.equals(bNode, cNode);
    Expect.isNull(bNode.type);
    Expect.isTrue(bNode.modifiers.isVar);
  });
}

Future resolveConstructor(String script, String statement, String className,
    String constructor, int expectedElementCount,
    {List expectedWarnings: const [],
    List expectedErrors: const [],
    List expectedInfos: const [],
    Map<String, String> corelib}) {
  MockCompiler compiler = new MockCompiler.internal(coreSource: corelib);
  return compiler.init().then((_) {
    compiler.parseScript(script);
    compiler.resolveStatement(statement);
    LibraryElement mainApp = compiler.mainApp;
    ClassElement classElement = mainApp.find(className);
    Element element;
    element = classElement.lookupConstructor(constructor);
    FunctionExpression tree = (element as FunctionElement).node;
    ResolverVisitor visitor = new ResolverVisitor(
        compiler.resolution,
        element,
        new ResolutionRegistry(
            compiler.backend.target, new CollectingTreeElements(element)),
        scope: classElement.buildScope());
    new InitializerResolver(visitor, element, tree).resolveInitializers();
    visitor.visit(tree.body);
    Expect.equals(expectedElementCount, map(visitor).length,
        "${map(visitor).values} for '$statement' in context of `$script`");

    DiagnosticCollector collector = compiler.diagnosticCollector;
    compareWarningKinds(script, expectedWarnings, collector.warnings);
    compareWarningKinds(script, expectedErrors, collector.errors);
    compareWarningKinds(script, expectedInfos, collector.infos);
  });
}

Future testClassHierarchy() {
  final MAIN = "main";
  return Future.wait([
    MockCompiler.create((MockCompiler compiler) {
      compiler.parseScript("""class A extends A {}
                              main() { return new A(); }""");
      LibraryElement mainApp = compiler.mainApp;
      FunctionElement mainElement = mainApp.find(MAIN);
      compiler.resolver.resolve(mainElement);
      DiagnosticCollector collector = compiler.diagnosticCollector;
      Expect.equals(0, collector.warnings.length);
      Expect.equals(1, collector.errors.length);
      Expect.equals(MessageKind.CYCLIC_CLASS_HIERARCHY,
          collector.errors.first.message.kind);
    }),
    MockCompiler.create((MockCompiler compiler) {
      compiler.parseScript("""class A extends B {}
                              class B extends A {}
                              main() { return new A(); }""");
      LibraryElement mainApp = compiler.mainApp;
      FunctionElement mainElement = mainApp.find(MAIN);
      compiler.resolver.resolve(mainElement);
      DiagnosticCollector collector = compiler.diagnosticCollector;
      Expect.equals(0, collector.warnings.length);
      Expect.equals(2, collector.errors.length);
      Expect.equals(MessageKind.CYCLIC_CLASS_HIERARCHY,
          collector.errors.first.message.kind);
      Expect.equals(MessageKind.CANNOT_FIND_UNNAMED_CONSTRUCTOR,
          collector.errors.elementAt(1).message.kind);
    }),
    MockCompiler.create((MockCompiler compiler) {
      compiler.parseScript("""abstract class A extends B {}
                              abstract class B extends A {}
                              class C implements A {}
                              main() { return new C(); }""");
      LibraryElement mainApp = compiler.mainApp;
      FunctionElement mainElement = mainApp.find(MAIN);
      compiler.resolver.resolve(mainElement);
      DiagnosticCollector collector = compiler.diagnosticCollector;
      Expect.equals(0, collector.warnings.length);
      Expect.equals(1, collector.errors.length);
      Expect.equals(MessageKind.CYCLIC_CLASS_HIERARCHY,
          collector.errors.first.message.kind);
    }),
    MockCompiler.create((MockCompiler compiler) {
      compiler.parseScript("""class A extends B {}
                              class B extends C {}
                              class C {}
                              main() { return new A(); }""");
      LibraryElement mainApp = compiler.mainApp;
      FunctionElement mainElement = mainApp.find(MAIN);
      compiler.resolver.resolve(mainElement);
      DiagnosticCollector collector = compiler.diagnosticCollector;
      Expect.equals(0, collector.warnings.length);
      Expect.equals(0, collector.errors.length);
      ClassElement aElement = mainApp.find("A");
      Link<InterfaceType> supertypes = aElement.allSupertypes;
      Expect.equals(<String>['B', 'C', 'Object'].toString(),
          asSortedStrings(supertypes).toString());
    }),
    MockCompiler.create((MockCompiler compiler) {
      compiler.parseScript("""class A<T> {}
                              class B<Z,W> extends A<int>
                                  implements I<Z,List<W>> {}
                              class I<X,Y> {}
                              class C extends B<bool,String> {}
                              main() { return new C(); }""");
      LibraryElement mainApp = compiler.mainApp;
      FunctionElement mainElement = mainApp.find(MAIN);
      compiler.resolver.resolve(mainElement);
      DiagnosticCollector collector = compiler.diagnosticCollector;
      Expect.equals(0, collector.warnings.length);
      Expect.equals(0, collector.errors.length);
      ClassElement aElement = mainApp.find("C");
      Link<InterfaceType> supertypes = aElement.allSupertypes;
      // Object is once per inheritance path, that is from both A and I.
      Expect.equals(
          <String>[
            'A<int>',
            'B<bool, String>',
            'I<bool, List<String>>',
            'Object'
          ].toString(),
          asSortedStrings(supertypes).toString());
    }),
    MockCompiler.create((MockCompiler compiler) {
      compiler.parseScript("""class A<T> {}
                              class D extends A<E> {}
                              class E extends D {}
                              main() { return new E(); }""");
      LibraryElement mainApp = compiler.mainApp;
      FunctionElement mainElement = mainApp.find(MAIN);
      compiler.resolver.resolve(mainElement);
      DiagnosticCollector collector = compiler.diagnosticCollector;
      Expect.equals(0, collector.warnings.length);
      Expect.equals(0, collector.errors.length);
      ClassElement aElement = mainApp.find("E");
      Link<InterfaceType> supertypes = aElement.allSupertypes;
      Expect.equals(<String>['A<E>', 'D', 'Object'].toString(),
          asSortedStrings(supertypes).toString());
    }),
    MockCompiler.create((MockCompiler compiler) {
      compiler.parseScript("""class A<T> {}
                              class D extends A<int> implements A<double> {}
                              main() { return new D(); }""");
      LibraryElement mainApp = compiler.mainApp;
      FunctionElement mainElement = mainApp.find(MAIN);
      compiler.resolver.resolve(mainElement);
      DiagnosticCollector collector = compiler.diagnosticCollector;
      Expect.equals(0, collector.warnings.length);
      Expect.equals(1, collector.errors.length);
      Expect.equals(
          MessageKind.MULTI_INHERITANCE, collector.errors.first.message.kind);
      Expect.equals(0, collector.crashes.length);
    }),
  ]);
}

Future testEnumDeclaration() {
  final MAIN = "main";
  return Future.wait([
    MockCompiler.create((MockCompiler compiler) {
      compiler.parseScript("""enum Enum {}
                              main() { Enum e; }""");
      LibraryElement mainApp = compiler.mainApp;
      FunctionElement mainElement = mainApp.find(MAIN);
      compiler.resolver.resolve(mainElement);
      DiagnosticCollector collector = compiler.diagnosticCollector;
      Expect.equals(0, collector.warnings.length,
          'Unexpected warnings: ${collector.warnings}');
      Expect.equals(
          1, collector.errors.length, 'Unexpected errors: ${collector.errors}');
    }),
    MockCompiler.create((MockCompiler compiler) {
      compiler.parseScript("""enum Enum { A }
                              main() { Enum e = Enum.A; }""");
      LibraryElement mainApp = compiler.mainApp;
      FunctionElement mainElement = mainApp.find(MAIN);
      compiler.resolver.resolve(mainElement);
      DiagnosticCollector collector = compiler.diagnosticCollector;
      Expect.equals(0, collector.warnings.length,
          'Unexpected warnings: ${collector.warnings}');
      Expect.equals(
          0, collector.errors.length, 'Unexpected errors: ${collector.errors}');
    }),
    MockCompiler.create((MockCompiler compiler) {
      compiler.parseScript("""enum Enum { A }
                              main() { Enum e = Enum.B; }""");
      LibraryElement mainApp = compiler.mainApp;
      FunctionElement mainElement = mainApp.find(MAIN);
      compiler.resolver.resolve(mainElement);
      DiagnosticCollector collector = compiler.diagnosticCollector;
      Expect.equals(1, collector.warnings.length,
          'Unexpected warnings: ${collector.warnings}');
      Expect.equals(
          MessageKind.UNDEFINED_GETTER, collector.warnings.first.message.kind);
      Expect.equals(
          0, collector.errors.length, 'Unexpected errors: ${collector.errors}');
    }),
    MockCompiler.create((MockCompiler compiler) {
      compiler.parseScript("""enum Enum { A }
                              main() { List values = Enum.values; }""");
      LibraryElement mainApp = compiler.mainApp;
      FunctionElement mainElement = mainApp.find(MAIN);
      compiler.resolver.resolve(mainElement);
      DiagnosticCollector collector = compiler.diagnosticCollector;
      Expect.equals(0, collector.warnings.length,
          'Unexpected warnings: ${collector.warnings}');
      Expect.equals(
          0, collector.errors.length, 'Unexpected errors: ${collector.errors}');
    }),
    MockCompiler.create((MockCompiler compiler) {
      compiler.parseScript("""enum Enum { A }
                              main() { new Enum(0, ''); }""");
      LibraryElement mainApp = compiler.mainApp;
      FunctionElement mainElement = mainApp.find(MAIN);
      compiler.resolver.resolve(mainElement);
      DiagnosticCollector collector = compiler.diagnosticCollector;
      Expect.equals(0, collector.warnings.length,
          'Unexpected warnings: ${collector.warnings}');
      Expect.equals(
          1, collector.errors.length, 'Unexpected errors: ${collector.errors}');
      Expect.equals(MessageKind.CANNOT_INSTANTIATE_ENUM,
          collector.errors.first.message.kind);
    }),
    MockCompiler.create((MockCompiler compiler) {
      compiler.parseScript("""enum Enum { A }
                              main() { const Enum(0, ''); }""");
      LibraryElement mainApp = compiler.mainApp;
      FunctionElement mainElement = mainApp.find(MAIN);
      compiler.resolver.resolve(mainElement);
      DiagnosticCollector collector = compiler.diagnosticCollector;
      Expect.equals(0, collector.warnings.length,
          'Unexpected warnings: ${collector.warnings}');
      Expect.equals(
          1, collector.errors.length, 'Unexpected errors: ${collector.errors}');
      Expect.equals(MessageKind.CANNOT_INSTANTIATE_ENUM,
          collector.errors.first.message.kind);
    }),
  ]);
}

Future testInitializers() {
  return Future.forEach([
    () {
      String script = """class A {
                    int foo; int bar;
                    A() : this.foo = 1, bar = 2;
                  }""";
      return resolveConstructor(script, "A a = new A();", "A", "", 2);
    },
    () {
      String script = """class A {
               int foo; A a;
               A() : a.foo = 1;
             }""";
      return resolveConstructor(script, "A a = new A();", "A", "", 0,
          expectedWarnings: [],
          expectedErrors: [MessageKind.INVALID_RECEIVER_IN_INITIALIZER]);
    },
    () {
      String script = """class A {
               int foo;
               A() : this.foo = 1, this.foo = 2;
             }""";
      return resolveConstructor(script, "A a = new A();", "A", "", 2,
          expectedInfos: [MessageKind.ALREADY_INITIALIZED],
          expectedErrors: [MessageKind.DUPLICATE_INITIALIZER]);
    },
    () {
      String script = """class A {
               A() : this.foo = 1;
             }""";
      return resolveConstructor(script, "A a = new A();", "A", "", 1,
          expectedWarnings: [], expectedErrors: [MessageKind.CANNOT_RESOLVE]);
    },
    () {
      String script = """class A {
               int foo;
               int bar;
               A() : this.foo = bar;
             }""";
      return resolveConstructor(script, "A a = new A();", "A", "", 2,
          expectedWarnings: [],
          expectedErrors: [MessageKind.NO_INSTANCE_AVAILABLE]);
    },
    () {
      String script = """class A {
               int foo() => 42;
               A() : foo();
             }""";
      return resolveConstructor(script, "A a = new A();", "A", "", 0,
          expectedWarnings: [],
          expectedErrors: [MessageKind.CONSTRUCTOR_CALL_EXPECTED]);
    },
    () {
      String script = """class A {
               int i;
               A.a() : this.b(0);
               A.b(int i);
             }""";
      return resolveConstructor(script, "A a = new A.a();", "A", "a", 1);
    },
    () {
      String script = """class A {
               int i;
               A.a() : i = 42, this(0);
               A(int i);
             }""";
      return resolveConstructor(script, "A a = new A.a();", "A", "a", 2,
          expectedWarnings: [],
          expectedErrors: [
            MessageKind.REDIRECTING_CONSTRUCTOR_HAS_INITIALIZER
          ]);
    },
    () {
      String script = """class A {
               int i;
               A(i);
             }
             class B extends A {
               B() : super(0);
             }""";
      return resolveConstructor(script, "B a = new B();", "B", "", 1);
    },
    () {
      String script = """class A {
               int i;
               A(i);
             }
             class B extends A {
               B() : super(0), super(1);
             }""";
      return resolveConstructor(script, "B b = new B();", "B", "", 2,
          expectedWarnings: [],
          expectedErrors: [MessageKind.DUPLICATE_SUPER_INITIALIZER]);
    },
    () {
      String script = "";
      final INVALID_OBJECT = const {
        'Object': 'class Object { Object() : super(); }'
      };
      return resolveConstructor(
          script, "Object o = new Object();", "Object", "", 1,
          expectedWarnings: [],
          expectedErrors: [MessageKind.SUPER_INITIALIZER_IN_OBJECT],
          corelib: INVALID_OBJECT);
    },
  ], (f) => f());
}

Future testConstantExpressions() {
  const Map<String, List<String>> testedConstants = const {
    'null': const ['null'],
    'true': const ['true'],
    '0': const ['0'],
    '0.0': const ['0.0'],
    '"foo"': const ['"foo"'],
    '#a': const ['#a'],
    '0 + 1': const ['0', '1', '0 + 1'],
    '0 * 1': const ['0', '1', '0 * 1'],
    '0 * 1 + 2': const ['0', '1', '0 * 1', '2', '0 * 1 + 2'],
    '0 + 1 * 2': const ['0', '1', '2', '1 * 2', '0 + 1 * 2'],
    '-(1)': const ['1', '-1'],
    '-(1 * 4)': const ['1', '4', '1 * 4', '-(1 * 4)'],
    'true ? 0 : 1': const ['true', '0', '1', 'true ? 0 : 1'],
    '"a" "b"': const ['"a"', '"b"', '"ab"'],
    '"a" "b" "c"': const ['"a"', '"b"', '"c"', '"bc"', r'"a${"bc"}"'],
    r'"a${0}b"': const ['"a"', '0', '"b"', r'"a${0}b"'],
    r'"a${0}b${1}"': const ['"a"', '0', '"b"', '1', '""', r'"a${0}b${1}"'],
    'true || false': const ['true', 'false', 'true || false'],
    'true && false': const ['true', 'false', 'true && false'],
    '!true': const ['true', '!true'],
    'const []': const ['const []'],
    'const <int>[]': const ['const <int>[]'],
    'const [0, 1, 2]': const ['0', '1', '2', 'const [0, 1, 2]'],
    'const <int>[0, 1, 2]': const ['0', '1', '2', 'const <int>[0, 1, 2]'],
    'const {}': const ['const {}'],
    'const <String, int>{}': const ['const <String, int>{}'],
    'const {"a": 0, "b": 1, "c": 2}': const [
      '"a"',
      '0',
      '"b"',
      '1',
      '"c"',
      '2',
      'const {"a": 0, "b": 1, "c": 2}'
    ],
    'const <String, int>{"a": 0, "b": 1, "c": 2}': const [
      '"a"',
      '0',
      '"b"',
      '1',
      '"c"',
      '2',
      'const <String, int>{"a": 0, "b": 1, "c": 2}'
    ],
  };
  return Future.forEach(testedConstants.keys, (String constant) {
    return MockCompiler.create((MockCompiler compiler) {
      CollectingTreeElements elements =
          compiler.resolveStatement("main() => $constant;");
      List<String> expectedConstants = testedConstants[constant];
      DiagnosticCollector collector = compiler.diagnosticCollector;
      Expect.equals(0, collector.warnings.length);
      Expect.equals(0, collector.errors.length);
      List<ConstantExpression> constants = elements.constants;
      String constantsText =
          '[${constants.map((c) => c.toDartText()).join(', ')}]';
      Expect.equals(
          expectedConstants.length,
          constants.length,
          "Expected ${expectedConstants.length} constants for `${constant}` "
          "found $constantsText.");
      for (int index = 0; index < expectedConstants.length; index++) {
        Expect.equals(
            expectedConstants[index],
            constants[index].toDartText(),
            "Expected ${expectedConstants} for `$constant`, "
            "found $constantsText.");
      }
    });
  });
}

map(ResolverVisitor visitor) {
  CollectingTreeElements elements = visitor.registry.mapping;
  return elements.map;
}

at(Link link, int index) => (index == 0) ? link.head : at(link.tail, index - 1);

List<String> asSortedStrings(Link link) {
  List<String> result = <String>[];
  for (; !link.isEmpty; link = link.tail) result.add(link.head.toString());
  result.sort((s1, s2) => s1.compareTo(s2));
  return result;
}

Future compileScript(String source) {
  Uri uri = new Uri(scheme: 'source');
  MockCompiler compiler = compilerFor(source, uri);
  compiler.diagnosticHandler = createHandler(compiler, source);
  return compiler.run(uri).then((_) {
    return compiler;
  });
}

checkMemberResolved(compiler, className, memberName) {
  ClassElement cls = findElement(compiler, className);
  MemberElement memberElement = cls.lookupLocalMember(memberName);
  Expect.isNotNull(memberElement);
  Expect.isTrue(compiler.resolutionWorldBuilder.isMemberUsed(memberElement));
}

testToString() {
  final script = r"class C { toString() => 'C'; } main() { '${new C()}'; }";
  asyncTest(() => compileScript(script).then((compiler) {
        checkMemberResolved(compiler, 'C', 'toString');
      }));
}

operatorName(op, isUnary) {
  return Elements.constructOperatorName(op, isUnary);
}

testIndexedOperator() {
  final script = r"""
      class C {
        operator[](ix) => ix;
        operator[]=(ix, v) {}
      }
      main() { var c = new C(); c[0]++; }""";
  asyncTest(() => compileScript(script).then((compiler) {
        checkMemberResolved(compiler, 'C', operatorName('[]', false));
        checkMemberResolved(compiler, 'C', operatorName('[]=', false));
      }));
}

testIncrementsAndDecrements() {
  final script = r"""
      class A { operator+(o)=>null; }
      class B { operator+(o)=>null; }
      class C { operator-(o)=>null; }
      class D { operator-(o)=>null; }
      main() {
        var a = new A();
        a++;
        var b = new B();
        ++b;
        var c = new C();
        c--;
        var d = new D();
        --d;
      }""";
  asyncTest(() => compileScript(script).then((compiler) {
        checkMemberResolved(compiler, 'A', operatorName('+', false));
        checkMemberResolved(compiler, 'B', operatorName('+', false));
        checkMemberResolved(compiler, 'C', operatorName('-', false));
        checkMemberResolved(compiler, 'D', operatorName('-', false));
      }));
}

testOverrideHashCodeCheck() {
  final script = r"""
      class A {
        operator==(other) => true;
      }
      class B {
        operator==(other) => true;
        get hashCode => 0;
      }
      main() {
        new A() == new B();
      }""";
  asyncTest(() => compileScript(script).then((compiler) {
        DiagnosticCollector collector = compiler.diagnosticCollector;
        Expect.equals(0, collector.warnings.length);
        Expect.equals(0, collector.infos.length);
        Expect.equals(1, collector.hints.length);
        Expect.equals(MessageKind.OVERRIDE_EQUALS_NOT_HASH_CODE,
            collector.hints.first.message.kind);
        Expect.equals(0, collector.errors.length);
      }));
}

testConstConstructorAndNonFinalFields() {
  void expect(compiler, List errors, List infos) {
    DiagnosticCollector collector = compiler.diagnosticCollector;
    Expect.equals(errors.length, collector.errors.length);
    for (int i = 0; i < errors.length; i++) {
      Expect.equals(errors[i], collector.errors.elementAt(i).message.kind);
    }
    Expect.equals(0, collector.warnings.length);
    Expect.equals(infos.length, collector.infos.length);
    for (int i = 0; i < infos.length; i++) {
      Expect.equals(infos[i], collector.infos.elementAt(i).message.kind);
    }
  }

  final script1 = r"""
      class A {
        var a;
        const A(this.a);
      }
      main() {
        new A(0);
      }""";
  asyncTest(() => compileScript(script1).then((compiler) {
        expect(compiler, [MessageKind.CONST_CONSTRUCTOR_WITH_NONFINAL_FIELDS],
            [MessageKind.CONST_CONSTRUCTOR_WITH_NONFINAL_FIELDS_FIELD]);
      }));

  final script2 = r"""
      class A {
        var a;
        var b;
        const A(this.a, this.b);
        const A.named(this.a, this.b);
      }
      main() {
        new A(0, 1);
      }""";
  asyncTest(() => compileScript(script2).then((compiler) {
        expect(compiler, [
          MessageKind.CONST_CONSTRUCTOR_WITH_NONFINAL_FIELDS
        ], [
          MessageKind.CONST_CONSTRUCTOR_WITH_NONFINAL_FIELDS_CONSTRUCTOR,
          MessageKind.CONST_CONSTRUCTOR_WITH_NONFINAL_FIELDS_CONSTRUCTOR,
          MessageKind.CONST_CONSTRUCTOR_WITH_NONFINAL_FIELDS_FIELD,
          MessageKind.CONST_CONSTRUCTOR_WITH_NONFINAL_FIELDS_FIELD
        ]);
      }));
}

testCantAssignMethods() {
  // Can't override local functions
  checkWarningOn(
      '''
      main() {
        mname() { mname = 2; };
        mname();
      }
      ''',
      [MessageKind.ASSIGNING_METHOD]);

  checkWarningOn(
      '''
      main() {
        mname() { };
        mname = 3;
      }
      ''',
      [MessageKind.ASSIGNING_METHOD]);

  // Can't override top-level functions
  checkWarningOn(
      '''
      m() {}
      main() { m = 4; }
      ''',
      [
        MessageKind.ASSIGNING_METHOD,
        // TODO(johnniwinther): Avoid duplicate warnings.
        MessageKind.NOT_ASSIGNABLE
      ]);

  // Can't override instance methods
  checkWarningOn(
      '''
      main() { new B().bar(); }
      class B {
        mname() {}
        bar() {
          mname = () => null;
        }
      }
      ''',
      [MessageKind.UNDEFINED_SETTER]);
  checkWarningOn(
      '''
      main() { new B().bar(); }
      class B {
        mname() {}
        bar() {
          this.mname = () => null;
        }
      }
      ''',
      [MessageKind.UNDEFINED_SETTER]);

  // Can't override super methods
  checkWarningOn(
      '''
      main() { new B().bar(); }
      class A {
        mname() {}
      }
      class B extends A {
        bar() {
          super.mname = () => 6;
        }
      }
      ''',
      [
        MessageKind.ASSIGNING_METHOD_IN_SUPER,
        // TODO(johnniwinther): Avoid duplicate warnings.
        MessageKind.UNDEFINED_SETTER
      ]);

  // But index operators should be OK
  checkWarningOn(
      '''
      main() { new B().bar(); }
      class B {
        operator[]=(x, y) {}
        bar() {
          this[1] = 3; // This is OK
        }
      }
      ''',
      []);
  checkWarningOn(
      '''
      main() { new B().bar(); }
      class A {
        operator[]=(x, y) {}
      }
      class B extends A {
        bar() {
          super[1] = 3; // This is OK
        }
      }
      ''',
      []);
}

testCantAssignFinalAndConsts() {
  // Can't write final or const locals.
  checkWarningOn(
      '''
      main() {
        final x = 1;
        x = 2;
      }
      ''',
      [MessageKind.UNDEFINED_STATIC_SETTER_BUT_GETTER]);
  checkWarningOn(
      '''
      main() {
        const x = 1;
        x = 2;
      }
      ''',
      [MessageKind.UNDEFINED_STATIC_SETTER_BUT_GETTER]);
  checkWarningOn(
      '''
      final x = 1;
      main() { x = 3; }
      ''',
      [MessageKind.UNDEFINED_STATIC_SETTER_BUT_GETTER]);

  checkWarningOn(
      '''
      const x = 1;
      main() { x = 3; }
      ''',
      [MessageKind.UNDEFINED_STATIC_SETTER_BUT_GETTER]);

  // Detect assignments to final fields:
  checkWarningOn(
      '''
      main() => new B().m();
      class B {
        final x = 1;
        m() { x = 2; }
      }
      ''',
      [MessageKind.UNDEFINED_SETTER]);

  // ... even if 'this' is explicit:
  checkWarningOn(
      '''
      main() => new B().m();
      class B {
        final x = 1;
        m() { this.x = 2; }
      }
      ''',
      [MessageKind.UNDEFINED_SETTER]);

  // ... and in super class:
  checkWarningOn(
      '''
      main() => new B().m();
      class A {
        final x = 1;
      }
      class B extends A {
        m() { super.x = 2; }
      }
      ''',
      [
        MessageKind.ASSIGNING_FINAL_FIELD_IN_SUPER,
        // TODO(johnniwinther): Avoid duplicate warnings.
        MessageKind.UNDEFINED_SETTER
      ]);

  // But non-final fields are OK:
  checkWarningOn(
      '''
      main() => new B().m();
      class A {
        int x = 1;
      }
      class B extends A {
        m() { super.x = 2; }
      }
      ''',
      []);

  // Check getter without setter.
  checkWarningOn(
      '''
      main() => new B().m();
      class A {
        get x => 1;
      }
      class B extends A {
        m() { super.x = 2; }
      }
      ''',
      [
        MessageKind.UNDEFINED_SUPER_SETTER,
        // TODO(johnniwinther): Avoid duplicate warnings.
        MessageKind.UNDEFINED_SETTER
      ]);
}

/// Helper to test that [script] produces all the given [warnings].
checkWarningOn(String script, List<MessageKind> warnings) {
  Expect.isTrue(warnings.length >= 0 && warnings.length <= 2);
  asyncTest(() => compileScript(script).then((compiler) {
        DiagnosticCollector collector = compiler.diagnosticCollector;
        Expect.equals(0, collector.errors.length,
            'Unexpected errors in\n$script\n${collector.errors}');
        Expect.equals(
            warnings.length,
            collector.warnings.length,
            'Unexpected warnings in\n$script\n'
            'Expected:$warnings\nFound:${collector.warnings}');
        for (int i = 0; i < warnings.length; i++) {
          Expect.equals(
              warnings[i], collector.warnings.elementAt(i).message.kind);
        }
      }));
}

testAwaitHint() {
  check(String script, {String className, String functionName}) {
    var prefix = className == null
        ? "Cannot resolve 'await'"
        : "No member named 'await' in class '$className'";
    var where =
        functionName == null ? 'the enclosing function' : "'$functionName'";
    asyncTest(() => compileScript(script).then((compiler) {
          DiagnosticCollector collector = compiler.diagnosticCollector;
          Expect.equals(0, collector.errors.length);
          Expect.equals(1, collector.warnings.length);
          Expect.equals(
              "$prefix.\n"
              "Did you mean to add the 'async' marker to $where?",
              '${collector.warnings.first.message}');
        }));
  }

  check('main() { await -3; }', functionName: 'main');
  check('main() { () => await -3; }');
  check('foo() => await -3; main() => foo();', functionName: 'foo');
  check(
      '''
    class A {
      m() => await - 3;
    }
    main() => new A().m();
  ''',
      className: 'A',
      functionName: 'm');
  check(
      '''
    class A {
      static m() => await - 3;
    }
    main() => A.m();
  ''',
      functionName: 'm');
  check(
      '''
    class A {
      m() => () => await - 3;
    }
    main() => new A().m();
  ''',
      className: 'A');
}
