// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';
import "package:expect/expect.dart";
import "package:async_helper/async_helper.dart";
import 'package:compiler/implementation/source_file.dart';
import 'package:compiler/implementation/types/types.dart';
import 'package:compiler/implementation/inferrer/concrete_types_inferrer.dart';

import "parser_helper.dart";
import "compiler_helper.dart";
import "type_mask_test_helper.dart";
import 'dart:mirrors';

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
        && node.selector.asIdentifier().source == identifier) {
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
  BaseType growableList;
  BaseType map;
  BaseType nullType;
  BaseType functionType;

  AnalysisResult(MockCompiler compiler) : this.compiler = compiler {
    inferrer = compiler.typesTask.concreteTypesInferrer;
    int = inferrer.baseTypes.intBaseType;
    double = inferrer.baseTypes.doubleBaseType;
    num = inferrer.baseTypes.numBaseType;
    bool = inferrer.baseTypes.boolBaseType;
    string = inferrer.baseTypes.stringBaseType;
    list = inferrer.baseTypes.listBaseType;
    growableList = inferrer.baseTypes.growableListBaseType;
    map = inferrer.baseTypes.mapBaseType;
    nullType = const NullBaseType();
    functionType = inferrer.baseTypes.functionBaseType;
    Element mainElement = compiler.mainApp.find('main');
    ast = mainElement.parseNode(compiler);
  }

  BaseType base(String className) {
    final source = className;
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
    ClassElement element = compiler.mainApp.find(className);
    return element.lookupLocalMember(fieldName);
  }

  ConcreteType concreteFrom(List<BaseType> baseTypes) {
    ConcreteType result = inferrer.emptyConcreteType;
    for (final baseType in baseTypes) {
      result = result.union(inferrer.singletonConcreteType(baseType));
    }
    // We make sure the concrete types expected by the tests don't default to
    // dynamic because of widening.
    assert(!result.isUnknown());
    return result;
  }

  /**
   * Checks that the inferred type of the node corresponding to the last
   * occurence of [: variable; :] in the program is the concrete type
   * made of [baseTypes].
   */
  void checkNodeHasType(String variable, List<BaseType> baseTypes) {
    Expect.equals(
        concreteFrom(baseTypes),
        inferrer.inferredTypes[findNode(variable)]);
  }

  /**
   * Checks that the inferred type of the node corresponding to the last
   * occurence of [: variable; :] in the program is the unknown concrete type.
   */
  void checkNodeHasUnknownType(String variable) {
    Expect.isTrue(inferrer.inferredTypes[findNode(variable)].isUnknown());
  }

  /**
   * Checks that [: className#fieldName :]'s inferred type is the concrete type
   * made of [baseTypes].
   */
  void checkFieldHasType(String className, String fieldName,
                         List<BaseType> baseTypes) {
    Expect.equals(
        concreteFrom(baseTypes),
        inferrer.inferredFieldTypes[findField(className, fieldName)]);
  }

  /**
   * Checks that [: className#fieldName :]'s inferred type is the unknown
   * concrete type.
   */
  void checkFieldHasUknownType(String className, String fieldName) {
    Expect.isTrue(
        inferrer.inferredFieldTypes[findField(className, fieldName)]
                .isUnknown());
  }

  /** Checks that the inferred type for [selector] is [mask]. */
  void checkSelectorHasType(Selector selector, TypeMask mask) {
    Expect.equals(mask, inferrer.getTypeOfSelector(selector));
  }
}

const String DYNAMIC = '"__dynamic_for_test"';

Future<AnalysisResult> analyze(String code, {int maxConcreteTypeSize: 1000}) {
  Uri uri = new Uri(scheme: 'dart', path: 'test');
  MockCompiler compiler = new MockCompiler.internal(
      enableConcreteTypeInference: true,
      maxConcreteTypeSize: maxConcreteTypeSize);
  compiler.registerSource(uri, code);
  compiler.typesTask.concreteTypesInferrer.testMode = true;
  return compiler.runCompiler(uri).then((_) {
    return new AnalysisResult(compiler);
  });
}

testDynamicBackDoor() {
  final String source = """
    main () {
      var x = $DYNAMIC;
      x;
    }
    """;
  return analyze(source).then((result) {
    result.checkNodeHasUnknownType('x');
  });
}

testVariableDeclaration() {
  final String source = r"""
      main() {
        var v1;
        var v2;
        v2 = 1;
        v1; v2;
      }
      """;
  return analyze(source).then((result) {
    result.checkNodeHasType('v1', [result.nullType]);
    result.checkNodeHasType('v2', [result.int]);
  });
}

testLiterals() {
  final String source = r"""
      main() {
        var v1 = 42;
        var v2 = 42.1;
        var v3 = 'abc';
        var v4 = true;
        var v5 = null;
        v1; v2; v3; v4; v5;
      }
      """;
  return analyze(source).then((result) {
    result.checkNodeHasType('v1', [result.int]);
    result.checkNodeHasType('v2', [result.double]);
    result.checkNodeHasType('v3', [result.string]);
    result.checkNodeHasType('v4', [result.bool]);
    result.checkNodeHasType('v5', [result.nullType]);
  });
}

testRedefinition() {
  final String source = r"""
      main() {
        var foo = 42;
        foo = 'abc';
        foo;
      }
      """;
  return analyze(source).then((result) {
    result.checkNodeHasType('foo', [result.string]);
  });
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
  return analyze(source).then((result) {
    result.checkNodeHasType('foo', [result.string, result.bool]);
  });
}

testTernaryIf() {
  final String source = r"""
      main() {
        var foo = 42;
        foo = true ? 'abc' : false;
        foo;
      }
      """;
  return analyze(source).then((result) {
    result.checkNodeHasType('foo', [result.string, result.bool]);
  });
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
  return analyze(source).then((result) {
    result.checkNodeHasType(
        'foo',
        [result.base('A'), result.base('B'), result.base('C')]);
    // Check that the condition is evaluated.
    // TODO(polux): bar's type could be inferred to be {int} here.
    result.checkNodeHasType('bar', [result.int, result.nullType]);
  });
}

testDoWhile() {
  final String source = r"""
      class A { f() => new B(); }
      class B { f() => new C(); }
      class C { f() => new A(); }
      main() {
        var bar = null;
        var foo = new A();
        do {
          foo = foo.f();
        } while (bar = 42);
        foo; bar;
      }
      """;
  return analyze(source).then((AnalysisResult result) {
    result.checkNodeHasType(
        'foo',
        [result.base('A'), result.base('B'), result.base('C')]);
    // Check that the condition is evaluated.
    result.checkNodeHasType('bar', [result.int]);
  });
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
  return analyze(source).then((result) {
    result.checkNodeHasType(
        'foo',
        [result.base('A'), result.base('B'), result.base('C')]);
  });
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
  return analyze(source).then((result) {
    result.checkNodeHasType('foo', [result.base('A'), result.base('B')]);
    // Check that the condition is evaluated.
    // TODO(polux): bar's type could be inferred to be {int} here.
    result.checkNodeHasType('bar', [result.int, result.nullType]);
  });
}

testFor3() {
  final String source = r"""
      main() {
        var i = 1;
        for(;;) {
          var x = 2;
          i = x;
        }
        i;
      }
      """;
  return analyze(source).then((result) {
    result.checkNodeHasType('i', [result.int]);
  });
}

testForIn() {
  final String source = r"""
      class MyIterator {
        var counter = 0;

        moveNext() {
          if (counter == 0) {
            counter = 1;
            return true;
          } else if (counter == 1) {
            counter = 2;
            return true;
          } else {
            return false;
          }
        }

        get current => (counter == 1) ? "foo" : 42;
      }

      class MyIterable {
        get iterator => new MyIterator();
      }

      main() {
        var res;
        for (var i in new MyIterable()) {
          res = i;
        }
        res;
      }
      """;
  return analyze(source).then((AnalysisResult result) {
    result.checkNodeHasType('res',
        [result.int, result.string, result.nullType]);
  });
}

testToplevelVariable() {
  final String source = r"""
      final top = 'abc';
      class A {
         f() => top;
      }
      main() {
        var foo = top;
        var bar = new A().f();
        foo; bar;
      }
      """;
  return analyze(source).then((result) {
    result.checkNodeHasType('foo', [result.string]);
    result.checkNodeHasType('bar', [result.string]);
  });
}

testToplevelVariable2() {
  final String source = r"""
      class A {
        var x;
      }
      final top = new A().x;

      main() {
        var a = new A();
        a.x = 42;
        a.x = "abc";
        var foo = top;
        foo;
      }
      """;
  return analyze(source).then((result) {
    result.checkNodeHasType('foo', [result.nullType, result.int,
                                    result.string]);
  });
}

testToplevelVariable3() {
  final String source = r"""
      var top = "a";
      
      f() => top;

      main() {
        var foo = f();
        var bar = top;
        top = 42;
        var baz = top;
        foo; bar; baz;
      }
      """;
  return analyze(source).then((result) {
    result.checkNodeHasType('foo', [result.int, result.string]);
    result.checkNodeHasType('bar', [result.int, result.string]);
    result.checkNodeHasType('baz', [result.int, result.string]);
  });
}

testNonRecusiveFunction() {
  final String source = r"""
      f(x, y) => true ? x : y;
      main() { var foo = f(42, "abc"); foo; }
      """;
  return analyze(source).then((result) {
    result.checkNodeHasType('foo', [result.int, result.string]);
  });
}

testMultipleReturns() {
  final String source = r"""
      f(x, y) {
        if (true) return x;
        else return y;
      }
      main() { var foo = f(42, "abc"); foo; }
      """;
  return analyze(source).then((result) {
    result.checkNodeHasType('foo', [result.int, result.string]);
  });
}

testRecusiveFunction() {
  final String source = r"""
      f(x) {
        if (true) return x;
        else return f(true ? x : "abc");
      }
      main() { var foo = f(42); foo; }
      """;
  return analyze(source).then((result) {
    result.checkNodeHasType('foo', [result.int, result.string]);
  });
}

testMutuallyRecusiveFunction() {
  final String source = r"""
      f() => true ? 42 : g();
      g() => true ? "abc" : f();
      main() { var foo = f(); foo; }
      """;
  return analyze(source).then((result) {
    result.checkNodeHasType('foo', [result.int, result.string]);
  });
}

testSimpleSend() {
  final String source = """
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
        var bar = $DYNAMIC.f(42);
        foo; bar;
      }
      """;
  return analyze(source).then((result) {
    result.checkNodeHasType('foo', [result.int]);
    result.checkNodeHasType('bar', [result.int, result.string]);
  });
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
  return analyze(source).then((result) {
    result.checkNodeHasType('foo', [result.int]);
  });
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
  return analyze(source).then((result) {
    result.checkNodeHasType('x', [result.base('B')]);
  });
}

testSendToThis3() {
  final String source = r"""
      class A {
        bar() => 42;
        foo() => bar();
      }
      class B extends A {
        bar() => "abc";
      }
      main() {
        var x = new B().foo();
        x;
      }
      """;
  return analyze(source).then((AnalysisResult result) {
    result.checkNodeHasType('x', [result.string]);
  });
}

testSendToThis4() {
  final String source = """
      class A {
        bar() => 42;
        foo() => bar();
      }
      class B extends A {
        bar() => "abc";
      }
      main() {
        new A(); new B();  // make A and B seen
        var x = $DYNAMIC.foo();
        x;
      }
      """;
  return analyze(source).then((AnalysisResult result) {
    result.checkNodeHasType('x', [result.int, result.string]);
  });
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
  return analyze(source).then((result) {
    result.checkFieldHasType('A', 'x', [result.int, result.bool]);
    result.checkFieldHasType('A', 'y', [result.string, result.nullType]);
    result.checkFieldHasType('A', 'z', [result.string]);
  });
}

testGetters() {
  final String source = """
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
        var quux = $DYNAMIC.x;
        foo; bar; baz; qux; quux;
      }
      """;
  return analyze(source).then((result) {
    result.checkNodeHasType('foo', [result.int]);
    result.checkNodeHasType('bar', [result.int]);
    result.checkNodeHasType('baz', [result.int]);
    result.checkNodeHasType('qux', []);
    result.checkNodeHasType('quux', [result.int, result.string]);
  });
}

testDynamicGetters() {
  final String source = """
      class A {
        get x => f();
        f() => 42;
      }
      class B extends A {
        f() => "abc";
      }
      main() {
        new A(); new B();  // make A and B seen
        var x = $DYNAMIC.x;
        x;
      }
      """;
  return analyze(source).then((result) {
    result.checkNodeHasType('x', [result.int, result.string]);
  });
}

testToplevelGetters() {
  final String source = """
      int _x = 42;
      get x => _x;
 
      f() => x;

      main() {
        var foo = f();
        var bar = x;
        _x = "a";
        var baz = x;
        foo; bar; baz;
      }
      """;
  return analyze(source).then((result) {
    result.checkNodeHasType('foo', [result.int, result.string]);
    result.checkNodeHasType('bar', [result.int, result.string]);
    result.checkNodeHasType('baz', [result.int, result.string]);
  });
}

testSetters() {
  final String source = """
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
        $DYNAMIC.x = null;
        $DYNAMIC.y = 3.14;
      }
      """;
  return analyze(source).then((result) {
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
                              result.double]);  // dynamic.y = 3.14
  });
}

testToplevelSetters() {
  final String source = """
      int _x = 42;
      set x(y) => _x = y;
 
      f(y) { x = y; }

      main() {
        var foo = _x;
        x = "a";
        var bar = _x;
        f(true);
        var baz = _x;
        foo; bar; baz;
      }
      """;
  return analyze(source).then((result) {
    result.checkNodeHasType('foo', [result.int, result.string, result.bool]);
    result.checkNodeHasType('bar', [result.int, result.string, result.bool]);
    result.checkNodeHasType('baz', [result.int, result.string, result.bool]);
  });
}


testOptionalNamedParameters() {
  final String source = r"""
      class A {
        var x, y, z, w;
        A(this.x, {this.y, this.z, this.w});
      }
      class B {
        var x, y;
        B(this.x, {this.y});
      }
      class C {
        var x, y;
        C(this.x, {this.y});
      }
      class Test {
        var a, b, c, d;
        var e, f;
        var g, h;

        Test(this.a, this.b, this.c, this.d,
             this.e, this.f,
             this.g, this.h);

        f1(x, {y, z, w}) {
          a = x;
          b = y;
          c = z;
          d = w;
        }
        f2(x, {y}) {
          e = x;
          f = y;
        }
        f3(x, {y}) {
          g = x;
          h = y;
        }
      }
      class Foo {
      }
      main() {
        // We want to test expiclitely for null later so we initialize all the
        // fields of Test with a placeholder type: Foo.
        var foo = new Foo();
        var test = new Test(foo, foo, foo, foo, foo, foo, foo, foo);

        new A(42);
        new A('abc', w: true, z: 42.1);
        test.f1(42);
        test.f1('abc', w: true, z: 42.1);

        new B('abc', y: true);
        new B(1, 2);  // too many positional arguments
        test.f2('abc', y: true);
        test.f2(1, 2);  // too many positional arguments

        new C('abc', y: true);
        new C(1, z: 2);  // non-existing named parameter
        test.f3('abc', y: true);
        test.f3(1, z: 2);  // non-existing named parameter
      }
      """;
  return analyze(source).then((result) {

    final foo = result.base('Foo');
    final nil = result.nullType;

    result.checkFieldHasType('A', 'x', [result.int, result.string]);
    result.checkFieldHasType('A', 'y', [nil]);
    result.checkFieldHasType('A', 'z', [nil, result.double]);
    result.checkFieldHasType('A', 'w', [nil, result.bool]);
    result.checkFieldHasType('Test', 'a', [foo, result.int, result.string]);
    result.checkFieldHasType('Test', 'b', [foo, nil]);
    result.checkFieldHasType('Test', 'c', [foo, nil, result.double]);
    result.checkFieldHasType('Test', 'd', [foo, nil, result.bool]);

    result.checkFieldHasType('B', 'x', [result.string]);
    result.checkFieldHasType('B', 'y', [result.bool]);
    result.checkFieldHasType('Test', 'e', [foo, result.string]);
    result.checkFieldHasType('Test', 'f', [foo, result.bool]);

    result.checkFieldHasType('C', 'x', [result.string]);
    result.checkFieldHasType('C', 'y', [result.bool]);
    result.checkFieldHasType('Test', 'g', [foo, result.string]);
    result.checkFieldHasType('Test', 'h', [foo, result.bool]);
  });
}

testOptionalPositionalParameters() {
  final String source = r"""
    class A {
      var x, y, z, w;
      A(this.x, [this.y, this.z, this.w]);
    }
    class B {
      var x, y;
      B(this.x, [this.y]);
    }
    class Test {
      var a, b, c, d;
      var e, f;

      Test(this.a, this.b, this.c, this.d,
           this.e, this.f);

      f1(x, [y, z, w]) {
        a = x;
        b = y;
        c = z;
        d = w;
      }
      f2(x, [y]) {
        e = x;
        f = y;
      }
    }
    class Foo {
    }
    main() {
      // We want to test expiclitely for null later so we initialize all the
      // fields of Test with a placeholder type: Foo.
      var foo = new Foo();
      var test = new Test(foo, foo, foo, foo, foo, foo);

      new A(42);
      new A('abc', true, 42.1);
      test.f1(42);
      test.f1('abc', true, 42.1);

      new B('a', true);
      new B(1, 2, 3);  // too many arguments
      test.f2('a', true);
      test.f2(1, 2, 3);  // too many arguments
    }
  """;
  return analyze(source).then((result) {

    final foo = result.base('Foo');
    final nil = result.nullType;

    result.checkFieldHasType('A', 'x', [result.int, result.string]);
    result.checkFieldHasType('A', 'y', [nil, result.bool]);
    result.checkFieldHasType('A', 'z', [nil, result.double]);
    result.checkFieldHasType('A', 'w', [nil]);
    result.checkFieldHasType('Test', 'a', [foo, result.int, result.string]);
    result.checkFieldHasType('Test', 'b', [foo, nil, result.bool]);
    result.checkFieldHasType('Test', 'c', [foo, nil, result.double]);
    result.checkFieldHasType('Test', 'd', [foo, nil]);

    result.checkFieldHasType('B', 'x', [result.string]);
    result.checkFieldHasType('B', 'y', [result.bool]);
    result.checkFieldHasType('Test', 'e', [foo, result.string]);
    result.checkFieldHasType('Test', 'f', [foo, result.bool]);
  });
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
  return analyze(source).then((result) {
    result.checkNodeHasType('x', [result.growableList]);
    result.checkNodeHasType('y', [result.growableList]);
    result.checkFieldHasType('A', 'x', [result.int]);
  });
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
  return analyze(source).then((result) {
    result.checkNodeHasType('x', [result.map]);
    result.checkNodeHasType('y', [result.map]);
    result.checkFieldHasType('A', 'x', [result.int]);
  });
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
  return analyze(source).then((result) {
    result.checkNodeHasType('x', [result.int, result.string]);
    result.checkNodeHasType('y', [result.nullType]);
  });
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
  return analyze(source).then((result) {
    result.checkNodeHasType('x', [result.int, result.nullType]);
    result.checkNodeHasType('y', [result.nullType]);
  });
}

testArithmeticOperators() {
  String source(op) {
    return """
        main() {
          var a = 1 $op 2;
          var b = 1 $op 2.1;
          var c = 1.1 $op 2;
          var d = 1.1 $op 2.1;
          var e = (1 $op 2.1) $op 1;
          var f = 1 $op (1 $op 2.1);
          var g = (1 $op 2.1) $op 1.1;
          var h = 1.1 $op (1 $op 2);
          var i = (1 $op 2) $op 1;
          var j = 1 $op (1 $op 2);
          var k = (1.1 $op 2.1) $op 1.1;
          var l = 1.1 $op (1.1 $op 2.1);
          a; b; c; d; e; f; g; h; i; j; k; l;
        }""";
  }
  return Future.forEach(['+', '*', '-'], (String op) {
    return analyze(source(op)).then((result) {
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
    });
  });
}

testBooleanOperators() {
  String source(op) {
    return """
        main() {
          var a = true $op null;
          var b = null $op true;
          var c = 1 $op true;
          var d = true $op "a";
          a; b; c; d;
        }""";
  }
  return Future.forEach(['&&', '||'], (String op) {
    return analyze(source(op)).then((result) {
      result.checkNodeHasType('a', [result.bool]);
      result.checkNodeHasType('b', [result.bool]);
      result.checkNodeHasType('c', [result.bool]);
      result.checkNodeHasType('d', [result.bool]);
    });
  });
}

testBooleanOperatorsShortCirtcuit() {
  String source(op) {
    return """
        main() {
          var x = null;
          "foo" $op (x = 42);
          x;
        }""";
  }
  return Future.forEach(['&&', '||'], (String op) {
    return analyze(source(op)).then((AnalysisResult result) {
      result.checkNodeHasType('x', [result.nullType, result.int]);
    });
  });
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
  return analyze(source).then((result) {
    result.checkNodeHasType('x', [result.int]);
    result.checkNodeHasType('y', [result.string]);
  });
}

testSetIndexOperator() {
  final String source = r"""
      class A {
        var witness1;
        var witness2;
        operator []=(i, x) { witness1 = i; witness2 = x; }
      }
      main() {
        var x = new A()[42] = "abc";
        x;
      }
      """;
  return analyze(source).then((result) {
    result.checkNodeHasType('x', [result.string]);
    result.checkFieldHasType('A', 'witness1', [result.int, result.nullType]);
    result.checkFieldHasType('A', 'witness2', [result.string, result.nullType]);
  });
}

testCompoundOperators1() {
  final String source = r"""
      class A {
        operator +(x) => "foo";
      }
      main() {
        var x1 = 1;
        x1++;
        var x2 = 1;
        ++x2;
        var x3 = 1;
        x3 += 42;
        var x4 = new A();
        x4++;
        var x5 = new A();
        ++x5;
        var x6 = new A();
        x6 += true;

        x1; x2; x3; x4; x5; x6;
      }
      """;
  return analyze(source).then((result) {
    result.checkNodeHasType('x1', [result.int]);
    result.checkNodeHasType('x2', [result.int]);
    result.checkNodeHasType('x3', [result.int]);
    result.checkNodeHasType('x4', [result.string]);
    result.checkNodeHasType('x5', [result.string]);
    result.checkNodeHasType('x6', [result.string]);
  });
}


testCompoundOperators2() {
  final String source = r"""
    class A {
      var xx;
      var yy;
      var witness1;
      var witness2;
      var witness3;
      var witness4;

      A(this.xx, this.yy);
      get x { witness1 = "foo"; return xx; }
      set x(a) { witness2 = "foo"; xx = a; }
      get y { witness3 = "foo"; return yy; }
      set y(a) { witness4 = "foo"; yy = a; }
    }
    main () {
      var a = new A(1, 1);
      a.x++;
      a.y++;
    }
    """;
  return analyze(source).then((result) {
    result.checkFieldHasType('A', 'xx', [result.int]);
    result.checkFieldHasType('A', 'yy', [result.int]);
    result.checkFieldHasType('A', 'witness1', [result.string, result.nullType]);
    result.checkFieldHasType('A', 'witness2', [result.string, result.nullType]);
    result.checkFieldHasType('A', 'witness3', [result.string, result.nullType]);
    result.checkFieldHasType('A', 'witness4', [result.string, result.nullType]);
  });
}

testInequality() {
  final String source = r"""
      class A {
        var witness;
        operator ==(x) { witness = "foo"; return "abc"; }
      }
      class B {
        operator ==(x) { throw "error"; }
      }
      main() {
        var foo = 1 != 2;
        var bar = (new A() != 2);
        var baz = (new B() != 2);
        foo; bar; baz;
      }
      """;
  return analyze(source).then((result) {
    result.checkNodeHasType('foo', [result.bool]);
    result.checkNodeHasType('bar', [result.bool]);
    // TODO(polux): could be even better: empty
    result.checkNodeHasType('baz', [result.bool]);
    result.checkFieldHasType('A', 'witness', [result.string, result.nullType]);
  });
}

testFieldInitialization1() {
  final String source = r"""
    class A {
      var x;
      var y = 1;
    }
    class B extends A {
      var z = "foo";
    }
    main () {
      // we need to access y and z once to trigger their analysis
      new B().y;
      new B().z;
    }
    """;
  return analyze(source).then((result) {
    result.checkFieldHasType('A', 'x', [result.nullType]);
    result.checkFieldHasType('A', 'y', [result.int]);
    result.checkFieldHasType('B', 'z', [result.string]);
  });
}

testFieldInitialization2() {
  final String source = r"""
    var top = 42;
    class A {
      var x = top;
    }
    main () {
      // we need to access X once to trigger its analysis
      new A().x;
    }
    """;
  return analyze(source).then((result) {
    result.checkFieldHasType('A', 'x', [result.int]);
  });
}

testFieldInitialization3() {
  final String source = r"""
    class A {
      var x;
    }
    f() => new A().x;
    class B {
      var x = new A().x;
      var y = f();
    }
    main () {
      var foo = new B().x;
      var bar = new B().y;
      new A().x = "a";
      foo; bar;
    }
    """;
  return analyze(source).then((result) {
    // checks that B.B is set as a reader of A.x
    result.checkFieldHasType('B', 'x', [result.nullType, result.string]);
    // checks that B.B is set as a caller of f
    result.checkFieldHasType('B', 'y', [result.nullType, result.string]);
    // checks that readers of x are notified by changes in x's type
    result.checkNodeHasType('foo', [result.nullType, result.string]);
    // checks that readers of y are notified by changes in y's type
    result.checkNodeHasType('bar', [result.nullType, result.string]);
  });
}

testLists() {
  final String source = """
    class A {}
    class B {}
    class C {}
    class D {}
    class E {}
    class F {}
    class G {}

    main() {
      var l1 = [new A()];
      var l2 = [];
      l1['a'] = new B();  // raises an error, so B should not be recorded
      l1[1] = new C();
      l1.add(new D());
      l1.insert('a', new E());  // raises an error, so E should not be recorded
      l1.insert(1, new F());
      $DYNAMIC[1] = new G();
      var x1 = l1[1];
      var x2 = l2[1];
      var x3 = l1['foo'];  // raises an error, should return empty
      var x4 = l1.removeAt(1);
      var x5 = l2.removeAt(1);
      var x6 = l1.removeAt('a');  // raises an error, should return empty
      var x7 = l1.removeLast();
      var x8 = l2.removeLast();
      x1; x2; x3; x4; x5; x6; x7; x8;
    }""";
  return analyze(source).then((result) {
    final expectedTypes = ['A', 'C', 'D', 'F', 'G'].map(result.base).toList();
    result.checkNodeHasType('x1', expectedTypes);
    result.checkNodeHasType('x2', expectedTypes);
    result.checkNodeHasType('x3', []);
    result.checkNodeHasType('x4', expectedTypes);
    result.checkNodeHasType('x5', expectedTypes);
    result.checkNodeHasType('x6', []);
    result.checkNodeHasType('x7', expectedTypes);
    result.checkNodeHasType('x8', expectedTypes);
  });
}

testListWithCapacity() {
  final String source = r"""
    main() {
      var l = new List(10);
      var x = [][0];
      x;
    }""";
  return analyze(source).then((result) {
    result.checkNodeHasType('x', [result.nullType]);
  });
}

testEmptyList() {
  final String source = r"""
    main() {
      var l = new List();
      var x = l[0];
      x;
    }""";
  return analyze(source).then((result) {
    result.checkNodeHasType('x', []);
  });
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
  return analyze(source).then((result) {
    // TODO(polux): It would be better if x and y also had the empty type. This
    // requires a change in SimpleTypeInferrerVisitor.visitStaticSend which
    // would impact the default type inference and possibly break dart2js.
    // Keeping this change for a later CL.
    result.checkNodeHasUnknownType('x');
    result.checkNodeHasUnknownType('y');
    result.checkNodeHasType('z', []);
    result.checkNodeHasType('w', []);
  });
}

testBigTypesWidening1() {
  final String source = r"""
    small() => true ? 1 : 'abc';
    big() => true ? 1 : (true ? 'abc' : false);
    main () {
      var x = small();
      var y = big();
      x; y;
    }
    """;
  return analyze(source, maxConcreteTypeSize: 2).then((result) {
    result.checkNodeHasType('x', [result.int, result.string]);
    result.checkNodeHasUnknownType('y');
  });
}

testBigTypesWidening2() {
  final String source = r"""
    class A {
      var x, y;
      A(this.x, this.y);
    }
    main () {
      var a = new A(1, 1);
      a.x = 'abc';
      a.y = 'abc';
      a.y = true;
    }
    """;
  return analyze(source, maxConcreteTypeSize: 2).then((result) {
    result.checkFieldHasType('A', 'x', [result.int, result.string]);
    result.checkFieldHasUknownType('A', 'y');
  });
}

testDynamicIsAbsorbing() {
  final String source = """
    main () {
      var x = 1;
      if (true) {
        x = $DYNAMIC;
      } else {
        x = 42;
      }
      x;
    }
    """;
  return analyze(source).then((result) {
    result.checkNodeHasUnknownType('x');
  });
}

testJsCall() {
  final String source = r"""
    import 'dart:_foreign_helper';
    import 'dart:_interceptors';

    abstract class AbstractA {}
    class A extends AbstractA {}
    class B extends A {}
    class BB extends B {}
    class C extends A {}
    class D implements A {}
    class E extends A {}

    class X {}

    main () {
      // we don't create any E on purpose
      new B(); new BB(); new C(); new D();

      var a = JS('', '1');
      var b = JS('Object', '1');
      var c = JS('JSExtendableArray', '1');
      var cNull = JS('JSExtendableArray|Null', '1');
      var d = JS('String', '1');
      var dNull = JS('String|Null', '1');
      var e = JS('int', '1');
      var eNull = JS('int|Null', '1');
      var f = JS('double', '1');
      var fNull = JS('double|Null', '1');
      var g = JS('num', '1');
      var gNull = JS('num|Null', '1');
      var h = JS('bool', '1');
      var hNull = JS('bool|Null', '1');
      var i = JS('AbstractA', '1');
      var iNull = JS('AbstractA|Null', '1');

      a; b; c; cNull; d; dNull; e; eNull; f; fNull; g; gNull; h; hNull; i;
      iNull;
    }
    """;
  return analyze(source, maxConcreteTypeSize: 6).then((result) {
    List maybe(List types) => new List.from(types)..add(result.nullType);
    // a and b have all the types seen by the resolver, which are more than 6
    result.checkNodeHasUnknownType('a');
    result.checkNodeHasUnknownType('b');
    final expectedCType = [result.growableList];
    result.checkNodeHasType('c', expectedCType);
    result.checkNodeHasType('cNull', maybe(expectedCType));
    final expectedDType = [result.string];
    result.checkNodeHasType('d', expectedDType);
    result.checkNodeHasType('dNull', maybe(expectedDType));
    final expectedEType = [result.int];
    result.checkNodeHasType('e', expectedEType);
    result.checkNodeHasType('eNull', maybe(expectedEType));
    final expectedFType = [result.double];
    result.checkNodeHasType('f', expectedFType);
    result.checkNodeHasType('fNull', maybe(expectedFType));
    final expectedGType = [result.num];
    result.checkNodeHasType('g', expectedGType);
    result.checkNodeHasType('gNull', maybe(expectedGType));
    final expectedType = [result.bool];
    result.checkNodeHasType('h', expectedType);
    result.checkNodeHasType('hNull', maybe(expectedType));
    final expectedIType = [result.base('A'), result.base('B'),
                           result.base('BB'), result.base('C'),
                           result.base('D')];
    result.checkNodeHasType('i', expectedIType);
    result.checkNodeHasType('iNull', maybe(expectedIType));
  });
}

testJsCallAugmentsSeenClasses() {
  final String source1 = """
    main () {
      var x = $DYNAMIC.truncate();
      x;
    }
    """;
  return analyze(source1).then((AnalysisResult result) {
    result.checkNodeHasType('x', []);
  }).whenComplete(() {

    final String source2 = """
      import 'dart:_foreign_helper';

      main () {
        var x = $DYNAMIC.truncate();
        JS('double', 'foo');
        x;
      }
      """;
    return analyze(source2).then((AnalysisResult result) {
      result.checkNodeHasType('x', [result.int]);
    });
  });
}

testIsCheck() {
  final String source = r"""
    main () {
      var x = (1 is String);
      x;
    }
    """;
  return analyze(source).then((result) {
    result.checkNodeHasType('x', [result.bool]);
  });
}

testSeenClasses() {
  final String source = """
      class A {
        witness() => 42;
      }
      class B {
        witness() => "string";
      }
      class AFactory {
        onlyCalledInAFactory() => new A();
      }
      class BFactory {
        onlyCalledInAFactory() => new B();
      }

      main() {
        new AFactory().onlyCalledInAFactory();
        new BFactory();
        // should be of type {int} and not {int, String} since B is unreachable
        var foo = $DYNAMIC.witness();
        foo;
      }
      """;
  return analyze(source).then((result) {
    result.checkNodeHasType('foo', [result.int]);
  });
}

testIntDoubleNum() {
  final String source = r"""
      main() {
        var a = 1;
        var b = 1.1;
        var c = true ? 1 : 1.1;
        a; b; c;
      }
      """;
  return analyze(source).then((result) {
    result.checkNodeHasType('a', [result.int]);
    result.checkNodeHasType('b', [result.double]);
    result.checkNodeHasType('c', [result.num]);
  });
}

testConcreteTypeToTypeMask() {
  final String source = r"""
      class A {}
      class B extends A {}
      class C extends A {}
      class D implements A {}
      main() {
        new A();
        new B();
        new C();
        new D();
      }
      """;
  return analyze(source).then((result) {

  convert(ConcreteType type) {
    return result.compiler.typesTask.concreteTypesInferrer
        .types.concreteTypeToTypeMask(type);
  }

    final nullSingleton =
        result.compiler.typesTask.concreteTypesInferrer.singletonConcreteType(
            new NullBaseType());

    singleton(ClassElement element) {
      return result.compiler.typesTask.concreteTypesInferrer
          .singletonConcreteType(new ClassBaseType(element));
    }

    ClassElement a = findElement(result.compiler, 'A');
    ClassElement b = findElement(result.compiler, 'B');
    ClassElement c = findElement(result.compiler, 'C');
    ClassElement d = findElement(result.compiler, 'D');

    for (ClassElement cls in [a, b, c, d]) {
      Expect.equals(convert(singleton(cls)),
                    new TypeMask.nonNullExact(cls));
    }

    for (ClassElement cls in [a, b, c, d]) {
      Expect.equals(convert(singleton(cls).union(nullSingleton)),
                    new TypeMask.exact(cls));
    }

    Expect.equals(convert(singleton(a).union(singleton(b))),
                  new TypeMask.nonNullSubclass(a));

    Expect.equals(
        convert(singleton(a).union(singleton(b)).union(nullSingleton)),
                  new TypeMask.subclass(a));

    Expect.equals(
        simplify(convert(singleton(b).union(singleton(d))), result.compiler),
        new TypeMask.nonNullSubtype(a));
  });
}

testSelectors() {
  final String source = r"""
      // ABC <--- A
      //       `- BC <--- B
      //               `- C

      class ABC {}
      class A extends ABC {}
      class BC extends ABC {}
      class B extends BC {}
      class C extends BC {}

      class XY {}
      class X extends XY { foo() => new B(); }
      class Y extends XY { foo() => new C(); }
      class Z { foo() => new A(); }

      main() {
        new X().foo();
        new Y().foo();
        new Z().foo();
      }
      """;
  return analyze(source).then((result) {



    ClassElement a = findElement(result.compiler, 'A');
    ClassElement b = findElement(result.compiler, 'B');
    ClassElement c = findElement(result.compiler, 'C');
    ClassElement xy = findElement(result.compiler, 'XY');
    ClassElement x = findElement(result.compiler, 'X');
    ClassElement y = findElement(result.compiler, 'Y');
    ClassElement z = findElement(result.compiler, 'Z');

    Selector foo = new Selector.call("foo", null, 0);

    result.checkSelectorHasType(
        foo,
        new TypeMask.unionOf([a, b, c]
            .map((cls) => new TypeMask.nonNullExact(cls)), result.compiler));
    result.checkSelectorHasType(
        new TypedSelector.subclass(x, foo, result.compiler),
        new TypeMask.nonNullExact(b));
    result.checkSelectorHasType(
        new TypedSelector.subclass(y, foo, result.compiler),
        new TypeMask.nonNullExact(c));
    result.checkSelectorHasType(
        new TypedSelector.subclass(z, foo, result.compiler),
        new TypeMask.nonNullExact(a));
    result.checkSelectorHasType(
        new TypedSelector.subclass(xy, foo, result.compiler),
        new TypeMask.unionOf([b, c].map((cls) =>
            new TypeMask.nonNullExact(cls)), result.compiler));

    result.checkSelectorHasType(new Selector.call("bar", null, 0), null);
  });
}

testEqualsNullSelector() {
  final String source = r"""
      main() {
        1 == null;
      }
      """;
  return analyze(source).then((result) {
    ClassElement bool = result.compiler.backend.boolImplementation;
    result.checkSelectorHasType(new Selector.binaryOperator('=='),
                                new TypeMask.nonNullExact(bool));
  });
}

testMixins() {
  final String source = r"""
      class A {
        foo() => "abc";
        get x => 42;
      }
      class B extends Object with A {
        bar() => foo();
        baz() => x;
      }
      main() {
        var b = new B();
        var x = b.foo();
        var y = b.bar();
        var z = b.x;
        var w = b.baz();
        x; y; z; w;
      }
      """;
  return analyze(source).then((result) {
    result.checkNodeHasType('x', [result.string]);
    result.checkNodeHasType('y', [result.string]);
    result.checkNodeHasType('z', [result.int]);
    result.checkNodeHasType('w', [result.int]);
  });
}

testClosures1() {
  final String source = r"""
      class A {
        final foo = 42;
      }
      class B {
        final foo = "abc";
      }
      class C {
        final foo = true;
      }
      main() {
        var a;
        var f = (x) {
          a = x.foo;
        };
        // We make sure that x doesn't have type dynamic by adding C to the
        // set of seen classes and by checking that a's type doesn't contain
        // bool.
        new C();
        f(new A());
        f(new B());
        a;
      }
      """;
  return analyze(source).then((AnalysisResult result) {
    result.checkNodeHasType('a', [result.nullType, result.int, result.string]);
  });
}

testClosures2() {
  final String source = r"""
      class A {
        final foo = 42;
      }
      class B {
        final foo = "abc";
      }
      class C {
        final foo = true;
      }
      main() {
        // We make sure that x doesn't have type dynamic by adding C to the
        // set of seen classes and by checking that a's type doesn't contain
        // bool. 
        new C();

        var a;
        f(x) {
          a = x.foo;
        }
        f(new A());
        f(new B());
        a; f;
      }
      """;
  return analyze(source).then((AnalysisResult result) {
    result.checkNodeHasType('a', [result.nullType, result.int, result.string]);
    result.checkNodeHasType('f', [result.functionType]);
  });
}

testClosures3() {
  final String source = r"""
      class A {
        var g;
        A(this.g);
      }
      main() {
        var foo = new A((x) => x).g(42);
        foo;
      }
      """;
  return analyze(source).then((result) {
    result.checkNodeHasType('foo', [result.int]);
  });
}

testClosures4() {
  final String source = """
      class A {
        var f = $DYNAMIC;
      }
      main() {
        var f = (x) => x;
        var g = (x) => "a";
        var h = (x, y) => true;

        var foo = $DYNAMIC(42);
        var bar = new A().f(1.2);
        var baz = $DYNAMIC.f(null);

        foo; bar; baz;
      }
      """;
  return analyze(source).then((result) {
    result.checkNodeHasType('foo', [result.int, result.string]);
    result.checkNodeHasType('bar', [result.double, result.string]);
    result.checkNodeHasType('baz', [result.nullType, result.string]);
  });
}

testClosures5() {
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
  return analyze(source).then((result) {
    result.checkNodeHasType('foo', [result.int]);
  });
}

testClosures6() {
  final String source = r"""
      class A {
        var g;
        A(this.g);
      }
      class B {
        f(x) => x;
      }
      main() {
        var foo = new A(new B().f).g(42);
        foo;
      }
      """;
  return analyze(source).then((result) {
    result.checkNodeHasType('foo', [result.int]);
  });
}

testClosures7() {
  final String source = r"""
      class A {
        final x = 42;
        f() => () => x;
      }
      main() {
        var foo = new A().f()();
        foo;
      }
      """;
  return analyze(source).then((result) {
    result.checkNodeHasType('foo', [result.int]);
  });
}

testClosures8() {
  final String source = r"""
      class A {
        final x = 42;
        f() => () => x;
      }
      class B extends A {
        get x => "a";
      }
      main() {
        var foo = new B().f()();
        foo;
      }
      """;
  return analyze(source).then((result) {
    result.checkNodeHasType('foo', [result.string]);
  });
}

testClosures9() {
  final String source = r"""
      class A {
        g() => 42;
        f() => () => g();
      }
      class B extends A {
        g() => "a";
      }
      main() {
        var foo = new B().f()();
        foo;
      }
      """;
  return analyze(source).then((result) {
    result.checkNodeHasType('foo', [result.string]);
  });
}

testClosures10() {
  final String source = r"""
      class A {
        f() => 42;
      }
      main() {
        var a = new A();
        g() => a.f();
        var foo = g();
        foo; a;
      }
      """;
  return analyze(source).then((result) {
    result.checkNodeHasType('foo', [result.int]);
  });
}

testClosures11() {
  final String source = r"""
      class A {
        var x;
        f() => x;
      }
      main() {
        var a = new A();
        f() => a.f();
        a.x = 42;
        var foo = f();
        foo;
      }
      """;
  return analyze(source).then((result) {
    result.checkNodeHasType('foo', [result.nullType, result.int]);
  });
}

testClosures12() {
  final String source = r"""
      var f = (x) => x;
      main() {
        var foo = f(1);
        foo;
      }
      """;
  return analyze(source).then((result) {
    result.checkNodeHasType('foo', [result.int]);
  });
}

testRefinement() {
  final String source = """
      class A {
        f() => null;
        g() => 42;
      }
      class B {
        g() => "aa";
      }
      main() {
        var x = $DYNAMIC ? new A() : new B();
        x.f();
        var foo = x.g();
        foo;
      }
      """;
  return analyze(source).then((result) {
    result.checkNodeHasType('foo', [result.int]);
  });
}

testDefaultArguments() {
  final String source = r"""
      f1([x = 42]) => x;
      g1([x]) => x;

      f2({x: 42}) => x;
      g2({x}) => x;

      main() {
        var xf1 = f1();
        var xg1 = g1();
        var xf2 = f2();
        var xg2 = g2();
        xf1; xg1; xf2; xg2;
      }
      """;
  return analyze(source).then((result) {
    result.checkNodeHasType('xf1', [result.int]);
    result.checkNodeHasType('xg1', [result.nullType]);
    result.checkNodeHasType('xf2', [result.int]);
    result.checkNodeHasType('xg2', [result.nullType]);
  });
}

testSuperConstructorCall() {
  final String source = r"""
      class A {
        final x;
        A(this.x);
      }

      class B extends A {
        B(x) : super(x);
      }
      main() {
        var b = new B(42);
        var foo = b.x;
        foo;
      }
      """;
  return analyze(source).then((result) {
    result.checkFieldHasType('A', 'x', [result.int]);
    result.checkNodeHasType('foo', [result.int]);
  });
}

testSuperConstructorCall2() {
  final String source = r"""
      class A {
        var x;
        A() {
          x = 42;
        }
      }
      class B extends A {
      }
      main() {
        new B();
      }
      """;
  return analyze(source).then((result) {
    result.checkFieldHasType('A', 'x', [result.int]);
  });
}

testSuperConstructorCall3() {
  final String source = r"""
      class A {
        var x;
        A() {
          x = 42;
        }
      }
      class B extends A {
        B(unused) {}
      }
      main() {
        new B("abc");
      }
      """;
  return analyze(source).then((result) {
    result.checkFieldHasType('A', 'x', [result.int]);
  });
}

void main() {
  asyncTest(() => Future.forEach([
    testDynamicBackDoor,
    testVariableDeclaration,
    testLiterals,
    testRedefinition,
    testIfThenElse,
    testTernaryIf,
    testWhile,
    testDoWhile,
    testFor1,
    testFor2,
    testFor3,
    testForIn,
    testToplevelVariable,
    testToplevelVariable2,
    testToplevelVariable3,
    testNonRecusiveFunction,
    testMultipleReturns,
    testRecusiveFunction,
    testMutuallyRecusiveFunction,
    testSimpleSend,
    testSendToThis1,
    testSendToThis2,
    testSendToThis3,
    testSendToThis4,
    testConstructor,
    testGetters,
    testToplevelGetters,
    testDynamicGetters,
    testSetters,
    testToplevelSetters,
    testOptionalNamedParameters,
    testOptionalPositionalParameters,
    testListLiterals,
    testMapLiterals,
    testReturn,
    testNoReturn,
    testArithmeticOperators,
    testBooleanOperators,
    testBooleanOperatorsShortCirtcuit,
    testOperators,
    testCompoundOperators1,
    testCompoundOperators2,
    testSetIndexOperator,
    testInequality,
    testFieldInitialization1,
    testFieldInitialization2,
    testFieldInitialization3,
    testSendWithWrongArity,
    testBigTypesWidening1,
    testBigTypesWidening2,
    testDynamicIsAbsorbing,
    testLists,
    testListWithCapacity,
    testEmptyList,
    testJsCall,
    testJsCallAugmentsSeenClasses,
    testIsCheck,
    testSeenClasses,
    testIntDoubleNum,
    testConcreteTypeToTypeMask,
    testSelectors,
    // TODO(polux): this test is failing, see http://dartbug.com/16825.
    //testEqualsNullSelector,
    testMixins,
    testClosures1,
    testClosures2,
    testClosures3,
    testClosures4,
    testClosures5,
    testClosures6,
    testClosures7,
    testClosures8,
    testClosures9,
    testClosures10,
    testClosures11,
    testClosures12,
    testRefinement,
    testDefaultArguments,
    testSuperConstructorCall,
    testSuperConstructorCall2,
    testSuperConstructorCall3,
  ], (f) => f()));
}
