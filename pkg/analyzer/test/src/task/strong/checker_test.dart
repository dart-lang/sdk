// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// TODO(jmesserly): this file needs to be refactored, it's a port from
// package:dev_compiler's tests
/// General type checking tests
library analyzer.test.src.task.strong.checker_test;

import 'package:unittest/unittest.dart';

import 'strong_test_helper.dart';

void main() {
  testChecker('ternary operator', {
    '/main.dart': '''
        abstract class Comparable<T> {
          int compareTo(T other);
          static int compare(Comparable a, Comparable b) => a.compareTo(b);
        }
        typedef int Comparator<T>(T a, T b);

        typedef bool _Predicate<T>(T value);

        class SplayTreeMap<K, V> {
          Comparator<K> _comparator;
          _Predicate _validKey;

          // Initializing _comparator needs a cast, since K may not always be
          // Comparable.
          // Initializing _validKey shouldn't need a cast.  Currently
          // it requires inference to work because of dartbug.com/23381
          SplayTreeMap([int compare(K key1, K key2),
                        bool isValidKey(potentialKey)]) {
            : _comparator = /*warning:DOWN_CAST_COMPOSITE*/(compare == null)
                           ? Comparable.compare : compare,
              _validKey = /*warning:DOWN_CAST_COMPOSITE*/(isValidKey != null)
                         ? isValidKey : ((v) => true);
             _Predicate<Object> _v = /*warning:DOWN_CAST_COMPOSITE*/(isValidKey != null)
                                    ? isValidKey : (/*info:INFERRED_TYPE_CLOSURE*/(v) => true);
        // TODO(leafp): Fix unimplemented LUB in analyzer
        _v = /*warning:DOWN_CAST_COMPOSITE*/(isValidKey != null)
             ? _v : (/*info:INFERRED_TYPE_CLOSURE*/(v) => true);
          }
        }
        void main() {
          Object obj = 42;
          dynamic dyn = 42;
          int i = 42;

          // Check the boolean conversion of the condition.
          print((/*severe:STATIC_TYPE_ERROR*/i) ? false : true);
          print((/*info:DOWN_CAST_IMPLICIT*/obj) ? false : true);
          print((/*info:DYNAMIC_CAST*/dyn) ? false : true);
        }
      '''
  });

  testChecker('if/for/do/while statements use boolean conversion', {
    '/main.dart': '''
      main() {
        dynamic d = 42;
        Object obj = 42;
        int i = 42;
        bool b = false;

        if (b) {}
        if (/*info:DYNAMIC_CAST*/dyn) {}
        if (/*info:DOWN_CAST_IMPLICIT*/obj) {}
        if (/*severe:STATIC_TYPE_ERROR*/i) {}

        while (b) {}
        while (/*info:DYNAMIC_CAST*/dyn) {}
        while (/*info:DOWN_CAST_IMPLICIT*/obj) {}
        while (/*severe:STATIC_TYPE_ERROR*/i) {}

        do {} while (b);
        do {} while (/*info:DYNAMIC_CAST*/dyn);
        do {} while (/*info:DOWN_CAST_IMPLICIT*/obj);
        do {} while (/*severe:STATIC_TYPE_ERROR*/i);

        for (;b;) {}
        for (;/*info:DYNAMIC_CAST*/dyn;) {}
        for (;/*info:DOWN_CAST_IMPLICIT*/obj;) {}
        for (;/*severe:STATIC_TYPE_ERROR*/i;) {}
      }
    '''
  });

  testChecker('dynamic invocation', {
    '/main.dart': '''

      class A {
        dynamic call(dynamic x) => x;
      }
      class B extends A {
        int call(int x) => x;
        double col(double x) => x;
      }
      void main() {
        {
          B f = new B();
          int x;
          double y;
          x = f(3);
          x = /*severe:STATIC_TYPE_ERROR*/f.col(3.0);
          y = /*severe:STATIC_TYPE_ERROR*/f(3);
          y = f.col(3.0);
          f(/*severe:STATIC_TYPE_ERROR*/3.0);
          f.col(/*severe:STATIC_TYPE_ERROR*/3);
        }
        {
          Function f = new B();
          int x;
          double y;
          x = /*info:DYNAMIC_CAST, info:DYNAMIC_INVOKE*/f(3);
          x = /*info:DYNAMIC_CAST, info:DYNAMIC_INVOKE*/f.col(3.0);
          y = /*info:DYNAMIC_CAST, info:DYNAMIC_INVOKE*/f(3);
          y = /*info:DYNAMIC_CAST, info:DYNAMIC_INVOKE*/f.col(3.0);
          (/*info:DYNAMIC_INVOKE*/f(3.0));
          (/*info:DYNAMIC_INVOKE*/f.col(3));
        }
        {
          A f = new B();
          int x;
          double y;
          x = /*info:DYNAMIC_CAST, info:DYNAMIC_INVOKE*/f(3);
          y = /*info:DYNAMIC_CAST, info:DYNAMIC_INVOKE*/f(3);
          (/*info:DYNAMIC_INVOKE*/f(3.0));
        }
        {
          dynamic g = new B();
          (/*info:DYNAMIC_INVOKE*/g.call(32.0));
          (/*info:DYNAMIC_INVOKE*/g.col(42.0));
          (/*info:DYNAMIC_INVOKE*/g.foo(42.0));
          (/*info:DYNAMIC_INVOKE*/g.x);
          A f = new B();
          f.call(32.0);
          (/*info:DYNAMIC_INVOKE*/f.col(42.0));
          (/*info:DYNAMIC_INVOKE*/f.foo(42.0));
          (/*info:DYNAMIC_INVOKE*/f.x);
        }
      }
    '''
  });

  testChecker('conversion and dynamic invoke', {
    '/helper.dart': '''
      dynamic toString = (int x) => x + 42;
      dynamic hashCode = "hello";
      ''',
    '/main.dart': '''
      import 'helper.dart' as helper;

      class A {
        String x = "hello world";

        void baz1(y) => x + /*info:DYNAMIC_CAST*/y;
        static baz2(y) => /*info:DYNAMIC_INVOKE*/y + y;
      }

      void foo(String str) {
        print(str);
      }

      class B {
        String toString([int arg]) => arg.toString();
      }

      void bar(a) {
        foo(/*info:DYNAMIC_CAST,info:DYNAMIC_INVOKE*/a.x);
      }

      baz() => new B();

      typedef DynFun(x);
      typedef StrFun(String x);

      var bar1 = bar;

      void main() {
        var a = new A();
        bar(a);
        (/*info:DYNAMIC_INVOKE*/bar1(a));
        var b = bar;
        (/*info:DYNAMIC_INVOKE*/b(a));
        var f1 = foo;
        f1("hello");
        dynamic f2 = foo;
        (/*info:DYNAMIC_INVOKE*/f2("hello"));
        DynFun f3 = foo;
        (/*info:DYNAMIC_INVOKE*/f3("hello"));
        (/*info:DYNAMIC_INVOKE*/f3(42));
        StrFun f4 = foo;
        f4("hello");
        a.baz1("hello");
        var b1 = a.baz1;
        (/*info:DYNAMIC_INVOKE*/b1("hello"));
        A.baz2("hello");
        var b2 = A.baz2;
        (/*info:DYNAMIC_INVOKE*/b2("hello"));

        dynamic a1 = new B();
        (/*info:DYNAMIC_INVOKE*/a1.x);
        a1.toString();
        (/*info:DYNAMIC_INVOKE*/a1.toString(42));
        var toStringClosure = a1.toString;
        (/*info:DYNAMIC_INVOKE*/a1.toStringClosure());
        (/*info:DYNAMIC_INVOKE*/a1.toStringClosure(42));
        (/*info:DYNAMIC_INVOKE*/a1.toStringClosure("hello"));
        a1.hashCode;

        dynamic toString = () => null;
        (/*info:DYNAMIC_INVOKE*/toString());

        (/*info:DYNAMIC_INVOKE*/helper.toString());
        var toStringClosure2 = helper.toString;
        (/*info:DYNAMIC_INVOKE*/toStringClosure2());
        int hashCode = /*info:DYNAMIC_CAST*/helper.hashCode;

        baz().toString();
        baz().hashCode;
      }
    '''
  });

  testChecker('Constructors', {
    '/main.dart': '''
      const num z = 25;
      Object obj = "world";

      class A {
        int x;
        String y;

        A(this.x) : this.y = /*severe:STATIC_TYPE_ERROR*/42;

        A.c1(p): this.x = /*info:DOWN_CAST_IMPLICIT*/z, this.y = /*info:DYNAMIC_CAST*/p;

        A.c2(this.x, this.y);

        A.c3(/*severe:INVALID_PARAMETER_DECLARATION*/num this.x, String this.y);
      }

      class B extends A {
        B() : super(/*severe:STATIC_TYPE_ERROR*/"hello");

        B.c2(int x, String y) : super.c2(/*severe:STATIC_TYPE_ERROR*/y,
                                         /*severe:STATIC_TYPE_ERROR*/x);

        B.c3(num x, Object y) : super.c3(x, /*info:DOWN_CAST_IMPLICIT*/y);
      }

      void main() {
         A a = new A.c2(/*info:DOWN_CAST_IMPLICIT*/z, /*severe:STATIC_TYPE_ERROR*/z);
         var b = new B.c2(/*severe:STATIC_TYPE_ERROR*/"hello", /*info:DOWN_CAST_IMPLICIT*/obj);
      }
   '''
  });

  testChecker('Unbound variable', {
    '/main.dart': '''
      void main() {
         dynamic y = /*pass should be severe:STATIC_TYPE_ERROR*/unboundVariable;
      }
   '''
  });

  testChecker('Unbound type name', {
    '/main.dart': '''
      void main() {
         /*pass should be severe:STATIC_TYPE_ERROR*/AToB y;
      }
   '''
  });

  // Regression test for https://github.com/dart-lang/sdk/issues/25069
  testChecker('Void subtyping', {
    '/main.dart': '''
      typedef int Foo();
      void foo() {}
      void main () {
        Foo x = /*severe:STATIC_TYPE_ERROR*/foo();
      }
   '''
  });

  testChecker('Ground type subtyping: dynamic is top', {
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

  testChecker('Ground type subtyping: dynamic downcasts', {
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
         i = /*info:DYNAMIC_CAST*/y;
         d = /*info:DYNAMIC_CAST*/y;
         n = /*info:DYNAMIC_CAST*/y;
         a = /*info:DYNAMIC_CAST*/y;
         b = /*info:DYNAMIC_CAST*/y;
      }
   '''
  });

  testChecker('Ground type subtyping: assigning a class', {
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
         i = /*severe:STATIC_TYPE_ERROR*/a;
         d = /*severe:STATIC_TYPE_ERROR*/a;
         n = /*severe:STATIC_TYPE_ERROR*/a;
         a = a;
         b = /*info:DOWN_CAST_IMPLICIT*/a;
      }
   '''
  });

  testChecker('Ground type subtyping: assigning a subclass', {
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
         i = /*severe:STATIC_TYPE_ERROR*/b;
         d = /*severe:STATIC_TYPE_ERROR*/b;
         n = /*severe:STATIC_TYPE_ERROR*/b;
         a = b;
         b = b;
         c = /*severe:STATIC_TYPE_ERROR*/b;
      }
   '''
  });

  testChecker('Ground type subtyping: interfaces', {
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
           left = /*info:DOWN_CAST_IMPLICIT*/top;
           left = left;
           left = /*severe:STATIC_TYPE_ERROR*/right;
           left = bot;
         }
         {
           right = /*info:DOWN_CAST_IMPLICIT*/top;
           right = /*severe:STATIC_TYPE_ERROR*/left;
           right = right;
           right = bot;
         }
         {
           bot = /*info:DOWN_CAST_IMPLICIT*/top;
           bot = /*info:DOWN_CAST_IMPLICIT*/left;
           bot = /*info:DOWN_CAST_IMPLICIT*/right;
           bot = bot;
         }
      }
   '''
  });

  testChecker('Function typing and subtyping: int and object', {
    '/main.dart': '''

      typedef Object Top(int x);      // Top of the lattice
      typedef int Left(int x);        // Left branch
      typedef int Left2(int x);       // Left branch
      typedef Object Right(Object x); // Right branch
      typedef int Bot(Object x);      // Bottom of the lattice

      Object top(int x) => x;
      int left(int x) => x;
      Object right(Object x) => x;
      int _bot(Object x) => /*info:DOWN_CAST_IMPLICIT*/x;
      int bot(Object x) => x as int;

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
          f = /*warning:DOWN_CAST_COMPOSITE*/top;
          f = left;
          f = /*warning:DOWN_CAST_COMPOSITE*/right; // Should we reject this?
          f = bot;
        }
        {
          Right f;
          f = /*warning:DOWN_CAST_COMPOSITE*/top;
          f = /*warning:DOWN_CAST_COMPOSITE*/left; // Should we reject this?
          f = right;
          f = bot;
        }
        {
          Bot f;
          f = /*warning:DOWN_CAST_COMPOSITE*/top;
          f = /*warning:DOWN_CAST_COMPOSITE*/left;
          f = /*warning:DOWN_CAST_COMPOSITE*/right;
          f = bot;
        }
      }
   '''
  });

  testChecker('Function typing and subtyping: classes', {
    '/main.dart': '''

      class A {}
      class B extends A {}

      typedef A Top(B x);   // Top of the lattice
      typedef B Left(B x);  // Left branch
      typedef B Left2(B x); // Left branch
      typedef A Right(A x); // Right branch
      typedef B Bot(A x);   // Bottom of the lattice

      B left(B x) => x;
      B _bot(A x) => /*info:DOWN_CAST_IMPLICIT*/x;
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
          f = /*warning:DOWN_CAST_COMPOSITE*/top;
          f = left;
          f = /*warning:DOWN_CAST_COMPOSITE*/right; // Should we reject this?
          f = bot;
        }
        {
          Right f;
          f = /*warning:DOWN_CAST_COMPOSITE*/top;
          f = /*warning:DOWN_CAST_COMPOSITE*/left; // Should we reject this?
          f = right;
          f = bot;
        }
        {
          Bot f;
          f = /*warning:DOWN_CAST_COMPOSITE*/top;
          f = /*warning:DOWN_CAST_COMPOSITE*/left;
          f = /*warning:DOWN_CAST_COMPOSITE*/right;
          f = bot;
        }
      }
   '''
  });

  testChecker('Function typing and subtyping: dynamic', {
    '/main.dart': '''

      class A {}

      typedef dynamic Top(dynamic x);     // Top of the lattice
      typedef dynamic Left(A x);          // Left branch
      typedef A Right(dynamic x);         // Right branch
      typedef A Bottom(A x);              // Bottom of the lattice

      dynamic left(A x) => x;
      A bot(A x) => x;
      dynamic top(dynamic x) => x;
      A right(dynamic x) => /*info:DYNAMIC_CAST*/x;

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
          f = /*warning:DOWN_CAST_COMPOSITE*/top;
          f = left;
          f = /*warning:DOWN_CAST_COMPOSITE*/right;
          f = bot;
        }
        {
          Right f;
          f = /*warning:DOWN_CAST_COMPOSITE*/top;
          f = /*warning:DOWN_CAST_COMPOSITE*/left;
          f = right;
          f = bot;
        }
        {
          Bottom f;
          f = /*warning:DOWN_CAST_COMPOSITE*/top;
          f = /*warning:DOWN_CAST_COMPOSITE*/left;
          f = /*warning:DOWN_CAST_COMPOSITE*/right;
          f = bot;
        }
      }
   '''
  });

  testChecker('Function typing and subtyping: function literal variance', {
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
          f = /*warning:DOWN_CAST_COMPOSITE*/top;
          f = left;
          f = /*warning:DOWN_CAST_COMPOSITE*/right; // Should we reject this?
          f = bot;
        }
        {
          Function2<A, A> f;
          f = /*warning:DOWN_CAST_COMPOSITE*/top;
          f = /*warning:DOWN_CAST_COMPOSITE*/left; // Should we reject this?
          f = right;
          f = bot;
        }
        {
          Function2<A, B> f;
          f = /*warning:DOWN_CAST_COMPOSITE*/top;
          f = /*warning:DOWN_CAST_COMPOSITE*/left;
          f = /*warning:DOWN_CAST_COMPOSITE*/right;
          f = bot;
        }
      }
   '''
  });

  testChecker('Function typing and subtyping: function variable variance', {
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

          left = /*warning:DOWN_CAST_COMPOSITE*/top;
          left = left;
          left = /*warning:DOWN_CAST_COMPOSITE*/right; // Should we reject this?
          left = bot;

          right = /*warning:DOWN_CAST_COMPOSITE*/top;
          right = /*warning:DOWN_CAST_COMPOSITE*/left; // Should we reject this?
          right = right;
          right = bot;

          bot = /*warning:DOWN_CAST_COMPOSITE*/top;
          bot = /*warning:DOWN_CAST_COMPOSITE*/left;
          bot = /*warning:DOWN_CAST_COMPOSITE*/right;
          bot = bot;
        }
      }
   '''
  });

  testChecker('Function typing and subtyping: higher order function literals', {
    '/main.dart': '''

      class A {}
      class B extends A {}

      typedef T Function2<S, T>(S z);

      typedef A BToA(B x);  // Top of the base lattice
      typedef B AToB(A x);  // Bot of the base lattice

      BToA top(AToB f) => f;
      AToB left(AToB f) => f;
      BToA right(BToA f) => f;
      AToB _bot(BToA f) => /*warning:DOWN_CAST_COMPOSITE*/f;
      AToB bot(BToA f) => f as AToB;

      Function2<B, A> top(AToB f) => f;
      Function2<A, B> left(AToB f) => f;
      Function2<B, A> right(BToA f) => f;
      Function2<A, B> _bot(BToA f) => /*warning:DOWN_CAST_COMPOSITE*/f;
      Function2<A, B> bot(BToA f) => f as Function2<A, B>;


      BToA top(Function2<A, B> f) => f;
      AToB left(Function2<A, B> f) => f;
      BToA right(Function2<B, A> f) => f;
      AToB _bot(Function2<B, A> f) => /*warning:DOWN_CAST_COMPOSITE*/f;
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
          f = /*warning:DOWN_CAST_COMPOSITE*/top;
          f = left;
          f = /*warning:DOWN_CAST_COMPOSITE*/right; // Should we reject this?
          f = bot;
        }
        {
          Function2<BToA, BToA> f; // Right
          f = /*warning:DOWN_CAST_COMPOSITE*/top;
          f = /*warning:DOWN_CAST_COMPOSITE*/left; // Should we reject this?
          f = right;
          f = bot;
        }
        {
          Function2<BToA, AToB> f; // Bot
          f = bot;
          f = /*warning:DOWN_CAST_COMPOSITE*/left;
          f = /*warning:DOWN_CAST_COMPOSITE*/top;
          f = /*warning:DOWN_CAST_COMPOSITE*/left;
        }
      }
   '''
  });

  testChecker(
      'Function typing and subtyping: higher order function variables', {
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

        left = /*warning:DOWN_CAST_COMPOSITE*/top;
        left = left;
        left =
            /*warning:DOWN_CAST_COMPOSITE should be severe:STATIC_TYPE_ERROR*/right;
        left = bot;

        right = /*warning:DOWN_CAST_COMPOSITE*/top;
        right =
            /*warning:DOWN_CAST_COMPOSITE should be severe:STATIC_TYPE_ERROR*/left;
        right = right;
        right = bot;

        bot = /*warning:DOWN_CAST_COMPOSITE*/top;
        bot = /*warning:DOWN_CAST_COMPOSITE*/left;
        bot = /*warning:DOWN_CAST_COMPOSITE*/right;
        bot = bot;
      }
    }
   '''
  });

  testChecker('Function typing and subtyping: named and optional parameters', {
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
         r = /*severe:STATIC_TYPE_ERROR*/n;
         r = /*severe:STATIC_TYPE_ERROR*/rr;
         r = ro;
         r = rn;
         r = oo;
         r = /*severe:STATIC_TYPE_ERROR*/nn;
         r = /*severe:STATIC_TYPE_ERROR*/nnn;

         o = /*warning:DOWN_CAST_COMPOSITE*/r;
         o = o;
         o = /*severe:STATIC_TYPE_ERROR*/n;
         o = /*severe:STATIC_TYPE_ERROR*/rr;
         o = /*severe:STATIC_TYPE_ERROR*/ro;
         o = /*severe:STATIC_TYPE_ERROR*/rn;
         o = oo;
         o = /*severe:STATIC_TYPE_ERROR*/nn
         o = /*severe:STATIC_TYPE_ERROR*/nnn;

         n = /*severe:STATIC_TYPE_ERROR*/r;
         n = /*severe:STATIC_TYPE_ERROR*/o;
         n = n;
         n = /*severe:STATIC_TYPE_ERROR*/rr;
         n = /*severe:STATIC_TYPE_ERROR*/ro;
         n = /*severe:STATIC_TYPE_ERROR*/rn;
         n = /*severe:STATIC_TYPE_ERROR*/oo;
         n = nn;
         n = nnn;

         rr = /*severe:STATIC_TYPE_ERROR*/r;
         rr = /*severe:STATIC_TYPE_ERROR*/o;
         rr = /*severe:STATIC_TYPE_ERROR*/n;
         rr = rr;
         rr = ro;
         rr = /*severe:STATIC_TYPE_ERROR*/rn;
         rr = oo;
         rr = /*severe:STATIC_TYPE_ERROR*/nn;
         rr = /*severe:STATIC_TYPE_ERROR*/nnn;

         ro = /*warning:DOWN_CAST_COMPOSITE*/r;
         ro = /*severe:STATIC_TYPE_ERROR*/o;
         ro = /*severe:STATIC_TYPE_ERROR*/n;
         ro = /*warning:DOWN_CAST_COMPOSITE*/rr;
         ro = ro;
         ro = /*severe:STATIC_TYPE_ERROR*/rn;
         ro = oo;
         ro = /*severe:STATIC_TYPE_ERROR*/nn;
         ro = /*severe:STATIC_TYPE_ERROR*/nnn;

         rn = /*warning:DOWN_CAST_COMPOSITE*/r;
         rn = /*severe:STATIC_TYPE_ERROR*/o;
         rn = /*severe:STATIC_TYPE_ERROR*/n;
         rn = /*severe:STATIC_TYPE_ERROR*/rr;
         rn = /*severe:STATIC_TYPE_ERROR*/ro;
         rn = rn;
         rn = /*severe:STATIC_TYPE_ERROR*/oo;
         rn = /*severe:STATIC_TYPE_ERROR*/nn;
         rn = /*severe:STATIC_TYPE_ERROR*/nnn;

         oo = /*warning:DOWN_CAST_COMPOSITE*/r;
         oo = /*warning:DOWN_CAST_COMPOSITE*/o;
         oo = /*severe:STATIC_TYPE_ERROR*/n;
         oo = /*warning:DOWN_CAST_COMPOSITE*/rr;
         oo = /*warning:DOWN_CAST_COMPOSITE*/ro;
         oo = /*severe:STATIC_TYPE_ERROR*/rn;
         oo = oo;
         oo = /*severe:STATIC_TYPE_ERROR*/nn;
         oo = /*severe:STATIC_TYPE_ERROR*/nnn;

         nn = /*severe:STATIC_TYPE_ERROR*/r;
         nn = /*severe:STATIC_TYPE_ERROR*/o;
         nn = /*warning:DOWN_CAST_COMPOSITE*/n;
         nn = /*severe:STATIC_TYPE_ERROR*/rr;
         nn = /*severe:STATIC_TYPE_ERROR*/ro;
         nn = /*severe:STATIC_TYPE_ERROR*/rn;
         nn = /*severe:STATIC_TYPE_ERROR*/oo;
         nn = nn;
         nn = nnn;

         nnn = /*severe:STATIC_TYPE_ERROR*/r;
         nnn = /*severe:STATIC_TYPE_ERROR*/o;
         nnn = /*warning:DOWN_CAST_COMPOSITE*/n;
         nnn = /*severe:STATIC_TYPE_ERROR*/rr;
         nnn = /*severe:STATIC_TYPE_ERROR*/ro;
         nnn = /*severe:STATIC_TYPE_ERROR*/rn;
         nnn = /*severe:STATIC_TYPE_ERROR*/oo;
         nnn = /*warning:DOWN_CAST_COMPOSITE*/nn;
         nnn = nnn;
      }
   '''
  });

  testChecker('Function subtyping: objects with call methods', {
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
           f = /*severe:STATIC_TYPE_ERROR*/new B();
           f = i2i;
           f = /*warning:DOWN_CAST_COMPOSITE*/n2n;
           f = /*warning:DOWN_CAST_COMPOSITE*/i2i as Object;
           f = /*warning:DOWN_CAST_COMPOSITE*/n2n as Function;
         }
         {
           N2N f;
           f = /*severe:STATIC_TYPE_ERROR*/new A();
           f = new B();
           f = /*warning:DOWN_CAST_COMPOSITE*/i2i;
           f = n2n;
           f = /*warning:DOWN_CAST_COMPOSITE*/i2i as Object;
           f = /*warning:DOWN_CAST_COMPOSITE*/n2n as Function;
         }
         {
           A f;
           f = new A();
           f = /*severe:STATIC_TYPE_ERROR*/new B();
           f = /*severe:STATIC_TYPE_ERROR*/i2i;
           f = /*severe:STATIC_TYPE_ERROR*/n2n;
           f = /*info:DOWN_CAST_IMPLICIT*/i2i as Object;
           f = /*info:DOWN_CAST_IMPLICIT*/n2n as Function;
         }
         {
           B f;
           f = /*severe:STATIC_TYPE_ERROR*/new A();
           f = new B();
           f = /*severe:STATIC_TYPE_ERROR*/i2i;
           f = /*severe:STATIC_TYPE_ERROR*/n2n;
           f = /*info:DOWN_CAST_IMPLICIT*/i2i as Object;
           f = /*info:DOWN_CAST_IMPLICIT*/n2n as Function;
         }
         {
           Function f;
           f = new A();
           f = new B();
           f = i2i;
           f = n2n;
           f = /*info:DOWN_CAST_IMPLICIT*/i2i as Object;
           f = (n2n as Function);
         }
      }
   '''
  });

  testChecker('Function typing and subtyping: void', {
    '/main.dart': '''

      class A {
        void bar() => null;
        void foo() => bar; // allowed
      }
   '''
  });

  testChecker('Function subtyping: uninferred closure', {
    '/main.dart': '''
      typedef num Num2Num(num x);
      void main() {
        Num2Num g = /*info:INFERRED_TYPE_CLOSURE,severe:STATIC_TYPE_ERROR*/(int x) { return x; };
        print(g(42));
      }
    '''
  });

  testChecker('Relaxed casts', {
    '/main.dart': '''

      class A {}

      class L<T> {}
      class M<T> extends L<T> {}
      //     L<dynamic|Object>
      //    /              \
      // M<dynamic|Object>  L<A>
      //    \              /
      //          M<A>
      // In normal Dart, there are additional edges
      //  from M<A> to M<dynamic>
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
          lOfOs = mOfDs;
          lOfOs = mOfOs;
          lOfOs = mOfAs;
          lOfOs = lOfDs;
          lOfOs = lOfOs;
          lOfOs = lOfAs;
        }
        {
          lOfAs = /*warning:DOWN_CAST_COMPOSITE*/mOfDs;
          lOfAs = /*severe:STATIC_TYPE_ERROR*/mOfOs;
          lOfAs = mOfAs;
          lOfAs = /*warning:DOWN_CAST_COMPOSITE*/lOfDs;
          lOfAs = /*info:DOWN_CAST_IMPLICIT*/lOfOs;
          lOfAs = lOfAs;
        }
        {
          mOfDs = mOfDs;
          mOfDs = mOfOs;
          mOfDs = mOfAs;
          mOfDs = /*info:DOWN_CAST_IMPLICIT*/lOfDs;
          mOfDs = /*info:DOWN_CAST_IMPLICIT*/lOfOs;
          mOfDs = /*warning:DOWN_CAST_COMPOSITE*/lOfAs;
        }
        {
          mOfOs = mOfDs;
          mOfOs = mOfOs;
          mOfOs = mOfAs;
          mOfOs = /*info:DOWN_CAST_IMPLICIT*/lOfDs;
          mOfOs = /*info:DOWN_CAST_IMPLICIT*/lOfOs;
          mOfOs = /*severe:STATIC_TYPE_ERROR*/lOfAs;
        }
        {
          mOfAs = /*warning:DOWN_CAST_COMPOSITE*/mOfDs;
          mOfAs = /*info:DOWN_CAST_IMPLICIT*/mOfOs;
          mOfAs = mOfAs;
          mOfAs = /*warning:DOWN_CAST_COMPOSITE*/lOfDs;
          mOfAs = /*info:DOWN_CAST_IMPLICIT*/lOfOs;
          mOfAs = /*info:DOWN_CAST_IMPLICIT*/lOfAs;
        }

      }
   '''
  });

  testChecker('Type checking literals', {
    '/main.dart': '''
          test() {
            num n = 3;
            int i = 3;
            String s = "hello";
            {
               List<int> l = <int>[i];
               l = <int>[/*severe:STATIC_TYPE_ERROR*/s];
               l = <int>[/*info:DOWN_CAST_IMPLICIT*/n];
               l = <int>[i, /*info:DOWN_CAST_IMPLICIT*/n, /*severe:STATIC_TYPE_ERROR*/s];
            }
            {
               List l = [i];
               l = [s];
               l = [n];
               l = [i, n, s];
            }
            {
               Map<String, int> m = <String, int>{s: i};
               m = <String, int>{s: /*severe:STATIC_TYPE_ERROR*/s};
               m = <String, int>{s: /*info:DOWN_CAST_IMPLICIT*/n};
               m = <String, int>{s: i,
                                 s: /*info:DOWN_CAST_IMPLICIT*/n,
                                 s: /*severe:STATIC_TYPE_ERROR*/s};
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

  testChecker('casts in constant contexts', {
    '/main.dart': '''
          class A {
            static const num n = 3.0;
            static const int i = /*info:ASSIGNMENT_CAST*/n;
            final int fi;
            const A(num a) : this.fi = /*info:DOWN_CAST_IMPLICIT*/a;
          }
          class B extends A {
            const B(Object a) : super(/*info:DOWN_CAST_IMPLICIT*/a);
          }
          void foo(Object o) {
            var a = const A(/*info:DOWN_CAST_IMPLICIT*/o);
          }
     '''
  });

  testChecker('casts in conditionals', {
    '/main.dart': '''
          main() {
            bool b = true;
            num x = b ? 1 : 2.3;
            int y = /*info:ASSIGNMENT_CAST*/b ? 1 : 2.3;
            String z = !b ? "hello" : null;
            z = b ? null : "hello";
          }
      '''
  });

  // This is a regression test for https://github.com/dart-lang/sdk/issues/25071
  testChecker('unbound redirecting constructor', {
    '/main.dart': '''
      class Foo {
        Foo() : this.init();
      }
       '''
  });

  testChecker('redirecting constructor', {
    '/main.dart': '''
          class A {
            A(A x) {}
            A.two() : this(/*severe:STATIC_TYPE_ERROR*/3);
          }
       '''
  });

  testChecker('super constructor', {
    '/main.dart': '''
          class A { A(A x) {} }
          class B extends A {
            B() : super(/*severe:STATIC_TYPE_ERROR*/3);
          }
       '''
  });

  testChecker('factory constructor downcast', {
    '/main.dart': r'''
        class Animal {
          Animal();
          factory Animal.cat() => return new Cat();
        }

        class Cat extends Animal {}

        void main() {
          Cat c = /*info:ASSIGNMENT_CAST*/new Animal.cat();
          c = /*severe:STATIC_TYPE_ERROR*/new Animal();
        }'''
  });

  testChecker('field/field override', {
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
            /*severe:INVALID_FIELD_OVERRIDE,severe:INVALID_METHOD_OVERRIDE*/A f1; // invalid for getter
            /*severe:INVALID_FIELD_OVERRIDE,severe:INVALID_METHOD_OVERRIDE*/C f2; // invalid for setter
            /*severe:INVALID_FIELD_OVERRIDE*/var f3;
            /*severe:INVALID_FIELD_OVERRIDE,severe:INVALID_METHOD_OVERRIDE,severe:INVALID_METHOD_OVERRIDE*/dynamic f4;
          }

          class Child2 implements Base {
            /*severe:INVALID_METHOD_OVERRIDE*/A f1; // invalid for getter
            /*severe:INVALID_METHOD_OVERRIDE*/C f2; // invalid for setter
            var f3;
            /*severe:INVALID_METHOD_OVERRIDE,severe:INVALID_METHOD_OVERRIDE*/dynamic f4;
          }
       '''
  });

  testChecker('private override', {
    '/helper.dart': '''
          import 'main.dart' as main;

          class Base {
            var f1;
            var _f2;
            var _f3;
            get _f4 => null;

            int _m1();
          }

          class GrandChild extends main.Child {
            /*severe:INVALID_FIELD_OVERRIDE*/var _f2;
            /*severe:INVALID_FIELD_OVERRIDE*/var _f3;
            var _f4;

            /*severe:INVALID_METHOD_OVERRIDE*/String _m1();
          }
    ''',
    '/main.dart': '''
          import 'helper.dart' as helper;

          class Child extends helper.Base {
            /*severe:INVALID_FIELD_OVERRIDE*/var f1;
            var _f2;
            var _f4;

            String _m1();
          }
    '''
  });

  testChecker('getter/getter override', {
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
            /*severe:INVALID_METHOD_OVERRIDE*/A get f1 => null;
            C get f2 => null;
            get f3 => null;
            /*severe:INVALID_METHOD_OVERRIDE*/dynamic get f4 => null;
          }
       '''
  });

  testChecker('field/getter override', {
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
            /*severe:INVALID_FIELD_OVERRIDE,severe:INVALID_METHOD_OVERRIDE*/A get f1 => null;
            /*severe:INVALID_FIELD_OVERRIDE*/C get f2 => null;
            /*severe:INVALID_FIELD_OVERRIDE*/get f3 => null;
            /*severe:INVALID_FIELD_OVERRIDE,severe:INVALID_METHOD_OVERRIDE*/dynamic get f4 => null;
          }

          class Child2 implements Base {
            /*severe:INVALID_METHOD_OVERRIDE*/A get f1 => null;
            C get f2 => null;
            get f3 => null;
            /*severe:INVALID_METHOD_OVERRIDE*/dynamic get f4 => null;
          }
       '''
  });

  testChecker('setter/setter override', {
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
            /*severe:INVALID_METHOD_OVERRIDE*/void set f2(C value) {}
            void set f3(value) {}
            /*severe:INVALID_METHOD_OVERRIDE*/void set f4(dynamic value) {}
            set f5(B value) {}
          }
       '''
  });

  testChecker('field/setter override', {
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
            /*severe:INVALID_FIELD_OVERRIDE*/B get f1 => null;
            /*severe:INVALID_FIELD_OVERRIDE*/B get f2 => null;
            /*severe:INVALID_FIELD_OVERRIDE*/B get f3 => null;
            /*severe:INVALID_FIELD_OVERRIDE*/B get f4 => null;
            /*severe:INVALID_FIELD_OVERRIDE*/B get f5 => null;

            /*severe:INVALID_FIELD_OVERRIDE*/void set f1(A value) {}
            /*severe:INVALID_FIELD_OVERRIDE,severe:INVALID_METHOD_OVERRIDE*/void set f2(C value) {}
            /*severe:INVALID_FIELD_OVERRIDE*/void set f3(value) {}
            /*severe:INVALID_FIELD_OVERRIDE,severe:INVALID_METHOD_OVERRIDE*/void set f4(dynamic value) {}
            /*severe:INVALID_FIELD_OVERRIDE*/set f5(B value) {}
          }

          class Child2 implements Base {
            B get f1 => null;
            B get f2 => null;
            B get f3 => null;
            B get f4 => null;
            B get f5 => null;

            void set f1(A value) {}
            /*severe:INVALID_METHOD_OVERRIDE*/void set f2(C value) {}
            void set f3(value) {}
            /*severe:INVALID_METHOD_OVERRIDE*/void set f4(dynamic value) {}
            set f5(B value) {}
          }
       '''
  });

  testChecker('method override', {
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
            /*severe:INVALID_METHOD_OVERRIDE*/A m1(A value) {}
            /*severe:INVALID_METHOD_OVERRIDE*/C m2(C value) {}
            /*severe:INVALID_METHOD_OVERRIDE*/A m3(C value) {}
            C m4(A value) {}
            m5(value) {}
            /*severe:INVALID_METHOD_OVERRIDE*/dynamic m6(dynamic value) {}
          }
       '''
  });

  testChecker('generic class method override', {
    '/main.dart': '''
          class A {}
          class B extends A {}

          class Base<T extends B> {
            T foo() => null;
          }

          class Derived<S extends A> extends Base<B> {
            /*severe:INVALID_METHOD_OVERRIDE*/S foo() => null;
          }

          class Derived2<S extends B> extends Base<B> {
            S foo() => null;
          }
       '''
  });

  testChecker('generic method override', {
    '/main.dart': '''
          class Future<T> {
            /*=S*/ then/*<S>*/(/*=S*/ onValue(T t)) => null;
          }

          class DerivedFuture<T> extends Future<T> {
            /*=S*/ then/*<S>*/(/*=S*/ onValue(T t)) => null;
          }

          class DerivedFuture2<A> extends Future<A> {
            /*=B*/ then/*<B>*/(/*=B*/ onValue(A a)) => null;
          }

          class DerivedFuture3<T> extends Future<T> {
            /*=S*/ then/*<S>*/(Object onValue(T t)) => null;
          }

          class DerivedFuture4<A> extends Future<A> {
            /*=B*/ then/*<B>*/(Object onValue(A a)) => null;
          }
      '''
  });

  testChecker('generic function wrong number of arguments', {
      '/main.dart': r'''
          /*=T*/ foo/*<T>*/(/*=T*/ x, /*=T*/ y) => x;
          /*=T*/ bar/*<T>*/({/*=T*/ x, /*=T*/ y}) => x;

          main() {
            // resolving thses shouldn't crash.
            foo(1, 2, 3);
            String x = foo('1', '2', '3');
            foo(1);
            String x = foo('1');
            x = /*severe:STATIC_TYPE_ERROR*/foo(1, 2, 3);
            x = /*severe:STATIC_TYPE_ERROR*/foo(1);

            // named arguments
            bar(y: 1, x: 2, z: 3);
            String x = bar(z: '1', x: '2', y: '3');
            bar(y: 1);
            x = bar(x: '1', z: 42);
            x = /*severe:STATIC_TYPE_ERROR*/bar(y: 1, x: 2, z: 3);
            x = /*severe:STATIC_TYPE_ERROR*/bar(x: 1);
          }
      '''
  });

  testChecker('type promotion from dynamic', {
    '/main.dart': r'''
          f() {
            dynamic x;
            if (x is int) {
              int y = x;
              String z = /*severe:STATIC_TYPE_ERROR*/x;
            }
          }
          g() {
            Object x;
            if (x is int) {
              int y = x;
              String z = /*severe:STATIC_TYPE_ERROR*/x;
            }
          }
    '''
  });

  testChecker('unary operators', {
    '/main.dart': '''
      class A {
        A operator ~() {}
        A operator +(int x) {}
        A operator -(int x) {}
        A operator -() {}
      }

      foo() => new A();

      test() {
        A a = new A();
        var c = foo();

        ~a;
        (/*info:DYNAMIC_INVOKE*/~d);

        !/*severe:STATIC_TYPE_ERROR*/a;
        !/*info:DYNAMIC_CAST*/d;

        -a;
        (/*info:DYNAMIC_INVOKE*/-d);

        ++a;
        --a;
        (/*info:DYNAMIC_INVOKE*/++d);
        (/*info:DYNAMIC_INVOKE*/--d);

        a++;
        a--;
        (/*info:DYNAMIC_INVOKE*/d++);
        (/*info:DYNAMIC_INVOKE*/d--);
      }'''
  });

  testChecker('binary and index operators', {
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
            A operator[](B b) {}
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
            a = a * /*info:DYNAMIC_CAST*/c;
            a = a / b;
            a = a ~/ b;
            a = a % b;
            a = a + b;
            a = a + /*severe:STATIC_TYPE_ERROR*/a;
            a = a - b;
            b = /*severe:STATIC_TYPE_ERROR*/b - b;
            a = a << b;
            a = a >> b;
            a = a & b;
            a = a ^ b;
            a = a | b;
            c = (/*info:DYNAMIC_INVOKE*/c + b);

            String x = 'hello';
            int y = 42;
            x = x + x;
            x = x + /*info:DYNAMIC_CAST*/c;
            x = x + /*severe:STATIC_TYPE_ERROR*/y;

            bool p = true;
            p = p && p;
            p = p && /*info:DYNAMIC_CAST*/c;
            p = (/*info:DYNAMIC_CAST*/c) && p;
            p = (/*info:DYNAMIC_CAST*/c) && /*info:DYNAMIC_CAST*/c;
            p = (/*severe:STATIC_TYPE_ERROR*/y) && p;
            p = c == y;

            a = a[b];
            a = a[/*info:DYNAMIC_CAST*/c];
            c = (/*info:DYNAMIC_INVOKE*/c[b]);
            a[/*severe:STATIC_TYPE_ERROR*/y];
          }
       '''
  });

  testChecker('null coalescing operator', {
    '/main.dart': '''
          class A {}
          class C<T> {}
          main() {
            A a, b;
            a ??= new A();
            b = b ?? new A();

            // downwards inference
            C<int> c, d;
            c ??= /*info:INFERRED_TYPE_ALLOCATION*/new C();
            d = d ?? /*info:INFERRED_TYPE_ALLOCATION*/new C();
          }
       '''
  });

  testChecker('compound assignments', {
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
            D operator [](B index) {}
            void operator []=(B index, D value) {}
          }

          class B {
            A operator -(B b) {}
          }

          class D {
            D operator +(D d) {}
          }

          foo() => new A();

          test() {
            int x = 0;
            x += 5;
            (/*severe:STATIC_TYPE_ERROR*/x += 3.14);

            double y = 0.0;
            y += 5;
            y += 3.14;

            num z = 0;
            z += 5;
            z += 3.14;

            x = /*info:DOWN_CAST_IMPLICIT*/x + z;
            x += /*info:DOWN_CAST_IMPLICIT*/z;
            y = /*info:DOWN_CAST_IMPLICIT*/y + z;
            y += /*info:DOWN_CAST_IMPLICIT*/z;

            dynamic w = 42;
            x += /*info:DYNAMIC_CAST*/w;
            y += /*info:DYNAMIC_CAST*/w;
            z += /*info:DYNAMIC_CAST*/w;

            A a = new A();
            B b = new B();
            var c = foo();
            a = a * b;
            a *= b;
            a *= /*info:DYNAMIC_CAST*/c;
            a /= b;
            a ~/= b;
            a %= b;
            a += b;
            a += /*severe:STATIC_TYPE_ERROR*/a;
            a -= b;
            (/*severe:STATIC_TYPE_ERROR*/b -= b);
            a <<= b;
            a >>= b;
            a &= b;
            a ^= b;
            a |= b;
            (/*info:DYNAMIC_INVOKE*/c += b);

            var d = new D();
            a[b] += d;
            a[/*info:DYNAMIC_CAST*/c] += d;
            a[/*severe:STATIC_TYPE_ERROR*/z] += d;
            a[b] += /*info:DYNAMIC_CAST*/c;
            a[b] += /*severe:STATIC_TYPE_ERROR*/z;
            (/*info:DYNAMIC_INVOKE*/(/*info:DYNAMIC_INVOKE*/c[b]) += d);
          }
       '''
  });

  testChecker('super call placement', {
    '/main.dart': '''
          class Base {
            var x;
            Base() : x = print('Base.1') { print('Base.2'); }
          }

          class Derived extends Base {
            var y, z;
            Derived()
                : y = print('Derived.1'),
                  /*severe:INVALID_SUPER_INVOCATION*/super(),
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

  testChecker('for loop variable', {
    '/main.dart': '''
          foo() {
            for (int i = 0; i < 10; i++) {
              i = /*severe:STATIC_TYPE_ERROR*/"hi";
            }
          }
          bar() {
            for (var i = 0; i < 10; i++) {
              int j = i + 1;
            }
          }
        '''
  });

  testChecker('loadLibrary', {
    '/lib1.dart': '''library lib1;''',
    '/main.dart': r'''
        import 'lib1.dart' deferred as lib1;
        main() {
          Future f = lib1.loadLibrary();
        }'''
  });

  group('invalid overrides', () {
    testChecker('child override', {
      '/main.dart': '''
            class A {}
            class B {}

            class Base {
                A f;
            }

            class T1 extends Base {
              /*severe:INVALID_FIELD_OVERRIDE,severe:INVALID_METHOD_OVERRIDE*/B get f => null;
            }

            class T2 extends Base {
              /*severe:INVALID_FIELD_OVERRIDE,severe:INVALID_METHOD_OVERRIDE*/set f(B b) => null;
            }

            class T3 extends Base {
              /*severe:INVALID_FIELD_OVERRIDE,severe:INVALID_METHOD_OVERRIDE*/final B f;
            }
            class T4 extends Base {
              // two: one for the getter one for the setter.
              /*severe:INVALID_FIELD_OVERRIDE,severe:INVALID_METHOD_OVERRIDE,severe:INVALID_METHOD_OVERRIDE*/B f;
            }

            class T5 implements Base {
              /*severe:INVALID_METHOD_OVERRIDE*/B get f => null;
            }

            class T6 implements Base {
              /*severe:INVALID_METHOD_OVERRIDE*/set f(B b) => null;
            }

            class T7 implements Base {
              /*severe:INVALID_METHOD_OVERRIDE*/final B f;
            }
            class T8 implements Base {
              // two: one for the getter one for the setter.
              /*severe:INVALID_METHOD_OVERRIDE,severe:INVALID_METHOD_OVERRIDE*/B f;
            }
         '''
    });

    testChecker('child override 2', {
      '/main.dart': '''
            class A {}
            class B {}

            class Base {
                m(A a) {}
            }

            class Test extends Base {
                /*severe:INVALID_METHOD_OVERRIDE*/m(B a) {}
            }
         '''
    });
    testChecker('grandchild override', {
      '/main.dart': '''
            class A {}
            class B {}

            class Grandparent {
                m(A a) {}
                int x;
            }
            class Parent extends Grandparent {
            }

            class Test extends Parent {
                /*severe:INVALID_METHOD_OVERRIDE*/m(B a) {}
                /*severe:INVALID_FIELD_OVERRIDE*/int x;
            }
         '''
    });

    testChecker('double override', {
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
                /*severe:INVALID_METHOD_OVERRIDE*/m(B a) {}
            }
         '''
    });

    testChecker('double override 2', {
      '/main.dart': '''
            class A {}
            class B {}

            class Grandparent {
                m(A a) {}
            }
            class Parent extends Grandparent {
                /*severe:INVALID_METHOD_OVERRIDE*/m(B a) {}
            }

            class Test extends Parent {
                m(B a) {}
            }
         '''
    });

    testChecker('mixin override to base', {
      '/main.dart': '''
            class A {}
            class B {}

            class Base {
                m(A a) {}
                int x;
            }

            class M1 {
                m(B a) {}
            }

            class M2 {
                int x;
            }

            class T1 extends Base with /*severe:INVALID_METHOD_OVERRIDE*/M1 {}
            class T2 extends Base with /*severe:INVALID_METHOD_OVERRIDE*/M1, /*severe:INVALID_FIELD_OVERRIDE*/M2 {}
            class T3 extends Base with /*severe:INVALID_FIELD_OVERRIDE*/M2, /*severe:INVALID_METHOD_OVERRIDE*/M1 {}
         '''
    });

    testChecker('mixin override to mixin', {
      '/main.dart': '''
            class A {}
            class B {}

            class Base {
            }

            class M1 {
                m(B a) {}
                int x;
            }

            class M2 {
                m(A a) {}
                int x;
            }

            class T1 extends Base with M1, /*severe:INVALID_METHOD_OVERRIDE,severe:INVALID_FIELD_OVERRIDE*/M2 {}
         '''
    });

    // This is a regression test for a bug in an earlier implementation were
    // names were hiding errors if the first mixin override looked correct,
    // but subsequent ones did not.
    testChecker('no duplicate mixin override', {
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
                with M1, /*severe:INVALID_METHOD_OVERRIDE*/M2, M3 {}
         '''
    });

    testChecker('class override of interface', {
      '/main.dart': '''
            class A {}
            class B {}

            abstract class I {
                m(A a);
            }

            class T1 implements I {
                /*severe:INVALID_METHOD_OVERRIDE*/m(B a) {}
            }
         '''
    });

    testChecker('base class override to child interface', {
      '/main.dart': '''
            class A {}
            class B {}

            abstract class I {
                m(A a);
            }

            class Base {
                m(B a) {}
            }


            class T1 /*severe:INVALID_METHOD_OVERRIDE*/extends Base implements I {
            }
         '''
    });

    testChecker('mixin override of interface', {
      '/main.dart': '''
            class A {}
            class B {}

            abstract class I {
                m(A a);
            }

            class M {
                m(B a) {}
            }

            class T1 extends Object with /*severe:INVALID_METHOD_OVERRIDE*/M
               implements I {}
         '''
    });

    // This is a case were it is incorrect to say that the base class
    // incorrectly overrides the interface.
    testChecker(
        'no errors if subclass correctly overrides base and interface', {
      '/main.dart': '''
            class A {}
            class B {}

            class Base {
                m(A a) {}
            }

            class I1 {
                m(B a) {}
            }

            class T1 /*severe:INVALID_METHOD_OVERRIDE*/extends Base
                implements I1 {}

            class T2 extends Base implements I1 {
                /*severe:INVALID_METHOD_OVERRIDE,severe:INVALID_METHOD_OVERRIDE*/m(a) {}
            }

            class T3 extends Object with /*severe:INVALID_METHOD_OVERRIDE*/Base
                implements I1 {}

            class T4 extends Object with Base implements I1 {
                /*severe:INVALID_METHOD_OVERRIDE,severe:INVALID_METHOD_OVERRIDE*/m(a) {}
            }
         '''
    });
  });

  group('class override of grand interface', () {
    testChecker('interface of interface of child', {
      '/main.dart': '''
              class A {}
              class B {}

              abstract class I1 {
                  m(A a);
              }
              abstract class I2 implements I1 {}

              class T1 implements I2 {
                  /*severe:INVALID_METHOD_OVERRIDE*/m(B a) {}
              }
           '''
    });
    testChecker('superclass of interface of child', {
      '/main.dart': '''
              class A {}
              class B {}

              abstract class I1 {
                  m(A a);
              }
              abstract class I2 extends I1 {}

              class T1 implements I2 {
                  /*severe:INVALID_METHOD_OVERRIDE*/m(B a) {}
              }
           '''
    });
    testChecker('mixin of interface of child', {
      '/main.dart': '''
              class A {}
              class B {}

              abstract class M1 {
                  m(A a);
              }
              abstract class I2 extends Object with M1 {}

              class T1 implements I2 {
                  /*severe:INVALID_METHOD_OVERRIDE*/m(B a) {}
              }
           '''
    });
    testChecker('interface of abstract superclass', {
      '/main.dart': '''
              class A {}
              class B {}

              abstract class I1 {
                  m(A a);
              }
              abstract class Base implements I1 {}

              class T1 extends Base {
                  /*severe:INVALID_METHOD_OVERRIDE*/m(B a) {}
              }
           '''
    });
    testChecker('interface of concrete superclass', {
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

  group('mixin override of grand interface', () {
    testChecker('interface of interface of child', {
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

              class T1 extends Object with /*severe:INVALID_METHOD_OVERRIDE*/M
                  implements I2 {
              }
           '''
    });
    testChecker('superclass of interface of child', {
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

              class T1 extends Object with /*severe:INVALID_METHOD_OVERRIDE*/M
                  implements I2 {
              }
           '''
    });
    testChecker('mixin of interface of child', {
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

              class T1 extends Object with /*severe:INVALID_METHOD_OVERRIDE*/M
                  implements I2 {
              }
           '''
    });
    testChecker('interface of abstract superclass', {
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

              class T1 extends Base with /*severe:INVALID_METHOD_OVERRIDE*/M {
              }
           '''
    });
    testChecker('interface of concrete superclass', {
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

  group('superclass override of grand interface', () {
    testChecker('interface of interface of child', {
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

              class T1 /*severe:INVALID_METHOD_OVERRIDE*/extends Base
                  implements I2 {
              }
           '''
    });
    testChecker('superclass of interface of child', {
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

              class T1 /*severe:INVALID_METHOD_OVERRIDE*/extends Base
                  implements I2 {
              }
           '''
    });
    testChecker('mixin of interface of child', {
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

              class T1 /*severe:INVALID_METHOD_OVERRIDE*/extends Base
                  implements I2 {
              }
           '''
    });
    testChecker('interface of abstract superclass', {
      '/main.dart': '''
              class A {}
              class B {}

              abstract class I1 {
                  m(A a);
              }

              abstract class Base implements I1 {
                  /*severe:INVALID_METHOD_OVERRIDE*/m(B a) {}
              }

              class T1 extends Base {
                  // we consider the base class incomplete because it is
                  // abstract, so we report the error here too.
                  // TODO(sigmund): consider tracking overrides in a fine-grain
                  // manner, then this and the double-overrides would not be
                  // reported.
                  /*severe:INVALID_METHOD_OVERRIDE*/m(B a) {}
              }
           '''
    });
    testChecker('interface of concrete superclass', {
      '/main.dart': '''
              class A {}
              class B {}

              abstract class I1 {
                  m(A a);
              }

              class Base implements I1 {
                  /*severe:INVALID_METHOD_OVERRIDE*/m(B a) {}
              }

              class T1 extends Base {
                  m(B a) {}
              }
           '''
    });
  });

  group('no duplicate reports from overriding interfaces', () {
    testChecker('type overrides same method in multiple interfaces', {
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
                /*severe:INVALID_METHOD_OVERRIDE*/m(B a) {}
              }
           '''
    });

    testChecker('type and base type override same method in interface', {
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
                /*severe:INVALID_METHOD_OVERRIDE*/m(B a) {}
              }

              // If there is no error in the class, we do report the error at
              // the base class:
              class T2 /*severe:INVALID_METHOD_OVERRIDE*/extends Base
                  implements I1 {
              }
           '''
    });

    testChecker('type and mixin override same method in interface', {
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
                /*severe:INVALID_METHOD_OVERRIDE*/m(B a) {}
              }

              class T2 extends Object with /*severe:INVALID_METHOD_OVERRIDE*/M
                  implements I1 {
              }
           '''
    });

    testChecker('two grand types override same method in interface', {
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
              class T1 /*severe:INVALID_METHOD_OVERRIDE*/extends Parent1
                  implements I1 {
              }
              class T2 /*severe:INVALID_METHOD_OVERRIDE*/extends Parent2
                  implements I1 {
              }
           '''
    });

    testChecker('two mixins override same method in interface', {
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
                  with /*severe:INVALID_METHOD_OVERRIDE*/M1
                  with /*severe:INVALID_METHOD_OVERRIDE*/M2
                  implements I1 {
              }
           '''
    });

    testChecker('base type and mixin override same method in interface', {
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
              class T1 /*severe:INVALID_METHOD_OVERRIDE*/extends Base
                  with /*severe:INVALID_METHOD_OVERRIDE*/M
                  implements I1 {
              }
           '''
    });
  });

  testChecker('invalid runtime checks', {
    '/main.dart': '''
          typedef int I2I(int x);
          typedef int D2I(x);
          typedef int II2I(int x, int y);
          typedef int DI2I(x, int y);
          typedef int ID2I(int x, y);
          typedef int DD2I(x, y);

          typedef I2D(int x);
          typedef D2D(x);
          typedef II2D(int x, int y);
          typedef DI2D(x, int y);
          typedef ID2D(int x, y);
          typedef DD2D(x, y);

          int foo(int x) => x;
          int bar(int x, int y) => x + y;

          void main() {
            bool b;
            b = /*info:NON_GROUND_TYPE_CHECK_INFO*/foo is I2I;
            b = /*info:NON_GROUND_TYPE_CHECK_INFO*/foo is D2I;
            b = /*info:NON_GROUND_TYPE_CHECK_INFO*/foo is I2D;
            b = foo is D2D;

            b = /*info:NON_GROUND_TYPE_CHECK_INFO*/bar is II2I;
            b = /*info:NON_GROUND_TYPE_CHECK_INFO*/bar is DI2I;
            b = /*info:NON_GROUND_TYPE_CHECK_INFO*/bar is ID2I;
            b = /*info:NON_GROUND_TYPE_CHECK_INFO*/bar is II2D;
            b = /*info:NON_GROUND_TYPE_CHECK_INFO*/bar is DD2I;
            b = /*info:NON_GROUND_TYPE_CHECK_INFO*/bar is DI2D;
            b = /*info:NON_GROUND_TYPE_CHECK_INFO*/bar is ID2D;
            b = bar is DD2D;

            // For as, the validity of checks is deferred to runtime.
            Function f;
            f = foo as I2I;
            f = foo as D2I;
            f = foo as I2D;
            f = foo as D2D;

            f = bar as II2I;
            f = bar as DI2I;
            f = bar as ID2I;
            f = bar as II2D;
            f = bar as DD2I;
            f = bar as DI2D;
            f = bar as ID2D;
            f = bar as DD2D;
          }
      '''
  });

  group('function modifiers', () {
    testChecker('async', {
      '/main.dart': '''
        import 'dart:async';
        import 'dart:math' show Random;

        dynamic x;

        foo1() async => x;
        Future foo2() async => x;
        Future<int> foo3() async => (/*info:DYNAMIC_CAST*/x);
        Future<int> foo4() async => (new Future<int>.value(/*info:DYNAMIC_CAST*/x));
        Future<int> foo5() async => (/*severe:STATIC_TYPE_ERROR*/new Future<String>.value(/*info:DYNAMIC_CAST*/x));

        bar1() async { return x; }
        Future bar2() async { return x; }
        Future<int> bar3() async { return (/*info:DYNAMIC_CAST*/x); }
        Future<int> bar4() async { return (new Future<int>.value(/*info:DYNAMIC_CAST*/x)); }
        Future<int> bar5() async { return (/*severe:STATIC_TYPE_ERROR*/new Future<String>.value(/*info:DYNAMIC_CAST*/x)); }

        int y;
        Future<int> z;

        void baz() async {
          int a = /*info:DYNAMIC_CAST*/await x;
          int b = await y;
          int c = await z;
          String d = /*severe:STATIC_TYPE_ERROR*/await z;
        }

        Future<bool> get issue_264 async {
          await 42;
          if (new Random().nextBool()) {
            return true;
          } else {
            return new Future<bool>.value(false);
          }
        }
    '''
    });

    testChecker('async*', {
      '/main.dart': '''
        import 'dart:async';

        dynamic x;

        bar1() async* { yield x; }
        Stream bar2() async* { yield x; }
        Stream<int> bar3() async* { yield (/*info:DYNAMIC_CAST*/x); }
        Stream<int> bar4() async* { yield (/*severe:STATIC_TYPE_ERROR*/new Stream<int>()); }

        baz1() async* { yield* (/*info:DYNAMIC_CAST*/x); }
        Stream baz2() async* { yield* (/*info:DYNAMIC_CAST*/x); }
        Stream<int> baz3() async* { yield* (/*warning:DOWN_CAST_COMPOSITE*/x); }
        Stream<int> baz4() async* { yield* new Stream<int>(); }
        Stream<int> baz5() async* { yield* (/*info:INFERRED_TYPE_ALLOCATION*/new Stream()); }
    '''
    });

    testChecker('sync*', {
      '/main.dart': '''
        import 'dart:async';

        dynamic x;

        bar1() sync* { yield x; }
        Iterable bar2() sync* { yield x; }
        Iterable<int> bar3() sync* { yield (/*info:DYNAMIC_CAST*/x); }
        Iterable<int> bar4() sync* { yield (/*severe:STATIC_TYPE_ERROR*/new Iterable<int>()); }

        baz1() sync* { yield* (/*info:DYNAMIC_CAST*/x); }
        Iterable baz2() sync* { yield* (/*info:DYNAMIC_CAST*/x); }
        Iterable<int> baz3() sync* { yield* (/*warning:DOWN_CAST_COMPOSITE*/x); }
        Iterable<int> baz4() sync* { yield* new Iterable<int>(); }
        Iterable<int> baz5() sync* { yield* (/*info:INFERRED_TYPE_ALLOCATION*/new Iterable()); }
    '''
    });
  });
}
