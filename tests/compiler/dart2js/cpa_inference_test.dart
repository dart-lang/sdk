// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import "dart:uri";
import "../../../sdk/lib/_internal/compiler/implementation/elements/elements.dart";
import '../../../sdk/lib/_internal/compiler/implementation/scanner/scannerlib.dart';
import '../../../sdk/lib/_internal/compiler/implementation/source_file.dart';
import '../../../sdk/lib/_internal/compiler/implementation/types/types.dart';
import '../../../sdk/lib/_internal/compiler/implementation/tree/tree.dart';
import "../../../sdk/lib/_internal/compiler/implementation/dart2jslib.dart" as leg;

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
  BaseType num;
  BaseType bool;
  BaseType string;
  BaseType list;
  BaseType map;
  BaseType nullType;

  AnalysisResult(MockCompiler compiler) : this.compiler = compiler {
    inferrer = compiler.typesTask.concreteTypesInferrer;
    int = inferrer.baseTypes.intBaseType;
    double = inferrer.baseTypes.doubleBaseType;
    num = inferrer.baseTypes.numBaseType;
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
   * Checks that the inferred type of the node corresponding to the last
   * occurence of [: variable; :] in the program is the unknown concrete type.
   */
  void checkNodeHasUnknownType(String variable) {
    return Expect.isTrue(inferrer.inferredTypes[findNode(variable)].isUnkown());
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

  /**
   * Checks that [: className#fieldName :]'s inferred type is the unknown
   * concrete type.
   */
  void checkFieldHasUknownType(String className, String fieldName) {
    return Expect.isTrue(
        inferrer.inferredFieldTypes[findField(className, fieldName)]
                .isUnkown());
  }
}

const String CORELIB = r'''
  print(var obj) {}
  abstract class num { operator +(x); operator *(x); operator -(x); }
  abstract class int extends num { }
  abstract class double extends num { }
  class bool {}
  class String {}
  class Object {}
  class Function {}
  abstract class List {}
  abstract class Map {}
  class Closure {}
  class Null {}
  class Type {}
  class Dynamic_ {}
  bool identical(Object a, Object b) {}''';

AnalysisResult analyze(String code) {
  Uri uri = new Uri.fromComponents(scheme: 'source');
  MockCompiler compiler = new MockCompiler(coreSource: CORELIB,
                                           enableConcreteTypeInference: true);
  compiler.sourceFiles[uri.toString()] = new SourceFile(uri.toString(), code);
  compiler.typesTask.concreteTypesInferrer.testMode = true;
  compiler.runCompiler(uri);
  return new AnalysisResult(compiler);
}

testDynamicBackDoor() {
  final String source = r"""
    main () {
      var x = "__dynamic_for_test";
      x;
    }
    """;
  AnalysisResult result = analyze(source);
  result.checkNodeHasUnknownType('x');
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

testToplevelVariable() {
  final String source = r"""
      final top = 'abc';
      main() { var foo = top; foo; }
      """;
  AnalysisResult result = analyze(source);
  result.checkNodeHasType('foo', [result.string]);
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

testSimpleSend() {
  final String source = r"""
      class A {
        f(x) => x;
      }
      class B {
        f(x) => 'abc';
      }
      class C {
        f(x) => 3.14;
      }
      class D {
        var f;  // we check that this field is ignored in calls to dynamic.f() 
        D(this.f);
      }
      main() {
        new B(); new D(42); // we instantiate B and D but not C
        var foo = new A().f(42);
        var bar = "__dynamic_for_test".f(42);
        foo; bar;
      }
      """;
  AnalysisResult result = analyze(source);
  result.checkNodeHasType('foo', [result.int]);
  result.checkNodeHasType('bar', [result.int, result.string]);
}

testSendToClosureField() {
  final String source = r"""
      f(x) => x;
      class A {
        var g;
        A(this.g);
      }
      main() {
        var foo = new A(f).g(42);
        foo;
      }
      """;
  AnalysisResult result = analyze(source);
  result.checkNodeHasType('foo', [result.int]);
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
        get z => y;
      }
      class B {
        var x;
        B(this.x);
      }
      main() {
        var a = new A(42);
        var b = new B('abc');
        var foo = a.x;
        var bar = a.y;
        var baz = a.z;
        var qux = null.x;
        var quux = "__dynamic_for_test".x;
        foo; bar; baz; qux; quux;
      }
      """;
  AnalysisResult result = analyze(source);
  result.checkNodeHasType('foo', [result.int]);
  result.checkNodeHasType('bar', [result.int]);
  result.checkNodeHasType('baz', [result.int]);
  result.checkNodeHasType('qux', []);
  result.checkNodeHasType('quux', [result.int, result.string]);
}

testSetters() {
  final String source = r"""
      class A {
        var x;
        var w;
        A(this.x, this.w);
        set y(a) { x = a; z = a; }
        set z(a) { w = a; }
      }
      class B {
        var x;
        B(this.x);
      }
      main() {
        var a = new A(42, 42);
        var b = new B(42);
        a.x = 'abc';
        a.y = true;
        null.x = 42;  // should be ignored
        "__dynamic_for_test".x = null;
        "__dynamic_for_test".y = 3.14;
      }
      """;
  AnalysisResult result = analyze(source);
  result.checkFieldHasType('B', 'x',
                           [result.int,         // new B(42)
                            result.nullType]);  // dynamic.x = null
  result.checkFieldHasType('A', 'x',
                           [result.int,       // new A(42, ...)
                            result.string,    // a.x = 'abc'
                            result.bool,      // a.y = true
                            result.nullType,  // dynamic.x = null
                            result.double]);  // dynamic.y = 3.14
  result.checkFieldHasType('A', 'w',
                           [result.int,       // new A(..., 42)
                            result.bool,      // a.y = true
                            result.double]);  // dynamic.y = double
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

testArithmeticOperators() {
  String source(op) {
    return """
        main() {
          var a = 1 $op 2;
          var b = 1 $op 2.0;
          var c = 1.0 $op 2;
          var d = 1.0 $op 2.0;
          var e = (1 $op 2.0) $op 1;
          var f = 1 $op (1 $op 2.0);
          var g = (1 $op 2.0) $op 1.0;
          var h = 1.0 $op (1 $op 2);
          var i = (1 $op 2) $op 1;
          var j = 1 $op (1 $op 2);
          var k = (1.0 $op 2.0) $op 1.0;
          var l = 1.0 $op (1.0 $op 2.0);
          a; b; c; d; e; f; g; h; i; j; k; l;
        }""";
  }
  for (String op in ['+', '*', '-']) {
    AnalysisResult result = analyze(source(op));
    result.checkNodeHasType('a', [result.int]);
    result.checkNodeHasType('b', [result.num]);
    result.checkNodeHasType('c', [result.num]);
    result.checkNodeHasType('d', [result.double]);
    result.checkNodeHasType('e', [result.num]);
    result.checkNodeHasType('f', [result.num]);
    result.checkNodeHasType('g', [result.num]);
    result.checkNodeHasType('h', [result.num]);
    result.checkNodeHasType('i', [result.int]);
    result.checkNodeHasType('j', [result.int]);
    result.checkNodeHasType('k', [result.double]);
    result.checkNodeHasType('l', [result.double]);
  }
}

testOperators() {
  final String source = r"""
      class A {
        operator <(x) => 42;
        operator <<(x) => "a";
      }
      main() {
        var x = new A() < "foo";
        var y = new A() << "foo";
        x; y;
      }
      """;
  AnalysisResult result = analyze(source);
  result.checkNodeHasType('x', [result.int]);
  result.checkNodeHasType('y', [result.string]);
}

testCompoundOperators1() {
  final String source = r"""
      class A {
        operator +(x) => "foo";
      }
      main() {
        var x1 = 1; x1++;
        var x2 = 1; ++x2;
        var x3 = new A(); x3++;
        var x4 = new A(); ++x4;

        x1; x2; x3; x4;
      }
      """;
  AnalysisResult result = analyze(source);
  result.checkNodeHasType('x1', [result.int]);
  result.checkNodeHasType('x2', [result.int]);
  result.checkNodeHasType('x3', [result.string]);
  result.checkNodeHasType('x4', [result.string]);
}


testCompoundOperators2() {
  final String source = r"""
    class A {
      var xx;
      var witness1;
      var witness2;

      A(this.xx);
      get x { witness1 = "foo"; return xx; }
      set x(y) { witness2 = "foo"; xx = y; }
    }
    main () {
      var a = new A(1);
      a.x++;
    }
    """;
  AnalysisResult result = analyze(source);
  result.checkFieldHasType('A', 'xx', [result.int]);
  // TODO(polux): the two following results should be {null, string}, see
  // fieldInitialization().
  result.checkFieldHasType('A', 'witness1', [result.string]);
  result.checkFieldHasType('A', 'witness2', [result.string]);
}

testFieldInitialization() {
  final String source = r"""
    class A {
      var x;
      var y = 1;
    }
    main () {
      new A();
    }
    """;
  AnalysisResult result = analyze(source);
  result.checkFieldHasType('A', 'x', [result.nullType]);
  result.checkFieldHasType('A', 'y', [result.int]);
}

testSendWithWrongArity() {
  final String source = r"""
    f(x) { }
    class A { g(x) { } }
    main () {
      var x = f();
      var y = f(1, 2);
      var z = new A().g();
      var w = new A().g(1, 2);
      x; y; z; w;
    }
    """;
  AnalysisResult result = analyze(source);
  result.checkNodeHasType('x', []);
  result.checkNodeHasType('y', []);
  result.checkNodeHasType('z', []);
  result.checkNodeHasType('w', []);
}

testDynamicIsAbsorbing() {
  final String source = r"""
    main () {
      var x = 1;
      if (true) {
        x = "__dynamic_for_test";
      } else {
        x = 42;
      }
      x;
    }
    """;
  AnalysisResult result = analyze(source);
  result.checkNodeHasUnknownType('x');
}

void main() {
  testDynamicBackDoor();
  testLiterals();
  testRedefinition();
  testIfThenElse();
  testTernaryIf();
  testWhile();
  testFor1();
  testFor2();
  // testToplevelVariable();  // toplevel variables are not yet supported
  testNonRecusiveFunction();
  testRecusiveFunction();
  testMutuallyRecusiveFunction();
  testSimpleSend();
  // testSendToClosureField();  // closures are not yet supported
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
  testArithmeticOperators();
  testOperators();
  testCompoundOperators1();
  testCompoundOperators2();
  // testFieldInitialization(); // TODO(polux)
  testSendWithWrongArity();
  testDynamicIsAbsorbing();
}
