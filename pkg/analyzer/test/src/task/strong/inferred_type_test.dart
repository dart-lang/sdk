// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// TODO(jmesserly): this file needs to be refactored, it's a port from
// package:dev_compiler's tests
/// Tests for type inference.
library test.src.task.strong.inferred_type_test;

import 'package:unittest/unittest.dart';

import 'strong_test_helper.dart';

void main() {
  // Error also expected when declared type is `int`.
  testChecker('infer type on var', {
    '/main.dart': '''
      test1() {
        int x = 3;
        x = /*severe:StaticTypeError*/"hi";
      }
    '''
  });

  // If inferred type is `int`, error is also reported
  testChecker('infer type on var 2', {
    '/main.dart': '''
      test2() {
        var x = 3;
        x = /*severe:StaticTypeError*/"hi";
      }
    '''
  });

  testChecker('No error when declared type is `num` and assigned null.', {
    '/main.dart': '''
        test1() {
          num x = 3;
          x = null;
        }
      '''
  });

  testChecker('do not infer type on dynamic', {
    '/main.dart': '''
      test() {
        dynamic x = 3;
        x = "hi";
      }
    '''
  });

  testChecker('do not infer type when initializer is null', {
    '/main.dart': '''
      test() {
        var x = null;
        x = "hi";
        x = 3;
      }
    '''
  });

  testChecker('infer type on var from field', {
    '/main.dart': '''
      class A {
        int x = 0;

        test1() {
          var a = x;
          a = /*severe:StaticTypeError*/"hi";
          a = 3;
          var b = y;
          b = /*severe:StaticTypeError*/"hi";
          b = 4;
          var c = z;
          c = /*severe:StaticTypeError*/"hi";
          c = 4;
        }

        int y; // field def after use
        final z = 42; // should infer `int`
      }
    '''
  });

  testChecker('infer type on var from top-level', {
    '/main.dart': '''
      int x = 0;

      test1() {
        var a = x;
        a = /*severe:StaticTypeError*/"hi";
        a = 3;
        var b = y;
        b = /*severe:StaticTypeError*/"hi";
        b = 4;
        var c = z;
        c = /*severe:StaticTypeError*/"hi";
        c = 4;
      }

      int y = 0; // field def after use
      final z = 42; // should infer `int`
    '''
  });

  testChecker('do not infer field type when initializer is null', {
    '/main.dart': '''
      var x = null;
      var y = 3;
      class A {
        static var x = null;
        static var y = 3;

        var x2 = null;
        var y2 = 3;
      }

      test() {
        x = "hi";
        y = /*severe:StaticTypeError*/"hi";
        A.x = "hi";
        A.y = /*severe:StaticTypeError*/"hi";
        new A().x2 = "hi";
        new A().y2 = /*severe:StaticTypeError*/"hi";
      }
    '''
  });

  testChecker('infer from variables in non-cycle imports with flag', {
    '/a.dart': '''
          var x = 2;
      ''',
    '/main.dart': '''
          import 'a.dart';
          var y = x;

          test1() {
            x = /*severe:StaticTypeError*/"hi";
            y = /*severe:StaticTypeError*/"hi";
          }
    '''
  });

  testChecker('infer from variables in non-cycle imports with flag 2', {
    '/a.dart': '''
          class A { static var x = 2; }
      ''',
    '/main.dart': '''
          import 'a.dart';
          class B { static var y = A.x; }

          test1() {
            A.x = /*severe:StaticTypeError*/"hi";
            B.y = /*severe:StaticTypeError*/"hi";
          }
    '''
  });

  testChecker('infer from variables in cycle libs when flag is on', {
    '/a.dart': '''
          import 'main.dart';
          var x = 2; // ok to infer
      ''',
    '/main.dart': '''
          import 'a.dart';
          var y = x; // now ok :)

          test1() {
            int t = 3;
            t = x;
            t = y;
          }
    '''
  });

  testChecker('infer from variables in cycle libs when flag is on 2', {
    '/a.dart': '''
          import 'main.dart';
          class A { static var x = 2; }
      ''',
    '/main.dart': '''
          import 'a.dart';
          class B { static var y = A.x; }

          test1() {
            int t = 3;
            t = A.x;
            t = B.y;
          }
    '''
  });

  testChecker('can infer also from static and instance fields (flag on)', {
    '/a.dart': '''
          import 'b.dart';
          class A {
            static final a1 = B.b1;
            final a2 = new B().b2;
          }
      ''',
    '/b.dart': '''
          class B {
            static final b1 = 1;
            final b2 = 1;
          }
      ''',
    '/main.dart': '''
          import "a.dart";

          test1() {
            int x = 0;
            // inference in A now works.
            x = A.a1;
            x = new A().a2;
          }
    '''
  });

  testChecker('inference in cycles is deterministic', {
    '/a.dart': '''
          import 'b.dart';
          class A {
            static final a1 = B.b1;
            final a2 = new B().b2;
          }
      ''',
    '/b.dart': '''
          class B {
            static final b1 = 1;
            final b2 = 1;
          }
      ''',
    '/c.dart': '''
          import "main.dart"; // creates a cycle

          class C {
            static final c1 = 1;
            final c2 = 1;
          }
      ''',
    '/e.dart': '''
          import 'a.dart';
          part 'e2.dart';

          class E {
            static final e1 = 1;
            static final e2 = F.f1;
            static final e3 = A.a1;
            final e4 = 1;
            final e5 = new F().f2;
            final e6 = new A().a2;
          }
      ''',
    '/f.dart': '''
          part 'f2.dart';
      ''',
    '/e2.dart': '''
          class F {
            static final f1 = 1;
            final f2 = 1;
          }
      ''',
    '/main.dart': '''
          import "a.dart";
          import "c.dart";
          import "e.dart";

          class D {
            static final d1 = A.a1 + 1;
            static final d2 = C.c1 + 1;
            final d3 = new A().a2;
            final d4 = new C().c2;
          }

          test1() {
            int x = 0;
            // inference in A works, it's not in a cycle
            x = A.a1;
            x = new A().a2;

            // Within a cycle we allow inference when the RHS is well known, but
            // not when it depends on other fields within the cycle
            x = C.c1;
            x = D.d1;
            x = D.d2;
            x = new C().c2;
            x = new D().d3;
            x = /*info:DynamicCast*/new D().d4;


            // Similarly if the library contains parts.
            x = E.e1;
            x = E.e2;
            x = E.e3;
            x = new E().e4;
            x = /*info:DynamicCast*/new E().e5;
            x = new E().e6;
            x = F.f1;
            x = new F().f2;
          }
    '''
  });

  testChecker(
      'infer from complex expressions if the outer-most value is precise', {
    '/main.dart': '''
        class A { int x; B operator+(other) {} }
        class B extends A { B(ignore); }
        var a = new A();
        // Note: it doesn't matter that some of these refer to 'x'.
        var b = new B(x);       // allocations
        var c1 = [x];           // list literals
        var c2 = const [];
        var d = {'a': 'b'};     // map literals
        var e = new A()..x = 3; // cascades
        var f = 2 + 3;          // binary expressions are OK if the left operand
                                // is from a library in a different strongest
                                // conected component.
        var g = -3;
        var h = new A() + 3;
        var i = - new A();
        var j = null as B;

        test1() {
          a = /*severe:StaticTypeError*/"hi";
          a = new B(3);
          b = /*severe:StaticTypeError*/"hi";
          b = new B(3);
          c1 = [];
          c1 = /*severe:StaticTypeError*/{};
          c2 = [];
          c2 = /*severe:StaticTypeError*/{};
          d = {};
          d = /*severe:StaticTypeError*/3;
          e = new A();
          e = /*severe:StaticTypeError*/{};
          f = 3;
          f = /*severe:StaticTypeError*/false;
          g = 1;
          g = /*severe:StaticTypeError*/false;
          h = /*severe:StaticTypeError*/false;
          h = new B();
          i = false;
          j = new B();
          j = /*severe:StaticTypeError*/false;
          j = /*severe:StaticTypeError*/[];
        }
    '''
  });

  // but flags can enable this behavior.
  testChecker('infer if complex expressions read possibly inferred field', {
    '/a.dart': '''
        class A {
          var x = 3;
        }
      ''',
    '/main.dart': '''
        import 'a.dart';
        class B {
          var y = 3;
        }
        final t1 = new A();
        final t2 = new A().x;
        final t3 = new B();
        final t4 = new B().y;

        test1() {
          int i = 0;
          A a;
          B b;
          a = t1;
          i = t2;
          b = t3;
          i = /*info:DynamicCast*/t4;
          i = new B().y; // B.y was inferred though
        }
    '''
  });

  group('infer types on loop indices', () {
    testChecker('foreach loop', {
      '/main.dart': '''
      class Foo {
        int bar = 42;
      }

      class Bar<T extends Iterable<String>> {
        void foo(T t) {
          for (var i in t) {
            int x = /*severe:StaticTypeError*/i;
          }
        }
      }

      class Baz<T, E extends Iterable<T>, S extends E> {
        void foo(S t) {
          for (var i in t) {
            int x = /*severe:StaticTypeError*/i;
            T y = i;
          }
        }
      }

      test() {
        var list = <Foo>[];
        for (var x in list) {
          String y = /*severe:StaticTypeError*/x;
        }

        for (dynamic x in list) {
          String y = /*info:DynamicCast*/x;
        }

        for (String x in /*severe:StaticTypeError*/list) {
          String y = x;
        }

        var z;
        for(z in list) {
          String y = /*info:DynamicCast*/z;
        }

        Iterable iter = list;
        for (Foo x in /*warning:DownCastComposite*/iter) {
          var y = x;
        }

        dynamic iter2 = list;
        for (Foo x in /*warning:DownCastComposite*/iter2) {
          var y = x;
        }

        var map = <String, Foo>{};
        // Error: map must be an Iterable.
        for (var x in /*severe:StaticTypeError*/map) {
          String y = /*info:DynamicCast*/x;
        }

        // We're not properly inferring that map.keys is an Iterable<String>
        // and that x is a String.
        for (var x in map.keys) {
          String y = x;
        }
      }
      '''
    });

    testChecker('for loop, with inference', {
      '/main.dart': '''
      test() {
        for (var i = 0; i < 10; i++) {
          int j = i + 1;
        }
      }
      '''
    });
  });

  testChecker('propagate inference to field in class', {
    '/main.dart': '''
      class A {
        int x = 2;
      }

      test() {
        var a = new A();
        A b = a;                      // doesn't require down cast
        print(a.x);     // doesn't require dynamic invoke
        print(a.x + 2); // ok to use in bigger expression
      }
    '''
  });

  testChecker('propagate inference to field in class dynamic warnings', {
    '/main.dart': '''
      class A {
        int x = 2;
      }

      test() {
        dynamic a = new A();
        A b = /*info:DynamicCast*/a;
        print(/*info:DynamicInvoke*/a.x);
        print(/*info:DynamicInvoke*/(/*info:DynamicInvoke*/a.x) + 2);
      }
    '''
  });

  testChecker('propagate inference transitively', {
    '/main.dart': '''
      class A {
        int x = 2;
      }

      test5() {
        var a1 = new A();
        a1.x = /*severe:StaticTypeError*/"hi";

        A a2 = new A();
        a2.x = /*severe:StaticTypeError*/"hi";
      }
    '''
  });

  testChecker('propagate inference transitively 2', {
    '/main.dart': '''
      class A {
        int x = 42;
      }

      class B {
        A a = new A();
      }

      class C {
        B b = new B();
      }

      class D {
        C c = new C();
      }

      void main() {
        var d1 = new D();
        print(d1.c.b.a.x);

        D d2 = new D();
        print(d2.c.b.a.x);
      }
    '''
  });

  group('infer type on overridden fields', () {
    testChecker('2', {
      '/main.dart': '''
        class A {
          int x = 2;
        }

        class B extends A {
          /*severe:InvalidFieldOverride*/get x => 3;
        }

        foo() {
          String y = /*severe:StaticTypeError*/new B().x;
          int z = new B().x;
        }
    '''
    });

    testChecker('4', {
      '/main.dart': '''
        class A {
          int x = 2;
        }

        class B implements A {
          get x => 3;
        }

        foo() {
          String y = /*severe:StaticTypeError*/new B().x;
          int z = new B().x;
        }
    '''
    });
  });

  group('infer types on generic instantiations', () {
    testChecker('infer', {
      '/main.dart': '''
        class A<T> {
          T x;
        }

        class B implements A<int> {
          /*severe:InvalidMethodOverride*/dynamic get x => 3;
        }

        foo() {
          String y = /*info:DynamicCast*/new B().x;
          int z = /*info:DynamicCast*/new B().x;
        }
    '''
    });

    testChecker('3', {
      '/main.dart': '''
        class A<T> {
          T x;
          T w;
        }

        class B implements A<int> {
          get x => 3;
          get w => /*severe:StaticTypeError*/"hello";
        }

        foo() {
          String y = /*severe:StaticTypeError*/new B().x;
          int z = new B().x;
        }
    '''
    });

    testChecker('4', {
      '/main.dart': '''
        class A<T> {
          T x;
        }

        class B<E> extends A<E> {
          E y;
          /*severe:InvalidFieldOverride*/get x => y;
        }

        foo() {
          int y = /*severe:StaticTypeError*/new B<String>().x;
          String z = new B<String>().x;
        }
    '''
    });

    testChecker('5', {
      '/main.dart': '''
        abstract class I<E> {
          String m(a, String f(v, T e));
        }

        abstract class A<E> implements I<E> {
          const A();
          String m(a, String f(v, T e));
        }

        abstract class M {
          int y;
        }

        class B<E> extends A<E> implements M {
          const B();
          int get y => 0;

          m(a, f(v, T e)) {}
        }

        foo () {
          int y = /*severe:StaticTypeError*/new B().m(null, null);
          String z = new B().m(null, null);
        }
    '''
    });
  });

  testChecker('infer type regardless of declaration order or cycles', {
    '/b.dart': '''
        import 'main.dart';

        class B extends A { }
      ''',
    '/main.dart': '''
        import 'b.dart';
        class C extends B {
          get x;
        }
        class A {
          int get x;
        }
        foo () {
          int y = new C().x;
          String y = /*severe:StaticTypeError*/new C().x;
        }
    '''
  });

  // Note: this is a regression test for a non-deterministic behavior we used to
  // have with inference in library cycles. If you see this test flake out,
  // change `test` to `skip_test` and reopen bug #48.
  testChecker('infer types on generic instantiations in library cycle', {
    '/a.dart': '''
          import 'main.dart';
        abstract class I<E> {
          A<E> m(a, String f(v, int e));
        }
      ''',
    '/main.dart': '''
          import 'a.dart';

        abstract class A<E> implements I<E> {
          const A();

          E value;
        }

        abstract class M {
          int y;
        }

        class B<E> extends A<E> implements M {
          const B();
          int get y => 0;

          m(a, f(v, int e)) {}
        }

        foo () {
          int y = /*severe:StaticTypeError*/new B<String>().m(null, null).value;
          String z = new B<String>().m(null, null).value;
        }
    '''
  });

  group('do not infer overridden fields that explicitly say dynamic', () {
    testChecker('infer', {
      '/main.dart': '''
          class A {
            int x = 2;
          }

          class B implements A {
            /*severe:InvalidMethodOverride*/dynamic get x => 3;
          }

          foo() {
            String y = /*info:DynamicCast*/new B().x;
            int z = /*info:DynamicCast*/new B().x;
          }
      '''
    });
  });

  testChecker('conflicts can happen', {
    '/main.dart': '''
        class I1 {
          int x;
        }
        class I2 extends I1 {
          int y;
        }

        class A {
          final I1 a;
        }

        class B {
          final I2 a;
        }

        class C1 implements A, B {
          /*severe:InvalidMethodOverride*/get a => null;
        }

        // Still ambiguous
        class C2 implements B, A {
          /*severe:InvalidMethodOverride*/get a => null;
        }
    '''
  });

  testChecker('conflicts can happen 2', {
    '/main.dart': '''
        class I1 {
          int x;
        }
        class I2 {
          int y;
        }

        class I3 implements I1, I2 {
          int x;
          int y;
        }

        class A {
          final I1 a;
        }

        class B {
          final I2 a;
        }

        class C1 implements A, B {
          I3 get a => null;
        }

        class C2 implements A, B {
          /*severe:InvalidMethodOverride*/get a => null;
        }
    '''
  });

  testChecker(
      'infer from RHS only if it wont conflict with overridden fields', {
    '/main.dart': '''
        class A {
          var x;
        }

        class B implements A {
          var x = 2;
        }

        foo() {
          String y = /*info:DynamicCast*/new B().x;
          int z = /*info:DynamicCast*/new B().x;
        }
    '''
  });

  testChecker(
      'infer from RHS only if it wont conflict with overridden fields 2', {
    '/main.dart': '''
        class A {
          final x;
        }

        class B implements A {
          final x = 2;
        }

        foo() {
          String y = /*severe:StaticTypeError*/new B().x;
          int z = new B().x;
        }
    '''
  });

  testChecker('infer correctly on multiple variables declared together', {
    '/main.dart': '''
        class A {
          var x, y = 2, z = "hi";
        }

        class B implements A {
          var x = 2, y = 3, z, w = 2;
        }

        foo() {
          String s;
          int i;

          s = /*info:DynamicCast*/new B().x;
          s = /*severe:StaticTypeError*/new B().y;
          s = new B().z;
          s = /*severe:StaticTypeError*/new B().w;

          i = /*info:DynamicCast*/new B().x;
          i = new B().y;
          i = /*severe:StaticTypeError*/new B().z;
          i = new B().w;
        }
    '''
  });

  testChecker('infer consts transitively', {
    '/b.dart': '''
        const b1 = 2;
      ''',
    '/a.dart': '''
        import 'main.dart';
        import 'b.dart';
        const a1 = m2;
        const a2 = b1;
      ''',
    '/main.dart': '''
        import 'a.dart';
        const m1 = a1;
        const m2 = a2;

        foo() {
          int i;
          i = m1;
        }
    '''
  });

  testChecker('infer statics transitively', {
    '/b.dart': '''
        final b1 = 2;
      ''',
    '/a.dart': '''
        import 'main.dart';
        import 'b.dart';
        final a1 = m2;
        class A {
          static final a2 = b1;
        }
      ''',
    '/main.dart': '''
        import 'a.dart';
        final m1 = a1;
        final m2 = A.a2;

        foo() {
          int i;
          i = m1;
        }
    '''
  });

  testChecker('infer statics transitively 2', {
    '/main.dart': '''
        const x1 = 1;
        final x2 = 1;
        final y1 = x1;
        final y2 = x2;

        foo() {
          int i;
          i = y1;
          i = y2;
        }
    '''
  });

  testChecker('infer statics transitively 3', {
    '/a.dart': '''
        const a1 = 3;
        const a2 = 4;
        class A {
          a3;
        }
      ''',
    '/main.dart': '''
        import 'a.dart' show a1, A;
        import 'a.dart' as p show a2, A;
        const t1 = 1;
        const t2 = t1;
        const t3 = a1;
        const t4 = p.a2;
        const t5 = A.a3;
        const t6 = p.A.a3;

        foo() {
          int i;
          i = t1;
          i = t2;
          i = t3;
          i = t4;
        }
    '''
  });

  testChecker('infer statics with method invocations', {
    '/a.dart': '''
        m3(String a, String b, [a1,a2]) {}
      ''',
    '/main.dart': '''
        import 'a.dart';
        class T {
          static final T foo = m1(m2(m3('', '')));
          static T m1(String m) { return null; }
          static String m2(e) { return ''; }
        }


    '''
  });

  testChecker('downwards inference: miscellaneous', {
    '/main.dart': '''
      typedef T Function2<S, T>(S x);
      class A<T> {
        Function2<T, T> x;
        A(this.x);
      }
      void main() {
          {  // Variables, nested literals
            var x = "hello";
            var y = 3;
            void f(List<Map<int, String>> l) {};
            f(/*info:InferredTypeLiteral*/[/*info:InferredTypeLiteral*/{y: x}]);
          }
          {
            int f(int x) {};
            A<int> a = /*info:InferredTypeAllocation*/new A(f);
          }
      }
      '''
  });

  group('downwards inference on instance creations', () {
    String info = 'info:InferredTypeAllocation';
    String code = '''
      class A<S, T> {
        S x;
        T y;
        A(this.x, this.y);
        A.named(this.x, this.y);
      }

      class B<S, T> extends A<T, S> {
        B(S y, T x) : super(x, y);
        B.named(S y, T x) : super.named(x, y);
      }

      class C<S> extends B<S, S> {
        C(S a) : super(a, a);
        C.named(S a) : super.named(a, a);
      }

      class D<S, T> extends B<T, int> {
        D(T a) : super(a, 3);
        D.named(T a) : super.named(a, 3);
      }

      class E<S, T> extends A<C<S>, T> {
        E(T a) : super(null, a);
      }

      class F<S, T> extends A<S, T> {
        F(S x, T y, {List<S> a, List<T> b}) : super(x, y);
        F.named(S x, T y, [S a, T b]) : super(a, b);
      }

      void main() {
        {
          A<int, String> a0 = /*$info*/new A(3, "hello");
          A<int, String> a1 = /*$info*/new A.named(3, "hello");
          A<int, String> a2 = new A<int, String>(3, "hello");
          A<int, String> a3 = new A<int, String>.named(3, "hello");
          A<int, String> a4 = /*severe:StaticTypeError*/new A<int, dynamic>(3, "hello");
          A<int, String> a5 = /*severe:StaticTypeError*/new A<dynamic, dynamic>.named(3, "hello");
        }
        {
          A<int, String> a0 = /*info:InferredTypeAllocation*/new A(/*severe:StaticTypeError*/"hello", /*severe:StaticTypeError*/3);
          A<int, String> a1 = /*info:InferredTypeAllocation*/new A.named(/*severe:StaticTypeError*/"hello", /*severe:StaticTypeError*/3);
        }
        {
          A<int, String> a0 = /*$info*/new B("hello", 3);
          A<int, String> a1 = /*$info*/new B.named("hello", 3);
          A<int, String> a2 = new B<String, int>("hello", 3);
          A<int, String> a3 = new B<String, int>.named("hello", 3);
          A<int, String> a4 = /*severe:StaticTypeError*/new B<String, dynamic>("hello", 3);
          A<int, String> a5 = /*severe:StaticTypeError*/new B<dynamic, dynamic>.named("hello", 3);
        }
        {
          A<int, String> a0 = /*info:InferredTypeAllocation*/new B(/*severe:StaticTypeError*/3, /*severe:StaticTypeError*/"hello");
          A<int, String> a1 = /*info:InferredTypeAllocation*/new B.named(/*severe:StaticTypeError*/3, /*severe:StaticTypeError*/"hello");
        }
        {
          A<int, int> a0 = /*$info*/new C(3);
          A<int, int> a1 = /*$info*/new C.named(3);
          A<int, int> a2 = new C<int>(3);
          A<int, int> a3 = new C<int>.named(3);
          A<int, int> a4 = /*severe:StaticTypeError*/new C<dynamic>(3);
          A<int, int> a5 = /*severe:StaticTypeError*/new C<dynamic>.named(3);
        }
        {
          A<int, int> a0 = /*info:InferredTypeAllocation*/new C(/*severe:StaticTypeError*/"hello");
          A<int, int> a1 = /*info:InferredTypeAllocation*/new C.named(/*severe:StaticTypeError*/"hello");
        }
        {
          A<int, String> a0 = /*$info*/new D("hello");
          A<int, String> a1 = /*$info*/new D.named("hello");
          A<int, String> a2 = new D<int, String>("hello");
          A<int, String> a3 = new D<String, String>.named("hello");
          A<int, String> a4 = /*severe:StaticTypeError*/new D<num, dynamic>("hello");
          A<int, String> a5 = /*severe:StaticTypeError*/new D<dynamic, dynamic>.named("hello");
        }
        {
          A<int, String> a0 = /*info:InferredTypeAllocation*/new D(/*severe:StaticTypeError*/3);
          A<int, String> a1 = /*info:InferredTypeAllocation*/new D.named(/*severe:StaticTypeError*/3);
        }
        { // Currently we only allow variable constraints.  Test that we reject.
          A<C<int>, String> a0 = /*severe:StaticTypeError*/new E("hello");
        }
        { // Check named and optional arguments
          A<int, String> a0 = /*$info*/new F(3, "hello", a: /*info:InferredTypeLiteral*/[3], b: /*info:InferredTypeLiteral*/["hello"]);
          A<int, String> a1 = /*info:InferredTypeAllocation*/new F(3, "hello", a: /*info:InferredTypeLiteral*/[/*severe:StaticTypeError*/"hello"], b: /*info:InferredTypeLiteral*/[/*severe:StaticTypeError*/3]);
          A<int, String> a2 = /*$info*/new F.named(3, "hello", 3, "hello");
          A<int, String> a3 = /*$info*/new F.named(3, "hello");
          A<int, String> a4 = /*info:InferredTypeAllocation*/new F.named(3, "hello", /*severe:StaticTypeError*/"hello", /*severe:StaticTypeError*/3);
          A<int, String> a5 = /*info:InferredTypeAllocation*/new F.named(3, "hello", /*severe:StaticTypeError*/"hello");
        }
      }
        ''';
    testChecker('infer downwards', {'/main.dart': code});
  });

  group('downwards inference on list literals', () {
    String info = "info:InferredTypeLiteral";
    String code = '''
      void foo([List<String> list1 = /*$info*/const [],
                List<String> list2 = /*info:InferredTypeLiteral*/const [/*severe:StaticTypeError*/42]]) {
      }

      void main() {
        {
          List<int> l0 = /*$info*/[];
          List<int> l1 = /*$info*/[3];
          List<int> l2 = /*info:InferredTypeLiteral*/[/*severe:StaticTypeError*/"hello"];
          List<int> l3 = /*info:InferredTypeLiteral*/[/*severe:StaticTypeError*/"hello", 3];
        }
        {
          List<dynamic> l0 = [];
          List<dynamic> l1 = [3];
          List<dynamic> l2 = ["hello"];
          List<dynamic> l3 = ["hello", 3];
        }
        {
          List<int> l0 = /*severe:StaticTypeError*/<num>[];
          List<int> l1 = /*severe:StaticTypeError*/<num>[3];
          List<int> l2 = /*severe:StaticTypeError*/<num>[/*severe:StaticTypeError*/"hello"];
          List<int> l3 = /*severe:StaticTypeError*/<num>[/*severe:StaticTypeError*/"hello", 3];
        }
        {
          Iterable<int> i0 = /*$info*/[];
          Iterable<int> i1 = /*$info*/[3];
          Iterable<int> i2 = /*info:InferredTypeLiteral*/[/*severe:StaticTypeError*/"hello"];
          Iterable<int> i3 = /*info:InferredTypeLiteral*/[/*severe:StaticTypeError*/"hello", 3];
        }
        {
          const List<int> c0 = /*$info*/const [];
          const List<int> c1 = /*$info*/const [3];
          const List<int> c2 = /*info:InferredTypeLiteral*/const [/*severe:StaticTypeError*/"hello"];
          const List<int> c3 = /*info:InferredTypeLiteral*/const [/*severe:StaticTypeError*/"hello", 3];
        }
      }
      ''';
    testChecker('infer downwards', {'/main.dart': code});
  });

  group('downwards inference on function arguments', () {
    String info = "info:InferredTypeLiteral";
    String code = '''
      void f0(List<int> a) {};
      void f1({List<int> a}) {};
      void f2(Iterable<int> a) {};
      void f3(Iterable<Iterable<int>> a) {};
      void f4({Iterable<Iterable<int>> a}) {};
      void main() {
        f0(/*$info*/[]);
        f0(/*$info*/[3]);
        f0(/*info:InferredTypeLiteral*/[/*severe:StaticTypeError*/"hello"]);
        f0(/*info:InferredTypeLiteral*/[/*severe:StaticTypeError*/"hello", 3]);

        f1(a: /*$info*/[]);
        f1(a: /*$info*/[3]);
        f1(a: /*$info*/[/*severe:StaticTypeError*/"hello"]);
        f1(a: /*$info*/[/*severe:StaticTypeError*/"hello", 3]);

        f2(/*$info*/[]);
        f2(/*$info*/[3]);
        f2(/*$info*/[/*severe:StaticTypeError*/"hello"]);
        f2(/*$info*/[/*severe:StaticTypeError*/"hello", 3]);

        f3(/*$info*/[]);
        f3(/*$info*/[/*$info*/[3]]);
        f3(/*$info*/[/*$info*/[/*severe:StaticTypeError*/"hello"]]);
        f3(/*$info*/[/*$info*/[/*severe:StaticTypeError*/"hello"], /*$info*/[3]]);

        f4(a: /*$info*/[]);
        f4(a: /*$info*/[/*$info*/[3]]);
        f4(a: /*$info*/[/*$info*/[/*severe:StaticTypeError*/"hello"]]);
        f4(a: /*$info*/[/*$info*/[/*severe:StaticTypeError*/"hello"], /*$info*/[3]]);
      }
      ''';
    testChecker('infer downwards', {'/main.dart': code});
  });

  group('downwards inference on constructor arguments', () {
    String info = "info:InferredTypeLiteral";
    String code = '''
      class F0 {
        F0(List<int> a) {};
      }
      class F1 {
        F1({List<int> a}) {};
      }
      class F2 {
        F2(Iterable<int> a) {};
      }
      class F3 {
        F3(Iterable<Iterable<int>> a) {};
      }
      class F4 {
        F4({Iterable<Iterable<int>> a}) {};
      }
      void main() {
        new F0(/*$info*/[]);
        new F0(/*$info*/[3]);
        new F0(/*info:InferredTypeLiteral*/[/*severe:StaticTypeError*/"hello"]);
        new F0(/*info:InferredTypeLiteral*/[/*severe:StaticTypeError*/"hello",
                                            3]);

        new F1(a: /*$info*/[]);
        new F1(a: /*$info*/[3]);
        new F1(a: /*$info*/[/*severe:StaticTypeError*/"hello"]);
        new F1(a: /*$info*/[/*severe:StaticTypeError*/"hello", 3]);

        new F2(/*$info*/[]);
        new F2(/*$info*/[3]);
        new F2(/*$info*/[/*severe:StaticTypeError*/"hello"]);
        new F2(/*$info*/[/*severe:StaticTypeError*/"hello", 3]);

        new F3(/*$info*/[]);
        new F3(/*$info*/[/*$info*/[3]]);
        new F3(/*$info*/[/*$info*/[/*severe:StaticTypeError*/"hello"]]);
        new F3(/*$info*/[/*$info*/[/*severe:StaticTypeError*/"hello"],
                         /*$info*/[3]]);

        new F4(a: /*$info*/[]);
        new F4(a: /*$info*/[/*$info*/[3]]);
        new F4(a: /*$info*/[/*$info*/[/*severe:StaticTypeError*/"hello"]]);
        new F4(a: /*$info*/[/*$info*/[/*severe:StaticTypeError*/"hello"],
                            /*$info*/[3]]);
      }
      ''';
    testChecker('infer downwards', {'/main.dart': code});
  });

  group('downwards inference on generic constructor arguments', () {
    String info = "info:InferredTypeLiteral";
    String code = '''
      class F0<T> {
        F0(List<T> a) {};
      }
      class F1<T> {
        F1({List<T> a}) {};
      }
      class F2<T> {
        F2(Iterable<T> a) {};
      }
      class F3<T> {
        F3(Iterable<Iterable<T>> a) {};
      }
      class F4<T> {
        F4({Iterable<Iterable<T>> a}) {};
      }
      void main() {
        new F0<int>(/*$info*/[]);
        new F0<int>(/*$info*/[3]);
        new F0<int>(/*info:InferredTypeLiteral*/[/*severe:StaticTypeError*/"hello"]);
        new F0<int>(/*info:InferredTypeLiteral*/[/*severe:StaticTypeError*/"hello",
                                            3]);

        new F1<int>(a: /*$info*/[]);
        new F1<int>(a: /*$info*/[3]);
        new F1<int>(a: /*$info*/[/*severe:StaticTypeError*/"hello"]);
        new F1<int>(a: /*$info*/[/*severe:StaticTypeError*/"hello", 3]);

        new F2<int>(/*$info*/[]);
        new F2<int>(/*$info*/[3]);
        new F2<int>(/*$info*/[/*severe:StaticTypeError*/"hello"]);
        new F2<int>(/*$info*/[/*severe:StaticTypeError*/"hello", 3]);

        new F3<int>(/*$info*/[]);
        new F3<int>(/*$info*/[/*$info*/[3]]);
        new F3<int>(/*$info*/[/*$info*/[/*severe:StaticTypeError*/"hello"]]);
        new F3<int>(/*$info*/[/*$info*/[/*severe:StaticTypeError*/"hello"],
                         /*$info*/[3]]);

        new F4<int>(a: /*$info*/[]);
        new F4<int>(a: /*$info*/[/*$info*/[3]]);
        new F4<int>(a: /*$info*/[/*$info*/[/*severe:StaticTypeError*/"hello"]]);
        new F4<int>(a: /*$info*/[/*$info*/[/*severe:StaticTypeError*/"hello"],
                            /*$info*/[3]]);

        new F3(/*$info*/[]);
        new F3(/*$info*/[[3]]);
        new F3(/*$info*/[["hello"]]);
        new F3(/*$info*/[["hello"], [3]]);

        new F4(a: /*$info*/[]);
        new F4(a: /*$info*/[[3]]);
        new F4(a: /*$info*/[["hello"]]);
        new F4(a: /*$info*/[["hello"], [3]]);
      }
      ''';
    testChecker('infer downwards', {'/main.dart': code});
  });

  group('downwards inference on map literals', () {
    String info = "info:InferredTypeLiteral";
    String code = '''
      void foo([Map<int, String> m1 = /*$info*/const {1: "hello"},
        Map<int, String> m1 = /*$info*/const {(/*severe:StaticTypeError*/"hello"): "world"}]) {
      }
      void main() {
        {
          Map<int, String> l0 = /*$info*/{};
          Map<int, String> l1 = /*$info*/{3: "hello"};
          Map<int, String> l2 = /*$info*/{(/*severe:StaticTypeError*/"hello"): "hello"};
          Map<int, String> l3 = /*$info*/{3: /*severe:StaticTypeError*/3};
          Map<int, String> l4 = /*$info*/{3:"hello", (/*severe:StaticTypeError*/"hello"): /*severe:StaticTypeError*/3};
        }
        {
          Map<dynamic, dynamic> l0 = {};
          Map<dynamic, dynamic> l1 = {3: "hello"};
          Map<dynamic, dynamic> l2 = {"hello": "hello"};
          Map<dynamic, dynamic> l3 = {3: 3};
          Map<dynamic, dynamic> l4 = {3:"hello", "hello": 3};
        }
        {
          Map<dynamic, String> l0 = /*$info*/{};
          Map<dynamic, String> l1 = /*$info*/{3: "hello"};
          Map<dynamic, String> l2 = /*$info*/{"hello": "hello"};
          Map<dynamic, String> l3 = /*$info*/{3: /*severe:StaticTypeError*/3};
          Map<dynamic, String> l4 = /*$info*/{3:"hello", "hello": /*severe:StaticTypeError*/3};
        }
        {
          Map<int, dynamic> l0 = /*$info*/{};
          Map<int, dynamic> l1 = /*$info*/{3: "hello"};
          Map<int, dynamic> l2 = /*$info*/{(/*severe:StaticTypeError*/"hello"): "hello"};
          Map<int, dynamic> l3 = /*$info*/{3: 3};
          Map<int, dynamic> l4 = /*$info*/{3:"hello", (/*severe:StaticTypeError*/"hello"): 3};
        }
        {
          Map<int, String> l0 = /*severe:StaticTypeError*/<num, dynamic>{};
          Map<int, String> l1 = /*severe:StaticTypeError*/<num, dynamic>{3: "hello"};
          Map<int, String> l3 = /*severe:StaticTypeError*/<num, dynamic>{3: 3};
        }
        {
          const Map<int, String> l0 = /*$info*/const {};
          const Map<int, String> l1 = /*$info*/const {3: "hello"};
          const Map<int, String> l2 = /*$info*/const {(/*severe:StaticTypeError*/"hello"): "hello"};
          const Map<int, String> l3 = /*$info*/const {3: /*severe:StaticTypeError*/3};
          const Map<int, String> l4 = /*$info*/const {3:"hello", (/*severe:StaticTypeError*/"hello"): /*severe:StaticTypeError*/3};
        }
      }
      ''';
    testChecker('infer downwards', {'/main.dart': code});
  });

  testChecker('downwards inference on function expressions', {
    '/main.dart': '''
      typedef T Function2<S, T>(S x);

      void main () {
        {
          Function2<int, String> l0 = /*info:InferredTypeClosure*/(int x) => null;
          Function2<int, String> l1 = (int x) => "hello";
          Function2<int, String> l2 = /*severe:StaticTypeError*/(String x) => "hello";
          Function2<int, String> l3 = /*severe:StaticTypeError*/(int x) => 3;
          Function2<int, String> l4 = /*info:InferredTypeClosure*/(int x) {return /*severe:StaticTypeError*/3;};
        }
        {
          Function2<int, String> l0 = /*info:InferredTypeClosure, info:InferredTypeClosure*/(x) => null;
          Function2<int, String> l1 = /*info:InferredTypeClosure*/(x) => "hello";
          Function2<int, String> l2 = /*info:InferredTypeClosure, severe:StaticTypeError*/(x) => 3;
          Function2<int, String> l3 = /*info:InferredTypeClosure, info:InferredTypeClosure*/(x) {return /*severe:StaticTypeError*/3;};
          Function2<int, String> l4 = /*info:InferredTypeClosure, info:InferredTypeClosure*/(x) {return /*severe:StaticTypeError*/x;};
        }
        {
          Function2<int, List<String>> l0 = /*info:InferredTypeClosure*/(int x) => null;
          Function2<int, List<String>> l1 = (int x) => /*info:InferredTypeLiteral*/["hello"];
          Function2<int, List<String>> l2 = /*severe:StaticTypeError*/(String x) => /*info:InferredTypeLiteral*/["hello"];
          Function2<int, List<String>> l3 = (int x) => /*info:InferredTypeLiteral*/[/*severe:StaticTypeError*/3];
          Function2<int, List<String>> l4 = /*info:InferredTypeClosure*/(int x) {return /*info:InferredTypeLiteral*/[/*severe:StaticTypeError*/3];};
        }
        {
          Function2<int, int> l0 = /*info:InferredTypeClosure*/(x) => x;
          Function2<int, int> l1 = /*info:InferredTypeClosure*/(x) => x+1;
          Function2<int, String> l2 = /*info:InferredTypeClosure, severe:StaticTypeError*/(x) => x;
          Function2<int, String> l3 = /*info:InferredTypeClosure, info:InferredTypeClosure*/(x) => /*info:DynamicCast, info:DynamicInvoke*/x.substring(3);
          Function2<String, String> l4 = /*info:InferredTypeClosure*/(x) => x.substring(3);
        }
      }
      '''
  });

  testChecker('downwards inference initializing formal, default formal', {
    '/main.dart': '''
      typedef T Function2<S, T>([S x]);
      class Foo {
        List<int> x;
        Foo([this.x = /*info:InferredTypeLiteral*/const [1]]);
        Foo.named([List<int> x = /*info:InferredTypeLiteral*/const [1]]);
      }
      void f([List<int> l = /*info:InferredTypeLiteral*/const [1]]) {}
// We do this inference in an early task but don't preserve the infos.
      Function2<List<int>, String> g = /*pass should be info:InferredTypeClosure*/([llll = /*info:InferredTypeLiteral*/const [1]]) => "hello";
'''
  });

  testChecker('downwards inference async/await', {
    '/main.dart': '''
      import 'dart:async';
      Future<int> test() async {
        List<int> l0 = /*warning:DownCastComposite should be pass*/await /*pass should be info:InferredTypeLiteral*/[3];
        List<int> l1 = await /*info:InferredTypeAllocation*/new Future.value(/*info:InferredTypeLiteral*/[3]);
        '''
  });

  testChecker('downwards inference foreach', {
    '/main.dart': '''
      import 'dart:async';
      void main() {
        for(int x in /*info:InferredTypeLiteral*/[1, 2, 3]) {
        }
        await for(int x in /*info:InferredTypeAllocation*/new Stream()) {
        }
      }
        '''
  });

  testChecker('downwards inference yield/yield*', {
    '/main.dart': '''
      import 'dart:async';
        Stream<List<int>> foo() async* {
          yield /*info:InferredTypeLiteral*/[];
          yield /*severe:StaticTypeError*/new Stream();
          yield* /*severe:StaticTypeError*/[];
          yield* /*info:InferredTypeAllocation*/new Stream();
        }

        Iterable<Map<int, int>> bar() sync* {
          yield /*info:InferredTypeLiteral*/{};
          yield /*severe:StaticTypeError*/new List();
          yield* /*severe:StaticTypeError*/{};
          yield* /*info:InferredTypeAllocation*/new List();
        }
        '''
  });

  testChecker('downwards inference, annotations', {
    '/main.dart': '''
        class Foo {
          const Foo(List<String> l);
          const Foo.named(List<String> l);
        }
        @Foo(/*info:InferredTypeLiteral*/const [])
        class Bar {}
        @Foo.named(/*info:InferredTypeLiteral*/const [])
        class Baz {}
        '''
  });

  testChecker('downwards inference, assignment statements', {
    '/main.dart': '''
    void main() {
      List<int> l;
      l = /*info:InferredTypeLiteral*/[/*severe:StaticTypeError*/"hello"];
      l = (l = /*info:InferredTypeLiteral*/[1]);
    }
'''
  });

  testChecker('inferred initializing formal checks default value', {
    '/main.dart': '''
      class Foo {
        var x = 1;
        Foo([this.x = /*severe:StaticTypeError*/"1"]);
      }'''
  });

  group('quasi-generics', () {
    testChecker('dart:math min/max', {
      '/main.dart': '''
        import 'dart:math';

        void printInt(int x) => print(x);
        void printDouble(double x) => print(x);

        num myMax(num x, num y) => max(x, y);

        main() {
          // Okay if static types match.
          printInt(max(1, 2));
          printInt(min(1, 2));
          printDouble(max(1.0, 2.0));
          printDouble(min(1.0, 2.0));

          // No help for user-defined functions from num->num->num.
          printInt(/*info:DownCastImplicit*/myMax(1, 2));
          printInt(myMax(1, 2) as int);

          // Mixing int and double means return type is num.
          printInt(/*info:DownCastImplicit*/max(1, 2.0));
          printInt(/*info:DownCastImplicit*/min(1, 2.0));
          printDouble(/*info:DownCastImplicit*/max(1, 2.0));
          printDouble(/*info:DownCastImplicit*/min(1, 2.0));

          // Types other than int and double are not accepted.
          printInt(
              /*info:DownCastImplicit*/min(
                  /*severe:StaticTypeError*/"hi",
                  /*severe:StaticTypeError*/"there"));
        }
    '''
    });

    testChecker('Iterable and Future', {
      '/main.dart': '''
        import 'dart:async';

        Future<int> make(int x) => (/*info:InferredTypeAllocation*/new Future(() => x));

        main() {
          Iterable<Future<int>> list = <int>[1, 2, 3].map(make);
          Future<List<int>> results = Future.wait(list);
          Future<String> results2 = results.then((List<int> list) 
            => list.fold('', (String x, int y) => x + y.toString()));
        }
    '''
    });
  });
}
