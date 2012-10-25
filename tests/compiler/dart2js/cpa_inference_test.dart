// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import "dart:uri";
import "../../../lib/compiler/implementation/elements/elements.dart";
import '../../../lib/compiler/implementation/scanner/scannerlib.dart';
import '../../../lib/compiler/implementation/source_file.dart';
import '../../../lib/compiler/implementation/types/types.dart';
import '../../../lib/compiler/implementation/tree/tree.dart';
import "../../../lib/compiler/implementation/dart2jslib.dart" as leg;

import "parser_helper.dart";
import "compiler_helper.dart";
import "mock_compiler.dart";

/**
 * Finds the node corresponding to the last occurence of the substring
 * [: identifier; :] in the program represented by the visited AST.
 */
class VariableFinderVisitor extends Visitor {
  final String identifier;
  Node result;

  VariableFinderVisitor(this.identifier);

  visitSend(Send node) {
    if (node.isPropertyAccess
        && node.selector.asIdentifier().source.slowToString() == identifier) {
      result = node;
    } else {
      node.visitChildren(this);
    }
  }

  visitNode(Node node) {
    node.visitChildren(this);
  }
}

class AnalysisResult {
  MockCompiler compiler;
  ConcreteTypesInferrer inferrer;
  Node ast;

  BaseType int;
  BaseType double;
  BaseType bool;
  BaseType string;
  BaseType list;
  BaseType map;
  BaseType nullType;

  AnalysisResult(MockCompiler compiler) : this.compiler = compiler {
    inferrer = compiler.typesTask.concreteTypesInferrer;
    int = inferrer.baseTypes.intBaseType;
    double = inferrer.baseTypes.doubleBaseType;
    bool = inferrer.baseTypes.boolBaseType;
    string = inferrer.baseTypes.stringBaseType;
    list = inferrer.baseTypes.listBaseType;
    map = inferrer.baseTypes.mapBaseType;
    nullType = new NullBaseType();
    Element mainElement = compiler.mainApp.find(buildSourceString('main'));
    ast = mainElement.parseNode(compiler);
  }

  BaseType base(String className) {
    final source = buildSourceString(className);
    return new ClassBaseType(compiler.mainApp.find(source));
  }

  /**
   * Finds the [Node] corresponding to the last occurence of the substring
   * [: identifier; :] in the program represented by the visited AST. For
   * instance, returns the AST node representing [: foo; :] in
   * [: main() { foo = 1; foo; } :].
   */
  Node findNode(String identifier) {
    VariableFinderVisitor finder = new VariableFinderVisitor(identifier);
    ast.accept(finder);
    return finder.result;
  }

  /**
   * Finds the [Element] corresponding to [: className#fieldName :].
   */
  Element findField(String className, String fieldName) {
    ClassElement element = compiler.mainApp.find(buildSourceString(className));
    return element.lookupLocalMember(buildSourceString(fieldName));
  }

  static ConcreteType concreteFrom(List<BaseType> baseTypes) {
    ConcreteType result = new ConcreteType.empty();
    for (final baseType in baseTypes) {
      result = result.union(new ConcreteType.singleton(baseType));
    }
    return result;
  }

  /**
   * Checks that the inferred type of the node corresponding to the last
   * occurence of [: variable; :] in the program is the concrete type
   * made of [baseTypes].
   */
  void checkNodeHasType(String variable, List<BaseType> baseTypes) {
    return Expect.equals(
        concreteFrom(baseTypes),
        inferrer.inferredTypes[findNode(variable)]);
  }

  /**
   * Checks that [: className#fieldName :]'s inferred type is the concrete type
   * made of [baseTypes].
   */
  void checkFieldHasType(String className, String fieldName,
                         List<BaseType> baseTypes) {
    return Expect.equals(
        concreteFrom(baseTypes),
        inferrer.inferredFieldTypes[findField(className, fieldName)]);
  }
}

AnalysisResult analyze(String code) {
  Uri uri = new Uri.fromComponents(scheme: 'source');
  MockCompiler compiler = new MockCompiler(enableConcreteTypeInference: true);
  compiler.sourceFiles[uri.toString()] = new SourceFile(uri.toString(), code);
  compiler.runCompiler(uri);
  return new AnalysisResult(compiler);
}

testLiterals() {
  final String source = r"""
      main() {
        var v1 = 42;
        var v2 = 42.0;
        var v3 = 'abc';
        var v4 = true;
        var v5 = null;
        v1; v2; v3; v4; v5;
      }
      """;
  AnalysisResult result = analyze(source);
  result.checkNodeHasType('v1', [result.int]);
  result.checkNodeHasType('v2', [result.double]);
  result.checkNodeHasType('v3', [result.string]);
  result.checkNodeHasType('v4', [result.bool]);
  result.checkNodeHasType('v5', [new NullBaseType()]);
}

testRedefinition() {
  final String source = r"""
      main() {
        var foo = 42;
        foo = 'abc';
        foo;
      }
      """;
  AnalysisResult result = analyze(source);
  result.checkNodeHasType('foo', [result.string]);
}

testIfThenElse() {
  final String source = r"""
      main() {
        var foo = 42;
        if (true) {
          foo = 'abc';
        } else {
          foo = false;
        }
        foo;
      }
      """;
  AnalysisResult result = analyze(source);
  result.checkNodeHasType('foo', [result.string, result.bool]);
}

testTernaryIf() {
  final String source = r"""
      main() {
        var foo = 42;
        foo = true ? 'abc' : false;
        foo;
      }
      """;
  AnalysisResult result = analyze(source);
  result.checkNodeHasType('foo', [result.string, result.bool]);
}

testWhile() {
  final String source = r"""
      class A { f() => new B(); }
      class B { f() => new C(); }
      class C { f() => new A(); }
      main() {
        var bar = null;
        var foo = new A();
        while(bar = 42) {
          foo = foo.f();
        }
        foo; bar;
      }
      """;
  AnalysisResult result = analyze(source);
  result.checkNodeHasType(
      'foo',
      [result.base('A'), result.base('B'), result.base('C')]);
  // Check that the condition is evaluated.
  result.checkNodeHasType('bar', [result.int]);
}

testFor1() {
  final String source = r"""
      class A { f() => new B(); }
      class B { f() => new C(); }
      class C { f() => new A(); }
      main() {
        var foo = new A();
        for(;;) {
          foo = foo.f();
        }
        foo;
      }
      """;
  AnalysisResult result = analyze(source);
  result.checkNodeHasType(
      'foo',
      [result.base('A'), result.base('B'), result.base('C')]);
}

testFor2() {
  final String source = r"""
      class A { f() => new B(); test() => true; }
      class B { f() => new A(); test() => true; }
      main() {
        var bar = null;
        var foo = new A();
        for(var i = new A(); bar = 42; i = i.f()) {
           foo = i;
        }
        foo; bar;
      }
      """;
  AnalysisResult result = analyze(source);
  result.checkNodeHasType('foo', [result.base('A'), result.base('B')]);
  // Check that the condition is evaluated.
  result.checkNodeHasType('bar', [result.int]);
}

testNonRecusiveFunction() {
  final String source = r"""
      f(x, y) => true ? x : y;
      main() { var foo = f(42, "abc"); foo; }
      """;
  AnalysisResult result = analyze(source);
  result.checkNodeHasType('foo', [result.int, result.string]);
}

testRecusiveFunction() {
  final String source = r"""
      f(x) {
        if (true) return x;
        else return f(true ? x : "abc");
      }
      main() { var foo = f(42); foo; }
      """;
  AnalysisResult result = analyze(source);
  result.checkNodeHasType('foo', [result.int, result.string]);
}

testMutuallyRecusiveFunction() {
  final String source = r"""
      f() => true ? 42 : g();
      g() => true ? "abc" : f(); 
      main() { var foo = f(); foo; }
      """;
  AnalysisResult result = analyze(source);
  result.checkNodeHasType('foo', [result.int, result.string]);
}

testSendToThis1() {
  final String source = r"""
      class A {
        A();
        f() => g();
        g() => 42;
      }
      main() {
        var foo = new A().f();
        foo;
      }
      """;
  AnalysisResult result = analyze(source);
  result.checkNodeHasType('foo', [result.int]);
}

testSendToThis2() {
  final String source = r"""
      class A {
        foo() => this;
      }
      class B extends A {
        bar() => foo();
      }
      main() {
        var x = new B().bar();
        x;
      }
      """;
  AnalysisResult result = analyze(source);
  result.checkNodeHasType('x', [result.base('B')]);
}

testConstructor() {
  final String source = r"""
      class A {
        var x, y, z;
        A(this.x, a) : y = a { z = 'abc'; }
      }
      main() {
        new A(42, 'abc');
        new A(true, null);
      }
      """;
  AnalysisResult result = analyze(source);
  result.checkFieldHasType('A', 'x', [result.int, result.bool]);
  result.checkFieldHasType('A', 'y', [result.string, new NullBaseType()]);
  result.checkFieldHasType('A', 'z', [result.string]);
}

testGetters() {
  final String source = r"""
      class A {
        var x;
        A(this.x);
        get y => x;
      }
      main() {
        var a = new A(42);
        var foo = a.x;
        var bar = a.y;
        foo; bar;
      }
      """;
  AnalysisResult result = analyze(source);
  result.checkNodeHasType('foo', [result.int]);
  result.checkNodeHasType('bar', [result.int]);
}

testSetters() {
  final String source = r"""
      class A {
        var x;
        A(this.x);
        set y(a) { x = a; }
      }
      main() {
        var a = new A(42);
        a.x = 'abc';
        a.y = true;
      }
      """;
  AnalysisResult result = analyze(source);
  result.checkFieldHasType('A', 'x', [result.int, result.string, result.bool]);
}

testNamedParameters() {
  final String source = r"""
      class A {
        var x, y, z, w;
        A(this.x, {this.y, this.z, this.w});
      }
      main() {
        new A(42);
        new A('abc', w: true, z: 42.0);
      }
      """;
  AnalysisResult result = analyze(source);
  result.checkFieldHasType('A', 'x', [result.int, result.string]);
  result.checkFieldHasType('A', 'y', [new NullBaseType()]);
  result.checkFieldHasType('A', 'z', [new NullBaseType(), result.double]);
  result.checkFieldHasType('A', 'w', [new NullBaseType(), result.bool]);
}

testListLiterals() {
  final String source = r"""
      class A {
        var x;
        A(this.x);
      }
      main() {
        var x = [];
        var y = [1, "a", null, new A(42)];
        x; y;
      }
      """;
  AnalysisResult result = analyze(source);
  result.checkNodeHasType('x', [result.list]);
  result.checkNodeHasType('y', [result.list]);
  result.checkFieldHasType('A', 'x', [result.int]);
}

testMapLiterals() {
  final String source = r"""
      class A {
        var x;
        A(this.x);
      }
      main() {
        var x = {};
        var y = {'a': "foo", 'b': new A(42) };
        x; y;
      }
      """;
  AnalysisResult result = analyze(source);
  result.checkNodeHasType('x', [result.map]);
  result.checkNodeHasType('y', [result.map]);
  result.checkFieldHasType('A', 'x', [result.int]);
}

testReturn() {
  final String source = r"""
      f() { if (true) { return 1; }; return "a"; }
      g() { f(); return; }
      main() {
        var x = f();
        var y = g();
        x; y;
      }
      """;
  AnalysisResult result = analyze(source);
  result.checkNodeHasType('x', [result.int, result.string]);
  result.checkNodeHasType('y', [result.nullType]);
}

testNoReturn() {
  final String source = r"""
      f() { if (true) { return 1; }; }
      g() { f(); }
      main() {
        var x = f();
        var y = g();
        x; y;
      }
      """;
  AnalysisResult result = analyze(source);
  result.checkNodeHasType('x', [result.int, result.nullType]);
  result.checkNodeHasType('y', [result.nullType]);
}

void main() {
  testLiterals();
  testRedefinition();
  testIfThenElse();
  testTernaryIf();
  testWhile();
  testFor1();
  testFor2();
  testNonRecusiveFunction();
  testRecusiveFunction();
  testMutuallyRecusiveFunction();
  testSendToThis1();
  testSendToThis2();
  testConstructor();
  testGetters();
  testSetters();
  testNamedParameters();
  testListLiterals();
  testMapLiterals();
  testReturn();
  // testNoReturn(); // right now we infer the empty type instead of null
}
