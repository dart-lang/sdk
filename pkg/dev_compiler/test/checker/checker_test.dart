// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/// General type checking tests
library dev_compiler.test.checker_test;

import 'package:unittest/unittest.dart';

import 'package:dev_compiler/src/testing.dart';

import '../test_util.dart';

void main() {
  configureTest();

  test('conversion and dynamic invoke', () {
    testChecker({
      '/main.dart': '''
      class A {
        String x = "hello world";
      }

      void foo(String str) {
        print(str);
      }

      void bar(a) {
        foo(/*info:DownCast,warning:DynamicInvoke*/a.x);
      }

      void main() => bar(new A());
    '''
    });
  });

  test('Primitives', () {
    testChecker({
      '/main.dart': '''
        int /*severe:InvalidVariableDeclaration*/a;
        double /*severe:InvalidVariableDeclaration*/b;
        num c;

        class A {
          int a;
          double b;
          num c;

          static int /*severe:InvalidVariableDeclaration*/x;
          static double /*severe:InvalidVariableDeclaration*/y;
          static num z;
        }

        void foo(int w, [int x = /*severe:StaticTypeError*/null, int /*severe:InvalidVariableDeclaration*/y, int z = 0]) {
        }

        void bar(int w, {int x = /*severe:StaticTypeError*/null, int /*severe:InvalidVariableDeclaration*/y, int z: 0}) {
        }

        void main() {
          int /*severe:InvalidVariableDeclaration*/x;
          double /*severe:InvalidVariableDeclaration*/y;
          num z;
          bool b;

          // int is non-nullable
          // TODO(vsm): This should be an error, not a warning.
          x = /*warning:DownCastLiteral*/null;
          x = 42;
          x = /*info:DownCast*/z;

          // double is non-nullable
          // TODO(vsm): This should be an error, not a warning.
          y = /*warning:DownCastLiteral*/null;
          y = /*severe:StaticTypeError*/42;
          y = 42.0;
          y = /*info:DownCast*/z;

          // num is nullable
          z = null;
          z = x;
          z = y;

          // bool is nullable
          b = null;
          b = true;
        }
      '''
    }, nonnullableTypes: <String>['int', 'double']);
  });

  test('Primitives and generics', () {
    testChecker({
      '/main.dart': '''
        class A<T> {
          // TODO(vsm): This needs a static info indicating a runtime
          // check at construction.
          T x;

          // TODO(vsm): Should this be a different type of DownCast?
          T foo() => /*warning:DownCastLiteral*/null;

          void bar() {
            int /*severe:InvalidVariableDeclaration*/x;
            num y;
            // TODO(vsm): This should be a runtime check:
            // Transformed to: T z = cast(null, T)
            T /*severe:InvalidVariableDeclaration*/z;
          }

          void baz(T x, [T /*severe:InvalidVariableDeclaration*/y, T z = /*severe:StaticTypeError*/null]) {
          }
        }

        class B<T extends List> {
          T x;

          // T cannot be primitive.
          T foo() => null;
        }

        class C<T extends num> {
          // TODO(vsm): This needs a static info indicating a runtime
          // check at construction.
          T x;

          // TODO(vsm): Should this be a different type of DownCast?
          T foo() => /*warning:DownCastLiteral*/null;
        }
      '''
    }, nonnullableTypes: <String>['int', 'double']);
  });

  test('Constructors', () {
    testChecker({
      '/main.dart': '''
      const num z = 25;
      Object obj = "world";

      class A {
        int x;
        String y;

        A(this.x) : this.y = /*severe:StaticTypeError*/42;

        A.c1(p): this.x = /*info:DownCast*/z, this.y = /*info:DownCast*/p;

        A.c2(this.x, this.y);

        A.c3(/*severe:InvalidParameterDeclaration*/num this.x, String this.y);
      }

      class B extends A {
        B() : super(/*severe:StaticTypeError*/"hello");

        B.c2(int x, String y) : super.c2(/*severe:StaticTypeError*/y, 
                                         /*severe:StaticTypeError*/x);

        B.c3(num x, Object y) : super.c3(x, /*info:DownCast*/y);
      }

      void main() {
         A a = new A.c2(/*info:DownCast*/z, /*severe:StaticTypeError*/z);
         var b = new B.c2(/*severe:StaticTypeError*/"hello", /*info:DownCast*/obj);
      }
   '''
    });
  });

  test('Unbound variable', () {
    testChecker({
      '/main.dart': '''
      void main() {
         dynamic y = /*pass should be severe:StaticTypeError*/unboundVariable;
      }
   '''
    });
  });

  test('Unbound type name', () {
    testChecker({
      '/main.dart': '''
      void main() {
         /*pass should be severe:StaticTypeError*/AToB y;
      }
   '''
    });
  });

  test('Ground type subtyping: dynamic is top', () {
    testChecker({
      '/main.dart': '''

      class A {}
      class B extends A {}

      void main() {
         dynamic y;
         Object o;
         int i = 0;
         double d = 0.0;
         num n;
         A a;
         B b;
         y = o;
         y = i;
         y = d;
         y = n;
         y = a;
         y = b;
      }
   '''
    });
  });

  test('Ground type subtyping: dynamic downcasts', () {
    testChecker({
      '/main.dart': '''

      class A {}
      class B extends A {}

      void main() {
         dynamic y;
         Object o;
         int i = 0;
         double d = 0.0;
         num n;
         A a;
         B b;
         o = y;
         i = /*info:DownCast*/y;
         d = /*info:DownCast*/y;
         n = /*info:DownCast*/y;
         a = /*info:DownCast*/y;
         b = /*info:DownCast*/y;
      }
   '''
    });
  });

  test('Ground type subtyping: assigning a class', () {
    testChecker({
      '/main.dart': '''

      class A {}
      class B extends A {}

      void main() {
         dynamic y;
         Object o;
         int i = 0;
         double d = 0.0;
         num n;
         A a;
         B b;
         y = a;
         o = a;
         i = /*severe:StaticTypeError*/a;
         d = /*severe:StaticTypeError*/a;
         n = /*severe:StaticTypeError*/a;
         a = a;
         b = /*info:DownCast*/a;
      }
   '''
    });
  });

  test('Ground type subtyping: assigning a subclass', () {
    testChecker({
      '/main.dart': '''

      class A {}
      class B extends A {}
      class C extends A {}

      void main() {
         dynamic y;
         Object o;
         int i = 0;
         double d = 0.0;
         num n;
         A a;
         B b;
         C c;
         y = b;
         o = b;
         i = /*severe:StaticTypeError*/b;
         d = /*severe:StaticTypeError*/b;
         n = /*severe:StaticTypeError*/b;
         a = b;
         b = b;
         c = /*severe:StaticTypeError*/b;
      }
   '''
    });
  });

  test('Ground type subtyping: interfaces', () {
    testChecker({
      '/main.dart': '''

      class A {}
      class B extends A {}
      class C extends A {}
      class D extends B implements C {}

      void main() {
         A top;
         B left;
         C right;
         D bot;
         {
           top = top;
           top = left;
           top = right;
           top = bot;
         }
         {
           left = /*info:DownCast*/top;
           left = left;
           left = /*severe:StaticTypeError*/right;
           left = bot;
         }
         {
           right = /*info:DownCast*/top;
           right = /*severe:StaticTypeError*/left;
           right = right;
           right = bot;
         }
         {
           bot = /*info:DownCast*/top;
           bot = /*info:DownCast*/left;
           bot = /*info:DownCast*/right;
           bot = bot;
         }
      }
   '''
    });
  });

  test('Function typing and subtyping: int and object', () {
    testChecker({
      '/main.dart': '''

      typedef Object Top(int x);      // Top of the lattice
      typedef int Left(int x);        // Left branch
      typedef int Left2(int x);       // Left branch
      typedef Object Right(Object x); // Right branch
      typedef int Bot(Object x);      // Bottom of the lattice

      Object top(int x) => x;
      int left(int x) => x;
      Object right(Object x) => x;
      int _bot(Object x) => /*info:DownCast*/x;
      int bot(Object x) => x as int;

      void main() {
        { // Check typedef equality
          Left f = left;
          Left2 g = f;
        }
        // TODO(leafp) Decide on ClosureWrap vs DownCast (or error).
        {
          Top f;
          f = top;
          f = left;
          f = right;
          f = bot;
        }
        {
          Left f;
          f = /*warning:ClosureWrap*/top;
          f = left;
          f = /*warning:ClosureWrap*/right; // Should we reject this?
          f = bot;
        }
        {
          Right f;
          f = /*warning:ClosureWrap*/top;
          f = /*warning:ClosureWrap*/left; // Should we reject this?
          f = right;
          f = bot;
        }
        {
          Bot f;
          f = /*warning:ClosureWrap*/top;
          f = /*warning:ClosureWrap*/left;
          f = /*warning:ClosureWrap*/right;
          f = bot;
        }
      }
   '''
    });
  });

  test('Function typing and subtyping: classes', () {
    testChecker({
      '/main.dart': '''

      class A {}
      class B extends A {}

      typedef A Top(B x);   // Top of the lattice
      typedef B Left(B x);  // Left branch
      typedef B Left2(B x); // Left branch
      typedef A Right(A x); // Right branch
      typedef B Bot(A x);   // Bottom of the lattice

      B left(B x) => x;
      B _bot(A x) => /*info:DownCast*/x;
      B bot(A x) => x as B;
      A top(B x) => x;
      A right(A x) => x;

      void main() {
        { // Check typedef equality
          Left f = left;
          Left2 g = f;
        }
        {
          Top f;
          f = top;
          f = left;
          f = right;
          f = bot;
        }
        {
          Left f;
          f = /*warning:ClosureWrap*/top;
          f = left;
          f = /*warning:ClosureWrap*/right; // Should we reject this?
          f = bot;
        }
        {
          Right f;
          f = /*warning:ClosureWrap*/top;
          f = /*warning:ClosureWrap*/left; // Should we reject this?
          f = right;
          f = bot;
        }
        {
          Bot f;
          f = /*warning:ClosureWrap*/top;
          f = /*warning:ClosureWrap*/left;
          f = /*warning:ClosureWrap*/right;
          f = bot;
        }
      }
   '''
    });
  });

  test('Function typing and subtyping: dynamic', () {
    testChecker({
      '/main.dart': '''

      class A {}

      typedef dynamic Top(A x);         // Top of the lattice
      typedef A Left(A x);              // Left branch
      typedef dynamic Right(dynamic x); // Right branch
      typedef A Bot(dynamic x);         // Bottom of the lattice

      dynamic top(A x) => x;
      A left(A x) => x;
      dynamic right(dynamic x) => x;
      A bot(dynamic x) => /*info:DownCast*/x;

      void main() {
        {
          Top f;
          f = top;
          f = left;
          f = right;
          f = bot;
        }
        {
          Left f;
          f = /*warning:ClosureWrap*/top;
          f = left;
          f = /*warning:ClosureWrap*/right;
          f = bot;
        }
        {
          Right f;
          f = /*warning:ClosureWrap*/top;
          f = /*warning:ClosureWrap*/left;
          f = right;
          f = bot;
        }
        {
          Bot f;
          f = /*warning:ClosureWrap*/top;
          f = /*warning:ClosureWrap*/left;
          f = /*warning:ClosureWrap*/right;
          f = bot;
        }
      }
   '''
    });
  });

  test('Function typing and subtyping: function literal variance', () {
    testChecker({
      '/main.dart': '''

      class A {}
      class B extends A {}

      typedef T Function2<S, T>(S z);

      A top(B x) => x;
      B left(B x) => x;
      A right(A x) => x;
      B bot(A x) => x as B;

      void main() {
        {
          Function2<B, A> f;
          f = top;
          f = left;
          f = right;
          f = bot;
        }
        {
          Function2<B, B> f;
          f = /*warning:ClosureWrap*/top;
          f = left;
          f = /*warning:ClosureWrap*/right; // Should we reject this?
          f = bot;
        }
        {
          Function2<A, A> f;
          f = /*warning:ClosureWrap*/top;
          f = /*warning:ClosureWrap*/left; // Should we reject this?
          f = right;
          f = bot;
        }
        {
          Function2<A, B> f;
          f = /*warning:ClosureWrap*/top;
          f = /*warning:ClosureWrap*/left;
          f = /*warning:ClosureWrap*/right;
          f = bot;
        }
      }
   '''
    });
  });

  test('Function typing and subtyping: function variable variance', () {
    testChecker({
      '/main.dart': '''

      class A {}
      class B extends A {}

      typedef T Function2<S, T>(S z);

      void main() {
        {
          Function2<B, A> top;
          Function2<B, B> left;
          Function2<A, A> right;
          Function2<A, B> bot;

          top = right;
          top = bot;
          top = top;
          top = left;

          left = /*warning:ClosureWrap*/top;
          left = left;
          left = /*warning:ClosureWrap*/right; // Should we reject this?
          left = bot;

          right = /*warning:ClosureWrap*/top;
          right = /*warning:ClosureWrap*/left; // Should we reject this?
          right = right;
          right = bot;

          bot = /*warning:ClosureWrap*/top;
          bot = /*warning:ClosureWrap*/left;
          bot = /*warning:ClosureWrap*/right;
          bot = bot;
        }
      }
   '''
    });
  });

  test('Function typing and subtyping: higher order function literals', () {
    testChecker({
      '/main.dart': '''

      class A {}
      class B extends A {}

      typedef T Function2<S, T>(S z);

      typedef A BToA(B x);  // Top of the base lattice
      typedef B AToB(A x);  // Bot of the base lattice

      BToA top(AToB f) => f;
      AToB left(AToB f) => f;
      BToA right(BToA f) => f;
      AToB _bot(BToA f) => /*warning:ClosureWrap*/f;
      AToB bot(BToA f) => f as AToB;

      Function2<B, A> top(AToB f) => f;
      Function2<A, B> left(AToB f) => f;
      Function2<B, A> right(BToA f) => f;
      Function2<A, B> _bot(BToA f) => /*warning:ClosureWrap*/f;
      Function2<A, B> bot(BToA f) => f as Function2<A, B>;


      BToA top(Function2<A, B> f) => f;
      AToB left(Function2<A, B> f) => f;
      BToA right(Function2<B, A> f) => f;
      AToB _bot(Function2<B, A> f) => /*warning:ClosureWrap*/f;
      AToB bot(Function2<B, A> f) => f as AToB;

      void main() {
        {
          Function2<AToB, BToA> f; // Top
          f = top;
          f = left;
          f = right;
          f = bot;
        }
        {
          Function2<AToB, AToB> f; // Left
          f = /*warning:ClosureWrap*/top;
          f = left;
          f = /*warning:ClosureWrap*/right; // Should we reject this?
          f = bot;
        }
        {
          Function2<BToA, BToA> f; // Right
          f = /*warning:ClosureWrap*/top;
          f = /*warning:ClosureWrap*/left; // Should we reject this?
          f = right;
          f = bot;
        }
        {
          Function2<BToA, AToB> f; // Bot
          f = bot;
          f = /*warning:ClosureWrap*/left;
          f = /*warning:ClosureWrap*/top;
          f = /*warning:ClosureWrap*/left;
        }
      }
   '''
    });
  });

  test('Function typing and subtyping: higher order function variables', () {
    testChecker({
      '/main.dart': '''

      class A {}
      class B extends A {}

      typedef T Function2<S, T>(S z);

      void main() {
        {
          Function2<Function2<A, B>, Function2<B, A>> top;
          Function2<Function2<B, A>, Function2<B, A>> right;
          Function2<Function2<A, B>, Function2<A, B>> left;
          Function2<Function2<B, A>, Function2<A, B>> bot;

          top = right;
          top = bot;
          top = top;
          top = left;

          left = /*pass should be warning:ClosureWrap*/top;
          left = left;
          left = /*pass should be severe:StaticTypeError*/right;
          left = bot;

          right = /*pass should be warning:ClosureWrap*/top;
          right = /*pass should be severe:StaticTypeError*/left;
          right = right;
          right = bot;

          bot = /*pass should be warning:ClosureWrap*/top;
          bot = /*pass should be warning:ClosureWrap*/left;
          bot = /*pass should be warning:ClosureWrap*/right;
          bot = bot;
        }
      }
   '''
    });
  });

  test('Function typing and subtyping: named and optional parameters', () {
    testChecker({
      '/main.dart': '''

      class A {}

      typedef A FR(A x);
      typedef A FO([A x]);
      typedef A FN({A x});
      typedef A FRR(A x, A y);
      typedef A FRO(A x, [A y]);
      typedef A FRN(A x, {A n});
      typedef A FOO([A x, A y]);
      typedef A FNN({A x, A y});
      typedef A FNNN({A z, A y, A x});

      void main() {
         FR r;
         FO o;
         FN n;
         FRR rr;
         FRO ro;
         FRN rn;
         FOO oo;
         FNN nn;
         FNNN nnn;

         r = r;
         r = o;
         r = /*severe:StaticTypeError*/n;
         r = /*severe:StaticTypeError*/rr;
         r = ro;
         r = rn;
         r = oo;
         r = /*severe:StaticTypeError*/nn;
         r = /*severe:StaticTypeError*/nnn;

         o = /*severe:StaticTypeError*/r;
         o = o;
         o = /*severe:StaticTypeError*/n;
         o = /*severe:StaticTypeError*/rr;
         o = /*severe:StaticTypeError*/ro;
         o = /*severe:StaticTypeError*/rn;
         o = oo;
         o = /*severe:StaticTypeError*/nn
         o = /*severe:StaticTypeError*/nnn;

         n = /*severe:StaticTypeError*/r;
         n = /*severe:StaticTypeError*/o;
         n = n;
         n = /*severe:StaticTypeError*/rr;
         n = /*severe:StaticTypeError*/ro;
         n = /*severe:StaticTypeError*/rn;
         n = /*severe:StaticTypeError*/oo;
         n = nn;
         n = nnn;

         rr = /*severe:StaticTypeError*/r;
         rr = /*severe:StaticTypeError*/o;
         rr = /*severe:StaticTypeError*/n;
         rr = rr;
         rr = ro;
         rr = /*severe:StaticTypeError*/rn;
         rr = oo;
         rr = /*severe:StaticTypeError*/nn;
         rr = /*severe:StaticTypeError*/nnn;

         ro = /*severe:StaticTypeError*/r;
         ro = /*severe:StaticTypeError*/o;
         ro = /*severe:StaticTypeError*/n;
         ro = /*severe:StaticTypeError*/rr;
         ro = ro;
         ro = /*severe:StaticTypeError*/rn;
         ro = oo;
         ro = /*severe:StaticTypeError*/nn;
         ro = /*severe:StaticTypeError*/nnn;

         rn = /*severe:StaticTypeError*/r;
         rn = /*severe:StaticTypeError*/o;
         rn = /*severe:StaticTypeError*/n;
         rn = /*severe:StaticTypeError*/rr;
         rn = /*severe:StaticTypeError*/ro;
         rn = rn;
         rn = /*severe:StaticTypeError*/oo;
         rn = /*severe:StaticTypeError*/nn;
         rn = /*severe:StaticTypeError*/nnn;

         oo = /*severe:StaticTypeError*/r;
         oo = /*severe:StaticTypeError*/o;
         oo = /*severe:StaticTypeError*/n;
         oo = /*severe:StaticTypeError*/rr;
         oo = /*severe:StaticTypeError*/ro;
         oo = /*severe:StaticTypeError*/rn;
         oo = oo;
         oo = /*severe:StaticTypeError*/nn;
         oo = /*severe:StaticTypeError*/nnn;

         nn = /*severe:StaticTypeError*/r;
         nn = /*severe:StaticTypeError*/o;
         nn = /*severe:StaticTypeError*/n;
         nn = /*severe:StaticTypeError*/rr;
         nn = /*severe:StaticTypeError*/ro;
         nn = /*severe:StaticTypeError*/rn;
         nn = /*severe:StaticTypeError*/oo;
         nn = nn;
         nn = nnn;

         nnn = /*severe:StaticTypeError*/r;
         nnn = /*severe:StaticTypeError*/o;
         nnn = /*severe:StaticTypeError*/n;
         nnn = /*severe:StaticTypeError*/rr;
         nnn = /*severe:StaticTypeError*/ro;
         nnn = /*severe:StaticTypeError*/rn;
         nnn = /*severe:StaticTypeError*/oo;
         nnn = /*severe:StaticTypeError*/nn;
         nnn = nnn;
      }
   '''
    });
  });

  test('Function subtyping: objects with call methods', () {
    testChecker({
      '/main.dart': '''

      typedef int I2I(int x);
      typedef num N2N(num x);
      class A {
         int call(int x) => x;
      }
      class B {
         num call(num x) => x;
      }
      int i2i(int x) => x;
      num n2n(num x) => x;
      void main() {
         {
           I2I f;
           f = new A();
           f = /*severe:StaticTypeError*/new B();
           f = i2i;
           f = /*warning:ClosureWrap*/n2n;
           f = /*warning:DownCast*/(i2i as Object);
           f = /*warning:DownCast*/(n2n as Function);
         }
         {
           N2N f;
           f = /*severe:StaticTypeError*/new A();
           f = new B();
           f = /*warning:ClosureWrap*/i2i;
           f = n2n;
           f = /*warning:DownCast*/(i2i as Object);
           f = /*warning:DownCast*/(n2n as Function);
         }
         {
           A f;
           f = new A();
           f = /*severe:StaticTypeError*/new B();
           f = /*severe:StaticTypeError*/i2i;
           f = /*severe:StaticTypeError*/n2n;
           f = /*info:DownCast*/(i2i as Object);
           f = /*info:DownCast*/(n2n as Function);
         }
         {
           B f;
           f = /*severe:StaticTypeError*/new A();
           f = new B();
           f = /*severe:StaticTypeError*/i2i;
           f = /*severe:StaticTypeError*/n2n;
           f = /*info:DownCast*/(i2i as Object);
           f = /*info:DownCast*/(n2n as Function);
         }
         {
           Function f;
           f = new A();
           f = new B();
           f = i2i;
           f = n2n;
           f = /*info:DownCast*/(i2i as Object);
           f = (n2n as Function);
         }
      }
   '''
    });
  });

  test('Function typing and subtyping: void', () {
    testChecker({
      '/main.dart': '''

      class A {
        void bar() => null;
        void foo() => bar; // allowed
      }
   '''
    });
  });

  test('Closure wrapping of literals', () {
    testChecker({
      '/main.dart': '''
      typedef T F<T>(T t1, T t2);
      typedef dynamic D(t1, t2);

      void main() {
        F f1 = (x, y) => x + y;
        F<int> f2 = /*warning:ClosureWrapLiteral*/(x, y) => x + y;
        D f3 = (x, y) => x + y;
        Function f4 = (x, y) => x + y;
        f2 = /*warning:ClosureWrap*/f1;
        f1 = /*warning:ClosureWrapLiteral*/(int x, int y) => x + y;
        f2 = /*severe:StaticTypeError*/(int x) => -x;
      }
   '''
    });
  });

  test('Generic subtyping: invariance', () {
    testChecker({
      '/main.dart': '''

      class A {}
      class B extends A {}
      class C implements A {}

      class L<T> {}
      class M<T> extends L<T> {}
      class N extends M<A> {}

      void main() {
        L<A> lOfAs;
        L<B> lOfBs;
        L<C> lOfCs;

        M<A> mOfAs;
        M<B> mOfBs;
        M<C> mOfCs;

        N ns;

        // L<T> <: L<S> iff S = dynamic or S=T
        lOfAs = lOfAs;
        lOfAs = /*severe:StaticTypeError*/lOfBs;
        lOfAs = /*severe:StaticTypeError*/lOfCs;

        // M<S> <: L<S>
        lOfAs = mOfAs;
        lOfAs = /*severe:StaticTypeError*/mOfBs;
        lOfAs = /*severe:StaticTypeError*/mOfCs;

        // N <: L<A>
        lOfAs = ns;

        // L<T> <: L<S> iff S = dynamic or  S=T
        lOfBs = /*severe:StaticTypeError*/lOfAs;
        lOfBs = lOfBs;
        lOfBs = /*severe:StaticTypeError*/lOfCs;

        // M<S> <: L<S>
        lOfBs = /*severe:StaticTypeError*/mOfAs;
        lOfBs = mOfBs;
        lOfBs = /*severe:StaticTypeError*/mOfCs;

        // N </: L<B>
        lOfBs = /*severe:StaticTypeError*/ns;

        // L<T> <: L<S> iff S = dynamic or  S=T
        lOfCs = /*severe:StaticTypeError*/lOfAs;
        lOfCs = /*severe:StaticTypeError*/lOfBs;
        lOfCs = lOfCs;

        // M<S> <: L<S>
        lOfCs = /*severe:StaticTypeError*/mOfAs;
        lOfCs = /*severe:StaticTypeError*/mOfBs;
        lOfCs = mOfCs;

        // N </: L<C>
        lOfCs = /*severe:StaticTypeError*/ns;

        // M<T> <: L<S> iff S = dynamic or S=T
        mOfAs = /*info:DownCast*/lOfAs;
        mOfAs = /*severe:StaticTypeError*/lOfBs;
        mOfAs = /*severe:StaticTypeError*/lOfCs;

        // M<S> <: M<S> iff S = dynamic or S=T
        mOfAs = mOfAs;
        mOfAs = /*severe:StaticTypeError*/mOfBs;
        mOfAs = /*severe:StaticTypeError*/mOfCs;

        // N <: M<A>
        mOfAs = ns;

        // M<T> <: L<S> iff S = dynamic or S=T
        mOfBs = /*severe:StaticTypeError*/lOfAs;
        mOfBs = /*info:DownCast*/lOfBs;
        mOfBs = /*severe:StaticTypeError*/lOfCs;

        // M<S> <: M<S> iff S = dynamic or S=T
        mOfBs = /*severe:StaticTypeError*/mOfAs;
        mOfBs = mOfBs;
        mOfBs = /*severe:StaticTypeError*/mOfCs;

        // N </: M<B>
        mOfBs = /*severe:StaticTypeError*/ns;

        // M<T> <: L<S> iff S = dynamic or S=T
        mOfCs = /*severe:StaticTypeError*/lOfAs;
        mOfCs = /*severe:StaticTypeError*/lOfBs;
        mOfCs = /*info:DownCast*/lOfCs;

        // M<S> <: M<S> iff S = dynamic or S=T
        mOfCs = /*severe:StaticTypeError*/mOfAs;
        mOfCs = /*severe:StaticTypeError*/mOfBs;
        mOfCs = mOfCs;

        // N </: L<C>
        mOfCs = /*severe:StaticTypeError*/ns;

        // Concrete subclass subtyping
        ns = /*info:DownCast*/lOfAs;
        ns = /*severe:StaticTypeError*/lOfBs;
        ns = /*severe:StaticTypeError*/lOfCs;
        ns = /*info:DownCast*/mOfAs;
        ns = /*severe:StaticTypeError*/mOfBs;
        ns = /*severe:StaticTypeError*/mOfCs;
        ns = ns;
      }
   '''
    }, covariantGenerics: false, relaxedCasts: false);
  });

  test('Generic subtyping: covariant raw types', () {
    testChecker({
      '/main.dart': '''

      class A {}
      class B extends A {}
      class C implements A {}

      class L<T> {}
      class M<T> extends L<T> {}
      class N extends M<A> {}

      void main() {
        L lRaw;
        L<dynamic> lOfDynamics;
        L<A> lOfAs;
        L<B> lOfBs;
        L<C> lOfCs;

        M mRaw;
        M<dynamic> mOfDynamics;
        M<A> mOfAs;
        M<B> mOfBs;
        M<C> mOfCs;

        N ns;

        // Raw type subtyping
        lRaw = lRaw;
        lRaw = lOfDynamics;
        lRaw = lOfAs;
        lRaw = lOfBs;
        lRaw = lOfCs;
        lRaw = mRaw;
        lRaw = mOfDynamics;
        lRaw = mOfAs;
        lRaw = mOfBs;
        lRaw = mOfCs;
        lRaw = ns;

        // L<dynamic> == L
        lOfDynamics = lRaw;
        lOfDynamics = lOfDynamics;
        lOfDynamics = lOfAs;
        lOfDynamics = lOfBs;
        lOfDynamics = lOfCs;
        lOfDynamics = mRaw;
        lOfDynamics = mOfDynamics;
        lOfDynamics = mOfAs;
        lOfDynamics = mOfBs;
        lOfDynamics = mOfCs;
        lOfDynamics = ns;

        // L<T> <: L<S> iff S = dynamic or S=T
        lOfAs = /*warning:DownCastDynamic*/lRaw;
        lOfAs = /*warning:DownCastDynamic*/lOfDynamics;

        // M<dynamic> </:/> L<A>
        lOfAs = /*severe:StaticTypeError*/mRaw;
        lOfAs = /*severe:StaticTypeError*/mOfDynamics;

        // L<T> <: L<S> iff S = dynamic or S=T
        lOfBs = /*warning:DownCastDynamic*/lRaw;
        lOfBs = /*warning:DownCastDynamic*/lOfDynamics;

        // M<dynamic> </:/> L<B>
        lOfBs = /*severe:StaticTypeError*/mRaw;
        lOfBs = /*severe:StaticTypeError*/mOfDynamics;

        // L<T> <: L<S> iff S = dynamic or S=T
        lOfCs = /*warning:DownCastDynamic*/lRaw;
        lOfCs = /*warning:DownCastDynamic*/lOfDynamics;

        // M<dynamic> </:/> L<C>
        lOfCs = /*severe:StaticTypeError*/mRaw;
        lOfCs = /*severe:StaticTypeError*/mOfDynamics;

        // Raw type subtyping
        mRaw = /*info:DownCast*/lRaw;
        mRaw = /*info:DownCast*/lOfDynamics;
        mRaw = /*severe:StaticTypeError*/lOfAs;
        mRaw = /*severe:StaticTypeError*/lOfBs;
        mRaw = /*severe:StaticTypeError*/lOfCs;
        mRaw = mRaw;
        mRaw = mOfDynamics;
        mRaw = mOfAs;
        mRaw = mOfBs;
        mRaw = mOfCs;
        mRaw = ns;

        // M<dynamic> == M
        mOfDynamics = /*info:DownCast*/lRaw;
        mOfDynamics = /*info:DownCast*/lOfDynamics;
        mOfDynamics = /*severe:StaticTypeError*/lOfAs;
        mOfDynamics = /*severe:StaticTypeError*/lOfBs;
        mOfDynamics = /*severe:StaticTypeError*/lOfCs;
        mOfDynamics = mRaw;
        mOfDynamics = mOfDynamics;
        mOfDynamics = mOfAs;
        mOfDynamics = mOfBs;
        mOfDynamics = mOfCs;
        mOfDynamics = ns;

        // M<T> <: L<S> iff S = dynamic or S=T
        mOfAs = /*info:DownCast*/lRaw;
        mOfAs = /*info:DownCast*/lOfDynamics;

        // M<dynamic> </:/> M<A>
        mOfAs = /*warning:DownCastDynamic*/mRaw;
        mOfAs = /*warning:DownCastDynamic*/mOfDynamics;

        // M<T> <: L<S> iff S = dynamic or S=T
        mOfBs = /*info:DownCast*/lRaw;
        mOfBs = /*info:DownCast*/lOfDynamics;

        // M<dynamic> </:/> M<B>
        mOfBs = /*warning:DownCastDynamic*/mRaw;
        mOfBs = /*warning:DownCastDynamic*/mOfDynamics;

        // M<T> <: L<S> iff S = dynamic or S=T
        mOfCs = /*info:DownCast*/lRaw;
        mOfCs = /*info:DownCast*/lOfDynamics;

        // M<dynamic> </:/> M<C>
        mOfCs = /*warning:DownCastDynamic*/mRaw;
        mOfCs = /*warning:DownCastDynamic*/mOfDynamics;

        // Concrete subclass subtyping
        ns = /*info:DownCast*/lRaw;
        ns = /*info:DownCast*/lOfDynamics;
        ns = /*info:DownCast*/mRaw;
        ns = /*info:DownCast*/mOfDynamics;
      }
   '''
    }, covariantGenerics: false, relaxedCasts: false);
  });

  test('Generic subtyping: covariant raw types with multiple parameters', () {
    testChecker({
      '/main.dart': '''

      class A {}

      class L<S, T> {}
      class M<S, T> extends L<S, T> {}

      void main() {
        L lRaw;
        /*pass should be severe:StaticTypeError*/L<dynamic> lOfD_;
        /*pass should be severe:StaticTypeError*/L<A> lOfA_;
        L<dynamic, A> lOfDA;
        L<A, dynamic> lOfAD;
        L<dynamic, dynamic> lOfDD;
        L<A, A> lOfAA;

        // This is the currently implemented lattice.
        // We may wish to change this to a flat lattice with
        // L<dynamic, dynamic> as the top element
        //
        //    L<dynamic, dynamic>
        //      /           \
        //  L<dynamic, A>  L<A, dynamic>
        //      \           /
        //         L<A, A>

        // L == L<dynamic, dynamic>
        lRaw = lRaw;
        lRaw = lOfD_;
        lRaw = lOfA_;
        lRaw = lOfDA;
        lRaw = lOfAD;
        lRaw = lOfDD;
        lRaw = lOfAA;

        // L<dynamic> == L<dynamic, dynamic>
        lOfD_ = lRaw;
        lOfD_ = lOfD_;
        lOfD_ = lOfA_;
        lOfD_ = lOfDA;
        lOfD_ = lOfAD;
        lOfD_ = lOfDD;
        lOfD_ = lOfAA;

        // L<dynamic, dynamic>
        lOfDD = lRaw;
        lOfDD = lOfD_;
        lOfDD = lOfA_;
        lOfDD = lOfDA;
        lOfDD = lOfAD;
        lOfDD = lOfDD;
        lOfDD = lOfAA;

        // L<dynamic, A>
        lOfDA = /*warning:DownCastDynamic*/lRaw;
        lOfDA = /*warning:DownCastDynamic*/lOfD_;
        lOfDA = /*warning:DownCastDynamic*/lOfA_;
        lOfDA = lOfDA;
        lOfDA = /*severe:StaticTypeError*/lOfAD;
        lOfDA = /*warning:DownCastDynamic*/lOfDD;
        lOfDA = lOfAA;

        // L<A, dynamic>
        lOfAD = /*warning:DownCastDynamic*/lRaw;
        lOfAD = /*warning:DownCastDynamic*/lOfD_;
        lOfAD = /*warning:DownCastDynamic*/lOfA_;
        lOfAD = /*severe:StaticTypeError*/lOfDA;
        lOfAD = lOfAD;
        lOfAD = /*warning:DownCastDynamic*/lOfDD;
        lOfAD = lOfAA;

        // L<A> == L<dynamic, dynamic>
        lOfA_ = lRaw;
        lOfA_ = lOfD_;
        lOfA_ = lOfA_;
        lOfA_ = lOfDA;
        lOfA_ = lOfAD;
        lOfA_ = lOfDD;
        lOfA_ = lOfAA;

        // L<A, A>
        lOfAA = /*warning:DownCastDynamic*/lRaw;
        lOfAA = /*warning:DownCastDynamic*/lOfD_;
        lOfAA = /*warning:DownCastDynamic*/lOfA_;
        lOfAA = /*warning:DownCastDynamic*/lOfDA;
        lOfAA = /*warning:DownCastDynamic*/lOfAD;
        lOfAA = /*warning:DownCastDynamic*/lOfDD;
        lOfAA = lOfAA;
      }
   '''
    }, covariantGenerics: false, relaxedCasts: false);
  });

  test('Covariant generic subtyping: invariance', () {
    testChecker({
      '/main.dart': '''

      class A {}
      class B extends A {}
      class C implements A {}

      class L<T> {}
      class M<T> extends L<T> {}
      class N extends M<A> {}

      void main() {
        L<A> lOfAs;
        L<B> lOfBs;
        L<C> lOfCs;

        M<A> mOfAs;
        M<B> mOfBs;
        M<C> mOfCs;

        N ns;

        // L<T> <: L<S> iff S <: T
        lOfAs = lOfAs;
        lOfAs = lOfBs;
        lOfAs = lOfCs;

        // M<T> <: L<S> iff T <: S
        lOfAs = mOfAs;
        lOfAs = mOfBs;
        lOfAs = mOfCs;

        // N <: L<A>
        lOfAs = ns;

        // L<T> <: L<S> iff S <: T
        lOfBs = /*info:DownCast*/lOfAs;
        lOfBs = lOfBs;
        lOfBs = /*severe:StaticTypeError*/lOfCs;

        // M<T> <: L<S> iff T <: S
        lOfBs = /*severe:StaticTypeError*/mOfAs;
        lOfBs = mOfBs;
        lOfBs = /*severe:StaticTypeError*/mOfCs;

        // N </: L<B>
        lOfBs = /*severe:StaticTypeError*/ns;

        // L<T> <: L<S> iff S <: T
        lOfCs = /*info:DownCast*/lOfAs;
        lOfCs = /*severe:StaticTypeError*/lOfBs;
        lOfCs = lOfCs;

        // M<T> <: L<S> iff T <: S
        lOfCs = /*severe:StaticTypeError*/mOfAs;
        lOfCs = /*severe:StaticTypeError*/mOfBs;
        lOfCs = mOfCs;

        // N </: L<C>
        lOfCs = /*severe:StaticTypeError*/ns;

        // M<T> <: L<S> iff T <: S
        mOfAs = /*info:DownCast*/lOfAs;
        mOfAs = /*severe:StaticTypeError*/lOfBs;
        mOfAs = /*severe:StaticTypeError*/lOfCs;

        // M<T> <: M<S> iff T <: S
        mOfAs = mOfAs;
        mOfAs = mOfBs;
        mOfAs = mOfCs;

        // N <: M<A>
        mOfAs = ns;

        // M<T> <: L<S> iff T <: S
        mOfBs = /*info:DownCast*/lOfAs;
        mOfBs = /*info:DownCast*/lOfBs;
        mOfBs = /*severe:StaticTypeError*/lOfCs;

        // M<T> <: M<S> iff T <: S
        mOfBs = /*info:DownCast*/mOfAs;
        mOfBs = mOfBs;
        mOfBs = /*severe:StaticTypeError*/mOfCs;

        // N </: M<B>
        mOfBs = /*severe:StaticTypeError*/ns;

        // M<T> <: L<S> iff T <: S
        mOfCs = /*info:DownCast*/lOfAs;
        mOfCs = /*severe:StaticTypeError*/lOfBs;
        mOfCs = /*info:DownCast*/lOfCs;

        // M<T> <: M<S> iff T :< S
        mOfCs = /*info:DownCast*/mOfAs;
        mOfCs = /*severe:StaticTypeError*/mOfBs;
        mOfCs = mOfCs;

        // N </: L<C>
        mOfCs = /*severe:StaticTypeError*/ns;

        // Concrete subclass subtyping
        ns = /*info:DownCast*/lOfAs;
        ns = /*severe:StaticTypeError*/lOfBs;
        ns = /*severe:StaticTypeError*/lOfCs;
        ns = /*info:DownCast*/mOfAs;
        ns = /*severe:StaticTypeError*/mOfBs;
        ns = /*severe:StaticTypeError*/mOfCs;
        ns = ns;
      }
   '''
    }, covariantGenerics: true, relaxedCasts: false);
  });

  test('Relaxed casts', () {
    testChecker({
      '/main.dart': '''

      class A {}

      class L<T> {}
      class M<T> extends L<T> {}
      //     L<dynamic>
      //    /          \
      // M<dynamic> L<Object>
      //    |      /    /
      // M<Object>    L<A>
      //    \        /
      //       M<A>
      // In normal Dart, there are additional edges
      //  from M<A> to M<dynamic>
      //  from L<Object> to M<dynamic>
      //  from L<Object> to L<dynamic>
      //  from L<A> to M<dynamic>
      //  from L<A> to L<dynamic>
      void main() {
        L lOfDs;
        L<Object> lOfOs;
        L<A> lOfAs;

        M mOfDs;
        M<Object> mOfOs;
        M<A> mOfAs;

        {
          lOfDs = mOfDs;
          lOfDs = mOfOs;
          lOfDs = mOfAs;
          lOfDs = lOfDs;
          lOfDs = lOfOs;
          lOfDs = lOfAs;
        }
        {
          lOfOs = /*warning:DownCastDynamic*/mOfDs;
          lOfOs = mOfOs;
          lOfOs = mOfAs;
          lOfOs = /*warning:DownCastDynamic*/lOfDs;
          lOfOs = lOfOs;
          lOfOs = lOfAs;
        }
        {
          lOfAs = /*warning:DownCastDynamic*/mOfDs;
          lOfAs = /*severe:StaticTypeError*/mOfOs;
          lOfAs = mOfAs;
          lOfAs = /*warning:DownCastDynamic*/lOfDs;
          lOfAs = /*info:DownCast*/lOfOs;
          lOfAs = lOfAs;
        }
        {
          mOfDs = mOfDs;
          mOfDs = mOfOs;
          mOfDs = mOfAs;
          mOfDs = /*info:DownCast*/lOfDs;
          mOfDs = /*info:DownCast*/lOfOs;
          mOfDs = /*info:DownCast*/lOfAs;
        }
        {
          mOfOs = /*warning:DownCastDynamic*/mOfDs;
          mOfOs = mOfOs;
          mOfOs = mOfAs;
          mOfOs = /*info:DownCast*/lOfDs;
          mOfOs = /*info:DownCast*/lOfOs;
          mOfOs = /*severe:StaticTypeError*/lOfAs;
        }
        {
          mOfAs = /*warning:DownCastDynamic*/mOfDs;
          mOfAs = /*info:DownCast*/mOfOs;
          mOfAs = mOfAs;
          mOfAs = /*info:DownCast*/lOfDs;
          mOfAs = /*info:DownCast*/lOfOs;
          mOfAs = /*info:DownCast*/lOfAs;
        }

      }
   '''
    }, covariantGenerics: true, relaxedCasts: true);
  });

  test('Subtyping literals', () {
    testChecker({
      '/main.dart': '''
          test() {
            Iterable i1 = [1, 2, 3];
            i1 = <int>[1, 2, 3];

            List l1 = [1, 2, 3];
            l1 = <int>[1, 2, 3];

            Iterable<int> i2 = /*warning:DownCastLiteral*/[1, 2, 3];
            i2 = /*warning:DownCastDynamic*/i1;
            i2 = /*warning:DownCastDynamic*/l1;
            i2 = <int>[1, 2, 3];

            List<int> l2 = /*warning:DownCastLiteral*/[1, 2, 3];
            l2 = /*info:DownCast*/i1;
            l2 = /*warning:DownCastDynamic*/l1;

            l2 = /*warning:DownCastExact*/new List();
            l2 = /*warning:DownCastExact*/new List(10);
            l2 = /*warning:DownCastExact*/new List.filled(10, 42);
          }
   '''
    });
  });

  test('Type checking literals', () {
    testChecker({
      '/main.dart': '''
          test() {
            num n = 3;
            int i = 3;
            String s = "hello";
            {
               List<int> l = <int>[i];
               l = <int>[/*severe:StaticTypeError*/s];
               l = <int>[/*info:DownCast*/n];
               l = <int>[i, /*info:DownCast*/n, /*severe:StaticTypeError*/s];
            }
            {
               List l = [i];
               l = [s];
               l = [n];
               l = [i, n, s];
            }
            {
               Map<String, int> m = <String, int>{s: i};
               m = <String, int>{s: /*severe:StaticTypeError*/s};
               m = <String, int>{s: /*info:DownCast*/n};
               m = <String, int>{s: i,
                                 s: /*info:DownCast*/n,
                                 s: /*severe:StaticTypeError*/s};
            }
           // TODO(leafp): We can't currently test for key errors since the
           // error marker binds to the entire entry.
            {
               Map m = {s: i};
               m = {s: s};
               m = {s: n};
               m = {s: i,
                    s: n,
                    s: s};
               m = {i: s,
                    n: s,
                    s: s};
            }
          }
   '''
    });
  });

  test('casts in constant contexts', () {
    String mk(String error) => '''
          class A {
            static const num n = 3.0;
            static const int i = /*$error*/n;
            final int fi;
            const A(num a) : this.fi = /*$error*/a;
          }
          class B extends A {
            const B(Object a) : super(/*$error*/a);
          }
          void foo(Object o) {
            var a = const A(/*$error*/o);
          }
     ''';
    testChecker({'/main.dart': mk("severe:StaticTypeError")},
        allowConstCasts: false);
    testChecker({'/main.dart': mk("info:DownCast")}, allowConstCasts: true);
  });

  test('casts in conditionals', () {
    testChecker({
      '/main.dart': '''
          main() {
            bool b = true;
            num x = b ? 1 : 2.3;
            int y = /*info:DownCast*/b ? 1 : 2.3;
            String z = !b ? "hello" : null;
            z = b ? null : "hello";
          }
      '''
    });
  });

  test('redirecting constructor', () {
    testChecker({
      '/main.dart': '''
          class A {
            A(A x) {}
            A.two() : this(/*severe:StaticTypeError*/3);
          }
       '''
    });
  });

  test('super constructor', () {
    testChecker({
      '/main.dart': '''
          class A { A(A x) {} }
          class B extends A {
            B() : super(/*severe:StaticTypeError*/3);
          }
       '''
    });
  });

  test('field/field override', () {
    testChecker({
      '/main.dart': '''
          class A {}
          class B extends A {}
          class C extends B {}

          class Base {
            B f1;
            B f2;
            B f3;
            B f4;
          }

          class Child extends Base {
            /*severe:InvalidMethodOverride*/A f1; // invalid for getter
            /*severe:InvalidMethodOverride*/C f2; // invalid for setter
            var f3;
            /*severe:InvalidMethodOverride*/dynamic f4;
          }
       '''
    }, inferFromOverrides: true);

    testChecker({
      '/main.dart': '''
          class A {}
          class B extends A {}
          class C extends B {}

          class Base {
            B f1;
            B f2;
            B f3;
            B f4;
          }

          class Child extends Base {
            /*severe:InvalidMethodOverride*/A f1; // invalid for getter
            /*severe:InvalidMethodOverride*/C f2; // invalid for setter
            /*severe:InferableOverride*/var f3;
            /*severe:InvalidMethodOverride*/dynamic f4;
          }
       '''
    }, inferFromOverrides: false);
  });

  test('getter/getter override', () {
    testChecker({
      '/main.dart': '''
          class A {}
          class B extends A {}
          class C extends B {}

          abstract class Base {
            B get f1;
            B get f2;
            B get f3;
            B get f4;
          }

          class Child extends Base {
            /*severe:InvalidMethodOverride*/A get f1 => null;
            C get f2 => null;
            get f3 => null;
            /*severe:InvalidMethodOverride*/dynamic get f4 => null;
          }
       '''
    }, inferFromOverrides: true);

    testChecker({
      '/main.dart': '''
          class A {}
          class B extends A {}
          class C extends B {}

          abstract class Base {
            B get f1;
            B get f2;
            B get f3;
            B get f4;
          }

          class Child extends Base {
            /*severe:InvalidMethodOverride*/A get f1 => null;
            C get f2 => null;
            /*severe:InferableOverride*/get f3 => null;
            /*severe:InvalidMethodOverride*/dynamic get f4 => null;
          }
       '''
    }, inferFromOverrides: false);
  });

  test('field/getter override', () {
    testChecker({
      '/main.dart': '''
          class A {}
          class B extends A {}
          class C extends B {}

          abstract class Base {
            B f1;
            B f2;
            B f3;
            B f4;
          }

          class Child extends Base {
            /*severe:InvalidMethodOverride*/A get f1 => null;
            C get f2 => null;
            get f3 => null;
            /*severe:InvalidMethodOverride*/dynamic get f4 => null;
          }
       '''
    }, inferFromOverrides: true);
  });

  test('setter/setter override', () {
    testChecker({
      '/main.dart': '''
          class A {}
          class B extends A {}
          class C extends B {}

          abstract class Base {
            void set f1(B value);
            void set f2(B value);
            void set f3(B value);
            void set f4(B value);
            void set f5(B value);
          }

          class Child extends Base {
            void set f1(A value) {}
            /*severe:InvalidMethodOverride*/void set f2(C value) {}
            void set f3(value) {}
            void set f4(dynamic value) {}
            set f5(B value) {}
          }
       '''
    });
  });

  test('field/setter override', () {
    testChecker({
      '/main.dart': '''
          class A {}
          class B extends A {}
          class C extends B {}

          class Base {
            B f1;
            B f2;
            B f3;
            B f4;
            B f5;
          }

          class Child extends Base {
            B get f1 => null;
            B get f2 => null;
            B get f3 => null;
            B get f4 => null;
            B get f5 => null;

            void set f1(A value) {}
            /*severe:InvalidMethodOverride*/void set f2(C value) {}
            void set f3(value) {}
            void set f4(dynamic value) {}
            set f5(B value) {}
          }
       '''
    });
  });

  test('method override', () {
    testChecker({
      '/main.dart': '''
          class A {}
          class B extends A {}
          class C extends B {}

          class Base {
            B m1(B a);
            B m2(B a);
            B m3(B a);
            B m4(B a);
            B m5(B a);
            B m6(B a);
          }

          class Child extends Base {
            /*severe:InvalidMethodOverride*/A m1(A value) {}
            /*severe:InvalidMethodOverride*/C m2(C value) {}
            /*severe:InvalidMethodOverride*/A m3(C value) {}
            C m4(A value) {}
            m5(value) {}
            /*severe:InvalidMethodOverride*/dynamic m6(dynamic value) {}
          }
       '''
    }, inferFromOverrides: true);
  });

  test('binary operators', () {
    testChecker({
      '/main.dart': '''
          class A {
            A operator *(B b) {}
            A operator /(B b) {}
            A operator ~/(B b) {}
            A operator %(B b) {}
            A operator +(B b) {}
            A operator -(B b) {}
            A operator <<(B b) {}
            A operator >>(B b) {}
            A operator &(B b) {}
            A operator ^(B b) {}
            A operator |(B b) {}
          }

          class B {
            A operator -(B b) {}
          }

          foo() => new A();

          test() {
            A a = new A();
            B b = new B();
            var c = foo();
            a = a * b;
            a = a * /*pass should be info:DownCast*/c;
            a = a / b;
            a = a ~/ b;
            a = a % b;
            a = a + b;
            a = a + /*pass should be severe:StaticTypeError*/a;
            a = a - b;
            b = /*severe:StaticTypeError*/b - b;
            a = a << b;
            a = a >> b;
            a = a & b;
            a = a ^ b;
            a = a | b;
            c = (/*pass should be warning:DynamicInvoke*/c + b);
          }
       '''
    });
  });

  test('compound assignments', () {
    testChecker({
      '/main.dart': '''
          class A {
            A operator *(B b) {}
            A operator /(B b) {}
            A operator ~/(B b) {}
            A operator %(B b) {}
            A operator +(B b) {}
            A operator -(B b) {}
            A operator <<(B b) {}
            A operator >>(B b) {}
            A operator &(B b) {}
            A operator ^(B b) {}
            A operator |(B b) {}
          }

          class B {
            A operator -(B b) {}
          }

          foo() => new A();

          test() {
            int x = 0;
            x += 5;
            (/*severe:StaticTypeError*/x += 3.14);

            double y = 0.0;
            y += 5;
            y += 3.14;

            num z = 0;
            z += 5;
            z += 3.14;

            x = /*info:DownCast*/x + z;
            x += /*info:DownCast*/z;
            y = /*info:DownCast*/y + z;
            y += /*info:DownCast*/z;

            dynamic w = 42;
            x += /*info:DownCast*/w;
            y += /*info:DownCast*/w;
            z += /*info:DownCast*/w;

            A a = new A();
            B b = new B();
            var c = foo();
            a = a * b;
            a *= b;
            a *= /*info:DownCast*/c;
            a /= b;
            a ~/= b;
            a %= b;
            a += b;
            a += /*severe:StaticTypeError*/a;
            a -= b;
            (/*severe:StaticTypeError*/b -= b);
            a <<= b;
            a >>= b;
            a &= b;
            a ^= b;
            a |= b;
            (/*warning:DynamicInvoke*/c += b);
          }
       '''
    });
  });

  test('super call placement', () {
    testChecker({
      '/main.dart': '''
          class Base {
            var x;
            Base() : x = print('Base.1') { print('Base.2'); }
          }

          class Derived extends Base {
            var y, z;
            Derived()
                : y = print('Derived.1'),
                  /*severe:InvalidSuperInvocation*/super(),
                  z = print('Derived.2') {
              print('Derived.3');
            }
          }

          class Valid extends Base {
            var y, z;
            Valid()
                : y = print('Valid.1'),
                  z = print('Valid.2'),
                  super() {
              print('Valid.3');
            }
          }

          class AlsoValid extends Base {
            AlsoValid() : super();
          }

          main() => new Derived();
       '''
    });
  });

  test('for loop variable', () {
    testChecker({
      '/main.dart': '''
          foo() {
            for (int i = 0; i < 10; i++) {
              i = /*severe:StaticTypeError*/"hi";
            }
          }
          bar() {
            for (var i = 0; i < 10; i++) {
              int j = i + 1;
            }
          }
        '''
    });
  });

  group('invalid overrides', () {
    test('child override', () {
      testChecker({
        '/main.dart': '''
            class A {}
            class B {}

            class Base {
                A f;
            }

            class T1 extends Base {
              /*severe:InvalidMethodOverride*/B get f => null;
            }

            class T2 extends Base {
              /*severe:InvalidMethodOverride*/set f(B b) => null;
            }

            class T3 extends Base {
              /*severe:InvalidMethodOverride*/final B f;
            }
            class T4 extends Base {
              // two: one for the getter one for the setter.
              /*severe:InvalidMethodOverride,severe:InvalidMethodOverride*/B f;
            }
         '''
      });

      testChecker({
        '/main.dart': '''
            class A {}
            class B {}

            class Base {
                m(A a) {}
            }

            class Test extends Base {
                /*severe:InvalidMethodOverride*/m(B a) {}
            }
         '''
      });
    });
    test('grandchild override', () {
      testChecker({
        '/main.dart': '''
            class A {}
            class B {}

            class Grandparent {
                m(A a) {}
            }
            class Parent extends Grandparent {
            }

            class Test extends Parent {
                /*severe:InvalidMethodOverride*/m(B a) {}
            }
         '''
      });
    });

    test('double override', () {
      testChecker({
        '/main.dart': '''
            class A {}
            class B {}

            class Grandparent {
                m(A a) {}
            }
            class Parent extends Grandparent {
                m(A a) {}
            }

            class Test extends Parent {
                // Reported only once
                /*severe:InvalidMethodOverride*/m(B a) {}
            }
         '''
      });

      testChecker({
        '/main.dart': '''
            class A {}
            class B {}

            class Grandparent {
                m(A a) {}
            }
            class Parent extends Grandparent {
                /*severe:InvalidMethodOverride*/m(B a) {}
            }

            class Test extends Parent {
                m(B a) {}
            }
         '''
      });
    });

    test('mixin override to base', () {
      testChecker({
        '/main.dart': '''
            class A {}
            class B {}

            class Base {
                m(A a) {}
            }

            class M1 {
                m(B a) {}
            }

            class M2 {}

            class T1 extends Base with /*severe:InvalidMethodOverride*/M1 {}
            class T2 extends Base with /*severe:InvalidMethodOverride*/M1, M2 {}
            class T3 extends Base with M2, /*severe:InvalidMethodOverride*/M1 {}
         '''
      });
    });

    test('mixin override to mixin', () {
      testChecker({
        '/main.dart': '''
            class A {}
            class B {}

            class Base {
            }

            class M1 {
                m(B a) {}
            }

            class M2 {
                m(A a) {}
            }

            class T1 extends Base with M1, /*severe:InvalidMethodOverride*/M2 {}
         '''
      });
    });

    test('no duplicate mixin override', () {
      // This is a regression test for a bug in an earlier implementation were
      // names were hiding errors if the first mixin override looked correct,
      // but subsequent ones did not.
      testChecker({
        '/main.dart': '''
            class A {}
            class B {}

            class Base {
                m(A a) {}
            }

            class M1 {
                m(A a) {}
            }

            class M2 {
                m(B a) {}
            }

            class M3 {
                m(B a) {}
            }

            class T1 extends Base
                with M1, /*severe:InvalidMethodOverride*/M2, M3 {}
         '''
      });
    });

    test('class override of interface', () {
      testChecker({
        '/main.dart': '''
            class A {}
            class B {}

            abstract class I {
                m(A a);
            }

            class T1 implements I {
                /*severe:InvalidMethodOverride*/m(B a) {}
            }
         '''
      });
    });

    test('base class override to child interface', () {
      testChecker({
        '/main.dart': '''
            class A {}
            class B {}

            abstract class I {
                m(A a);
            }

            class Base {
                m(B a) {}
            }


            class T1 /*severe:InvalidMethodOverride*/extends Base implements I {
            }
         '''
      });
    });

    test('mixin override of interface', () {
      testChecker({
        '/main.dart': '''
            class A {}
            class B {}

            abstract class I {
                m(A a);
            }

            class M {
                m(B a) {}
            }

            class T1 extends Object with /*severe:InvalidMethodOverride*/M
               implements I {}
         '''
      });
    });

    test('no errors if subclass correctly overrides base and interface', () {
      // This is a case were it is incorrect to say that the base class
      // incorrectly overrides the interface.
      testChecker({
        '/main.dart': '''
            class A {}
            class B {}

            class Base {
                m(A a) {}
            }

            class I1 {
                m(B a) {}
            }

            class T1 /*severe:InvalidMethodOverride*/extends Base
                implements I1 {}

            class T2 extends Base implements I1 {
                m(a) {}
            }

            class T3 extends Object with /*severe:InvalidMethodOverride*/Base
                implements I1 {}

            class T4 extends Object with Base implements I1 {
                m(a) {}
            }
         '''
      });
    });

    group('class override of grand interface', () {
      test('interface of interface of child', () {
        testChecker({
          '/main.dart': '''
              class A {}
              class B {}

              abstract class I1 {
                  m(A a);
              }
              abstract class I2 implements I1 {}

              class T1 implements I2 {
                  /*severe:InvalidMethodOverride*/m(B a) {}
              }
           '''
        });
      });
      test('superclass of interface of child', () {
        testChecker({
          '/main.dart': '''
              class A {}
              class B {}

              abstract class I1 {
                  m(A a);
              }
              abstract class I2 extends I1 {}

              class T1 implements I2 {
                  /*severe:InvalidMethodOverride*/m(B a) {}
              }
           '''
        });
      });
      test('mixin of interface of child', () {
        testChecker({
          '/main.dart': '''
              class A {}
              class B {}

              abstract class M1 {
                  m(A a);
              }
              abstract class I2 extends Object with M1 {}

              class T1 implements I2 {
                  /*severe:InvalidMethodOverride*/m(B a) {}
              }
           '''
        });
      });
      test('interface of abstract superclass', () {
        testChecker({
          '/main.dart': '''
              class A {}
              class B {}

              abstract class I1 {
                  m(A a);
              }
              abstract class Base implements I1 {}

              class T1 extends Base {
                  /*severe:InvalidMethodOverride*/m(B a) {}
              }
           '''
        });
      });
      test('interface of concrete superclass', () {
        testChecker({
          '/main.dart': '''
              class A {}
              class B {}

              abstract class I1 {
                  m(A a);
              }

              // See issue #25
              /*pass should be warning:AnalyzerError*/class Base implements I1 {
              }

              class T1 extends Base {
                  // not reported technically because if the class is concrete,
                  // it should implement all its interfaces and hence it is
                  // sufficient to check overrides against it.
                  m(B a) {}
              }
           '''
        });
      });
    });

    group('mixin override of grand interface', () {
      test('interface of interface of child', () {
        testChecker({
          '/main.dart': '''
              class A {}
              class B {}

              abstract class I1 {
                  m(A a);
              }
              abstract class I2 implements I1 {}

              class M {
                  m(B a) {}
              }

              class T1 extends Object with /*severe:InvalidMethodOverride*/M
                  implements I2 {
              }
           '''
        });
      });
      test('superclass of interface of child', () {
        testChecker({
          '/main.dart': '''
              class A {}
              class B {}

              abstract class I1 {
                  m(A a);
              }
              abstract class I2 extends I1 {}

              class M {
                  m(B a) {}
              }

              class T1 extends Object with /*severe:InvalidMethodOverride*/M
                  implements I2 {
              }
           '''
        });
      });
      test('mixin of interface of child', () {
        testChecker({
          '/main.dart': '''
              class A {}
              class B {}

              abstract class M1 {
                  m(A a);
              }
              abstract class I2 extends Object with M1 {}

              class M {
                  m(B a) {}
              }

              class T1 extends Object with /*severe:InvalidMethodOverride*/M
                  implements I2 {
              }
           '''
        });
      });
      test('interface of abstract superclass', () {
        testChecker({
          '/main.dart': '''
              class A {}
              class B {}

              abstract class I1 {
                  m(A a);
              }
              abstract class Base implements I1 {}

              class M {
                  m(B a) {}
              }

              class T1 extends Base with /*severe:InvalidMethodOverride*/M {
              }
           '''
        });
      });
      test('interface of concrete superclass', () {
        testChecker({
          '/main.dart': '''
              class A {}
              class B {}

              abstract class I1 {
                  m(A a);
              }

              // See issue #25
              /*pass should be warning:AnalyzerError*/class Base implements I1 {
              }

              class M {
                  m(B a) {}
              }

              class T1 extends Base with M {
              }
           '''
        });
      });
    });

    group('superclass override of grand interface', () {
      test('interface of interface of child', () {
        testChecker({
          '/main.dart': '''
              class A {}
              class B {}

              abstract class I1 {
                  m(A a);
              }
              abstract class I2 implements I1 {}

              class Base {
                  m(B a) {}
              }

              class T1 /*severe:InvalidMethodOverride*/extends Base
                  implements I2 {
              }
           '''
        });
      });
      test('superclass of interface of child', () {
        testChecker({
          '/main.dart': '''
              class A {}
              class B {}

              abstract class I1 {
                  m(A a);
              }
              abstract class I2 extends I1 {}

              class Base {
                  m(B a) {}
              }

              class T1 /*severe:InvalidMethodOverride*/extends Base
                  implements I2 {
              }
           '''
        });
      });
      test('mixin of interface of child', () {
        testChecker({
          '/main.dart': '''
              class A {}
              class B {}

              abstract class M1 {
                  m(A a);
              }
              abstract class I2 extends Object with M1 {}

              class Base {
                  m(B a) {}
              }

              class T1 /*severe:InvalidMethodOverride*/extends Base
                  implements I2 {
              }
           '''
        });
      });
      test('interface of abstract superclass', () {
        testChecker({
          '/main.dart': '''
              class A {}
              class B {}

              abstract class I1 {
                  m(A a);
              }

              abstract class Base implements I1 {
                  /*severe:InvalidMethodOverride*/m(B a) {}
              }

              class T1 extends Base {
                  // we consider the base class incomplete because it is
                  // abstract, so we report the error here too.
                  // TODO(sigmund): consider tracking overrides in a fine-grain
                  // manner, then this and the double-overrides would not be
                  // reported.
                  /*severe:InvalidMethodOverride*/m(B a) {}
              }
           '''
        });
      });
      test('interface of concrete superclass', () {
        testChecker({
          '/main.dart': '''
              class A {}
              class B {}

              abstract class I1 {
                  m(A a);
              }

              class Base implements I1 {
                  /*severe:InvalidMethodOverride*/m(B a) {}
              }

              class T1 extends Base {
                  m(B a) {}
              }
           '''
        });
      });
    });

    group('no duplicate reports from overriding interfaces', () {
      test('type overrides same method in multiple interfaces', () {
        testChecker({
          '/main.dart': '''
              class A {}
              class B {}

              abstract class I1 {
                  m(A a);
              }
              abstract class I2 implements I1 {
                  m(A a);
              }

              class Base {
              }

              class T1 implements I2 {
                /*severe:InvalidMethodOverride*/m(B a) {}
              }
           '''
        });
      });

      test('type and base type override same method in interface', () {
        testChecker({
          '/main.dart': '''
              class A {}
              class B {}

              abstract class I1 {
                  m(A a);
              }

              class Base {
                  m(B a);
              }

              // Note: no error reported in `extends Base` to avoid duplicating
              // the error in T1.
              class T1 extends Base implements I1 {
                /*severe:InvalidMethodOverride*/m(B a) {}
              }

              // If there is no error in the class, we do report the error at
              // the base class:
              class T2 /*severe:InvalidMethodOverride*/extends Base
                  implements I1 {
              }
           '''
        });
      });

      test('type and mixin override same method in interface', () {
        testChecker({
          '/main.dart': '''
              class A {}
              class B {}

              abstract class I1 {
                  m(A a);
              }

              class M {
                  m(B a);
              }

              class T1 extends Object with M implements I1 {
                /*severe:InvalidMethodOverride*/m(B a) {}
              }

              class T2 extends Object with /*severe:InvalidMethodOverride*/M
                  implements I1 {
              }
           '''
        });
      });

      test('two grand types override same method in interface', () {
        testChecker({
          '/main.dart': '''
              class A {}
              class B {}

              abstract class I1 {
                  m(A a);
              }

              class Grandparent {
                  m(B a) {}
              }

              class Parent1 extends Grandparent {
                  m(B a) {}
              }
              class Parent2 extends Grandparent {
              }

              // Note: otherwise both errors would be reported on this line
              class T1 /*severe:InvalidMethodOverride*/extends Parent1
                  implements I1 {
              }
              class T2 /*severe:InvalidMethodOverride*/extends Parent2
                  implements I1 {
              }
           '''
        });
      });

      test('two mixins override same method in interface', () {
        testChecker({
          '/main.dart': '''
              class A {}
              class B {}

              abstract class I1 {
                  m(A a);
              }

              class M1 {
                  m(B a) {}
              }

              class M2 {
                  m(B a) {}
              }

              // Here we want to report both, because the error location is
              // different.
              // TODO(sigmund): should we merge these as well?
              class T1 extends Object
                  with /*severe:InvalidMethodOverride*/M1
                  with /*severe:InvalidMethodOverride*/M2
                  implements I1 {
              }
           '''
        });
      });

      test('base type and mixin override same method in interface', () {
        testChecker({
          '/main.dart': '''
              class A {}
              class B {}

              abstract class I1 {
                  m(A a);
              }

              class Base {
                  m(B a) {}
              }

              class M {
                  m(B a) {}
              }

              // Here we want to report both, because the error location is
              // different.
              // TODO(sigmund): should we merge these as well?
              class T1 /*severe:InvalidMethodOverride*/extends Base
                  with /*severe:InvalidMethodOverride*/M
                  implements I1 {
              }
           '''
        });
      });
    });

    test('no reporting of overrides with Object twice.', () {
      // This is a regression test: we used to report it twice because it was
      // the top super class and top super interface.
      // TODO(sigmund): maybe we generalize this and don't report again errors
      // when an interface is also a superclass.
      testChecker({
        '/main.dart': '''
            class A {}
            class T1 implements A {
                /*severe:InferableOverride*/toString() {}
            }
         '''
      }, inferFromOverrides: false);
    });
  });
}
