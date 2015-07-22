// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/// General type checking tests
library dev_compiler.test.checker_test;

import 'package:test/test.dart';

import '../testing.dart';

void main() {
  test('ternary operator', () {
    testChecker({
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
            : _comparator = /*warning:DownCastComposite*/(compare == null) ? Comparable.compare : compare,
              _validKey = /*info:InferredType should be pass*/(isValidKey != null) ? isValidKey : ((v) => true);
              _Predicate<Object> _v = /*warning:DownCastComposite*/(isValidKey != null) ? isValidKey : ((v) => true);
              _v = /*info:InferredType should be pass*/(isValidKey != null) ? _v : ((v) => true);
          }
        }
        void main() {
          Object obj = 42;
          dynamic dyn = 42;
          int i = 42;

          // Check the boolean conversion of the condition.
          print((/*severe:StaticTypeError*/i) ? false : true);
          print((/*warning:DownCastImplicit*/obj) ? false : true);
          print((/*info:DynamicCast*/dyn) ? false : true);
        }
      '''
    });
  });

  test('if/for/do/while statements use boolean conversion', () => testChecker({
    '/main.dart': '''
      main() {
        dynamic d = 42;
        Object obj = 42;
        int i = 42;
        bool b = false;

        if (b) {}
        if (/*info:DynamicCast*/dyn) {}
        if (/*warning:DownCastImplicit*/obj) {}
        if (/*severe:StaticTypeError*/i) {}

        while (b) {}
        while (/*info:DynamicCast*/dyn) {}
        while (/*warning:DownCastImplicit*/obj) {}
        while (/*severe:StaticTypeError*/i) {}

        do {} while (b);
        do {} while (/*info:DynamicCast*/dyn);
        do {} while (/*warning:DownCastImplicit*/obj);
        do {} while (/*severe:StaticTypeError*/i);

        for (;b;) {}
        for (;/*info:DynamicCast*/dyn;) {}
        for (;/*warning:DownCastImplicit*/obj;) {}
        for (;/*severe:StaticTypeError*/i;) {}
      }
    '''
  }));

  test('dynamic invocation', () {
    testChecker({
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
          // The analyzer has what I believe is a bug (dartbug.com/23252) which
          // causes the return type of calls to f to be treated as dynamic.
          x = /*info:DynamicCast should be pass*/f(3);
          x = /*severe:StaticTypeError*/f.col(3.0);
          y = /*info:DynamicCast should be severe:StaticTypeError*/f(3);
          y = f.col(3.0);
          f(/*severe:StaticTypeError*/3.0);
          f.col(/*severe:StaticTypeError*/3);
        }
        {
          Function f = new B();
          int x;
          double y;
          x = /*info:DynamicCast, info:DynamicInvoke*/f(3);
          x = /*info:DynamicCast, info:DynamicInvoke*/f.col(3.0);
          y = /*info:DynamicCast, info:DynamicInvoke*/f(3);
          y = /*info:DynamicCast, info:DynamicInvoke*/f.col(3.0);
          (/*info:DynamicInvoke*/f(3.0));
          (/*info:DynamicInvoke*/f.col(3));
        }
        {
          A f = new B();
          int x;
          double y;
          x = /*info:DynamicCast, info:DynamicInvoke*/f(3);
          y = /*info:DynamicCast, info:DynamicInvoke*/f(3);
          (/*info:DynamicInvoke*/f(3.0));
        }
      }
    '''
    });
  });

  test('conversion and dynamic invoke', () {
    testChecker({
      '/helper.dart': '''
      dynamic toString = (int x) => x + 42;
      dynamic hashCode = "hello";
      ''',
      '/main.dart': '''
      import 'helper.dart' as helper;

      class A {
        String x = "hello world";

        void baz1(y) => x + /*info:DynamicCast*/y;
        static baz2(y) => /*info:DynamicInvoke*/y + y;
      }

      void foo(String str) {
        print(str);
      }

      class B {
        String toString([int arg]) => arg.toString();
      }

      void bar(a) {
        foo(/*info:DynamicCast,info:DynamicInvoke*/a.x);
      }

      baz() => new B();

      typedef DynFun(x);
      typedef StrFun(String x);

      var bar1 = bar;

      void main() {
        var a = new A();
        bar(a);
        (/*info:DynamicInvoke*/bar1(a));
        var b = bar;
        (/*info:DynamicInvoke*/b(a));
        var f1 = foo;
        f1("hello");
        dynamic f2 = foo;
        (/*info:DynamicInvoke*/f2("hello"));
        DynFun f3 = foo;
        (/*info:DynamicInvoke*/f3("hello"));
        (/*info:DynamicInvoke*/f3(42));
        StrFun f4 = foo;
        f4("hello");
        a.baz1("hello");
        var b1 = a.baz1;
        (/*info:DynamicInvoke*/b1("hello"));
        A.baz2("hello");
        var b2 = A.baz2;
        (/*info:DynamicInvoke*/b2("hello"));

        dynamic a1 = new B();
        (/*info:DynamicInvoke*/a1.x);
        a1.toString();
        (/*info:DynamicInvoke*/a1.toString(42));
        var toStringClosure = a1.toString;
        (/*info:DynamicInvoke*/a1.toStringClosure());
        (/*info:DynamicInvoke*/a1.toStringClosure(42));
        (/*info:DynamicInvoke*/a1.toStringClosure("hello"));
        a1.hashCode;

        dynamic toString = () => null;
        (/*info:DynamicInvoke*/toString());

        (/*info:DynamicInvoke*/helper.toString());
        var toStringClosure2 = helper.toString;
        (/*info:DynamicInvoke*/toStringClosure2());
        int hashCode = /*info:DynamicCast*/helper.hashCode;

        baz().toString();
        baz().hashCode;
      }
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
          x = /*severe:StaticTypeError*/null;
          x = 42;
          x = /*warning:DownCastImplicit*/z;

          // double is non-nullable
          y = /*severe:StaticTypeError*/null;
          y = /*severe:StaticTypeError*/42;
          y = 42.0;
          y = /*warning:DownCastImplicit*/z;

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
          T foo() => /*warning:DownCastImplicit*/null;

          void bar() {
            int /*severe:InvalidVariableDeclaration*/x;
            num y;
            // TODO(vsm): This should be a runtime check:
            // Transformed to: T z = cast(null, T)
            T /*severe:InvalidVariableDeclaration*/z;
          }

          void baz(T x, [T /*severe:InvalidVariableDeclaration*/y, T z = /*warning:DownCastImplicit*/null]) {
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
          T foo() => /*warning:DownCastImplicit*/null;
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

        A.c1(p): this.x = /*warning:DownCastImplicit*/z, this.y = /*info:DynamicCast*/p;

        A.c2(this.x, this.y);

        A.c3(/*severe:InvalidParameterDeclaration*/num this.x, String this.y);
      }

      class B extends A {
        B() : super(/*severe:StaticTypeError*/"hello");

        B.c2(int x, String y) : super.c2(/*severe:StaticTypeError*/y, 
                                         /*severe:StaticTypeError*/x);

        B.c3(num x, Object y) : super.c3(x, /*warning:DownCastImplicit*/y);
      }

      void main() {
         A a = new A.c2(/*warning:DownCastImplicit*/z, /*severe:StaticTypeError*/z);
         var b = new B.c2(/*severe:StaticTypeError*/"hello", /*warning:DownCastImplicit*/obj);
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
         i = /*info:DynamicCast*/y;
         d = /*info:DynamicCast*/y;
         n = /*info:DynamicCast*/y;
         a = /*info:DynamicCast*/y;
         b = /*info:DynamicCast*/y;
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
         b = /*warning:DownCastImplicit*/a;
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
           left = /*warning:DownCastImplicit*/top;
           left = left;
           left = /*severe:StaticTypeError*/right;
           left = bot;
         }
         {
           right = /*warning:DownCastImplicit*/top;
           right = /*severe:StaticTypeError*/left;
           right = right;
           right = bot;
         }
         {
           bot = /*warning:DownCastImplicit*/top;
           bot = /*warning:DownCastImplicit*/left;
           bot = /*warning:DownCastImplicit*/right;
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
      int _bot(Object x) => /*warning:DownCastImplicit*/x;
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
          f = /*warning:DownCastComposite*/top;
          f = left;
          f = /*warning:DownCastComposite*/right; // Should we reject this?
          f = bot;
        }
        {
          Right f;
          f = /*warning:DownCastComposite*/top;
          f = /*warning:DownCastComposite*/left; // Should we reject this?
          f = right;
          f = bot;
        }
        {
          Bot f;
          f = /*warning:DownCastComposite*/top;
          f = /*warning:DownCastComposite*/left;
          f = /*warning:DownCastComposite*/right;
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
      B _bot(A x) => /*warning:DownCastImplicit*/x;
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
          f = /*warning:DownCastComposite*/top;
          f = left;
          f = /*warning:DownCastComposite*/right; // Should we reject this?
          f = bot;
        }
        {
          Right f;
          f = /*warning:DownCastComposite*/top;
          f = /*warning:DownCastComposite*/left; // Should we reject this?
          f = right;
          f = bot;
        }
        {
          Bot f;
          f = /*warning:DownCastComposite*/top;
          f = /*warning:DownCastComposite*/left;
          f = /*warning:DownCastComposite*/right;
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

      typedef dynamic Top(dynamic x);     // Top of the lattice
      typedef dynamic Left(A x);          // Left branch
      typedef A Right(dynamic x);         // Right branch
      typedef A Bottom(A x);              // Bottom of the lattice

      dynamic left(A x) => x;
      A bot(A x) => x;
      dynamic top(dynamic x) => x;
      A right(dynamic x) => /*info:DynamicCast*/x;

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
          f = /*warning:DownCastComposite*/top;
          f = left;
          f = /*warning:DownCastComposite*/right;
          f = bot;
        }
        {
          Right f;
          f = /*warning:DownCastComposite*/top;
          f = /*warning:DownCastComposite*/left;
          f = right;
          f = bot;
        }
        {
          Bottom f;
          f = /*warning:DownCastComposite*/top;
          f = /*warning:DownCastComposite*/left;
          f = /*warning:DownCastComposite*/right;
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
          f = /*warning:DownCastComposite*/top;
          f = left;
          f = /*warning:DownCastComposite*/right; // Should we reject this?
          f = bot;
        }
        {
          Function2<A, A> f;
          f = /*warning:DownCastComposite*/top;
          f = /*warning:DownCastComposite*/left; // Should we reject this?
          f = right;
          f = bot;
        }
        {
          Function2<A, B> f;
          f = /*warning:DownCastComposite*/top;
          f = /*warning:DownCastComposite*/left;
          f = /*warning:DownCastComposite*/right;
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

          left = /*warning:DownCastComposite*/top;
          left = left;
          left = /*warning:DownCastComposite*/right; // Should we reject this?
          left = bot;

          right = /*warning:DownCastComposite*/top;
          right = /*warning:DownCastComposite*/left; // Should we reject this?
          right = right;
          right = bot;

          bot = /*warning:DownCastComposite*/top;
          bot = /*warning:DownCastComposite*/left;
          bot = /*warning:DownCastComposite*/right;
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
      AToB _bot(BToA f) => /*warning:DownCastComposite*/f;
      AToB bot(BToA f) => f as AToB;

      Function2<B, A> top(AToB f) => f;
      Function2<A, B> left(AToB f) => f;
      Function2<B, A> right(BToA f) => f;
      Function2<A, B> _bot(BToA f) => /*warning:DownCastComposite*/f;
      Function2<A, B> bot(BToA f) => f as Function2<A, B>;


      BToA top(Function2<A, B> f) => f;
      AToB left(Function2<A, B> f) => f;
      BToA right(Function2<B, A> f) => f;
      AToB _bot(Function2<B, A> f) => /*warning:DownCastComposite*/f;
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
          f = /*warning:DownCastComposite*/top;
          f = left;
          f = /*warning:DownCastComposite*/right; // Should we reject this?
          f = bot;
        }
        {
          Function2<BToA, BToA> f; // Right
          f = /*warning:DownCastComposite*/top;
          f = /*warning:DownCastComposite*/left; // Should we reject this?
          f = right;
          f = bot;
        }
        {
          Function2<BToA, AToB> f; // Bot
          f = bot;
          f = /*warning:DownCastComposite*/left;
          f = /*warning:DownCastComposite*/top;
          f = /*warning:DownCastComposite*/left;
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

        left = /*warning:DownCastComposite*/top;
        left = left;
        left =
            /*warning:DownCastComposite should be severe:StaticTypeError*/right;
        left = bot;

        right = /*warning:DownCastComposite*/top;
        right =
            /*warning:DownCastComposite should be severe:StaticTypeError*/left;
        right = right;
        right = bot;

        bot = /*warning:DownCastComposite*/top;
        bot = /*warning:DownCastComposite*/left;
        bot = /*warning:DownCastComposite*/right;
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

         o = /*warning:DownCastComposite*/r;
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

         ro = /*warning:DownCastComposite*/r;
         ro = /*severe:StaticTypeError*/o;
         ro = /*severe:StaticTypeError*/n;
         ro = /*warning:DownCastComposite*/rr;
         ro = ro;
         ro = /*severe:StaticTypeError*/rn;
         ro = oo;
         ro = /*severe:StaticTypeError*/nn;
         ro = /*severe:StaticTypeError*/nnn;

         rn = /*warning:DownCastComposite*/r;
         rn = /*severe:StaticTypeError*/o;
         rn = /*severe:StaticTypeError*/n;
         rn = /*severe:StaticTypeError*/rr;
         rn = /*severe:StaticTypeError*/ro;
         rn = rn;
         rn = /*severe:StaticTypeError*/oo;
         rn = /*severe:StaticTypeError*/nn;
         rn = /*severe:StaticTypeError*/nnn;

         oo = /*warning:DownCastComposite*/r;
         oo = /*warning:DownCastComposite*/o;
         oo = /*severe:StaticTypeError*/n;
         oo = /*warning:DownCastComposite*/rr;
         oo = /*warning:DownCastComposite*/ro;
         oo = /*severe:StaticTypeError*/rn;
         oo = oo;
         oo = /*severe:StaticTypeError*/nn;
         oo = /*severe:StaticTypeError*/nnn;

         nn = /*severe:StaticTypeError*/r;
         nn = /*severe:StaticTypeError*/o;
         nn = /*warning:DownCastComposite*/n;
         nn = /*severe:StaticTypeError*/rr;
         nn = /*severe:StaticTypeError*/ro;
         nn = /*severe:StaticTypeError*/rn;
         nn = /*severe:StaticTypeError*/oo;
         nn = nn;
         nn = nnn;

         nnn = /*severe:StaticTypeError*/r;
         nnn = /*severe:StaticTypeError*/o;
         nnn = /*warning:DownCastComposite*/n;
         nnn = /*severe:StaticTypeError*/rr;
         nnn = /*severe:StaticTypeError*/ro;
         nnn = /*severe:StaticTypeError*/rn;
         nnn = /*severe:StaticTypeError*/oo;
         nnn = /*warning:DownCastComposite*/nn;
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
           f = /*warning:DownCastComposite*/n2n;
           f = /*warning:DownCastComposite*/i2i as Object;
           f = /*warning:DownCastComposite*/n2n as Function;
         }
         {
           N2N f;
           f = /*severe:StaticTypeError*/new A();
           f = new B();
           f = /*warning:DownCastComposite*/i2i;
           f = n2n;
           f = /*warning:DownCastComposite*/i2i as Object;
           f = /*warning:DownCastComposite*/n2n as Function;
         }
         {
           A f;
           f = new A();
           f = /*severe:StaticTypeError*/new B();
           f = /*severe:StaticTypeError*/i2i;
           f = /*severe:StaticTypeError*/n2n;
           f = /*warning:DownCastImplicit*/i2i as Object;
           f = /*warning:DownCastImplicit*/n2n as Function;
         }
         {
           B f;
           f = /*severe:StaticTypeError*/new A();
           f = new B();
           f = /*severe:StaticTypeError*/i2i;
           f = /*severe:StaticTypeError*/n2n;
           f = /*warning:DownCastImplicit*/i2i as Object;
           f = /*warning:DownCastImplicit*/n2n as Function;
         }
         {
           Function f;
           f = new A();
           f = new B();
           f = i2i;
           f = n2n;
           f = /*warning:DownCastImplicit*/i2i as Object;
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
        lOfBs = /*warning:DownCastComposite*/lOfAs;
        lOfBs = lOfBs;
        lOfBs = /*severe:StaticTypeError*/lOfCs;

        // M<T> <: L<S> iff T <: S
        lOfBs = /*severe:StaticTypeError*/mOfAs;
        lOfBs = mOfBs;
        lOfBs = /*severe:StaticTypeError*/mOfCs;

        // N </: L<B>
        lOfBs = /*severe:StaticTypeError*/ns;

        // L<T> <: L<S> iff S <: T
        lOfCs = /*warning:DownCastComposite*/lOfAs;
        lOfCs = /*severe:StaticTypeError*/lOfBs;
        lOfCs = lOfCs;

        // M<T> <: L<S> iff T <: S
        lOfCs = /*severe:StaticTypeError*/mOfAs;
        lOfCs = /*severe:StaticTypeError*/mOfBs;
        lOfCs = mOfCs;

        // N </: L<C>
        lOfCs = /*severe:StaticTypeError*/ns;

        // M<T> <: L<S> iff T <: S
        mOfAs = /*warning:DownCastComposite*/lOfAs;
        mOfAs = /*severe:StaticTypeError*/lOfBs;
        mOfAs = /*severe:StaticTypeError*/lOfCs;

        // M<T> <: M<S> iff T <: S
        mOfAs = mOfAs;
        mOfAs = mOfBs;
        mOfAs = mOfCs;

        // N <: M<A>
        mOfAs = ns;

        // M<T> <: L<S> iff T <: S
        mOfBs = /*warning:DownCastComposite*/lOfAs;
        mOfBs = /*warning:DownCastComposite*/lOfBs;
        mOfBs = /*severe:StaticTypeError*/lOfCs;

        // M<T> <: M<S> iff T <: S
        mOfBs = /*warning:DownCastComposite*/mOfAs;
        mOfBs = mOfBs;
        mOfBs = /*severe:StaticTypeError*/mOfCs;

        // N </: M<B>
        mOfBs = /*severe:StaticTypeError*/ns;

        // M<T> <: L<S> iff T <: S
        mOfCs = /*warning:DownCastComposite*/lOfAs;
        mOfCs = /*severe:StaticTypeError*/lOfBs;
        mOfCs = /*warning:DownCastComposite*/lOfCs;

        // M<T> <: M<S> iff T :< S
        mOfCs = /*warning:DownCastComposite*/mOfAs;
        mOfCs = /*severe:StaticTypeError*/mOfBs;
        mOfCs = mOfCs;

        // N </: L<C>
        mOfCs = /*severe:StaticTypeError*/ns;

        // Concrete subclass subtyping
        ns = /*warning:DownCastImplicit*/lOfAs;
        ns = /*severe:StaticTypeError*/lOfBs;
        ns = /*severe:StaticTypeError*/lOfCs;
        ns = /*warning:DownCastImplicit*/mOfAs;
        ns = /*severe:StaticTypeError*/mOfBs;
        ns = /*severe:StaticTypeError*/mOfCs;
        ns = ns;
      }
   '''
    }, relaxedCasts: false);
  });

  test('Relaxed casts', () {
    testChecker({
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
          lOfAs = /*warning:DownCastComposite*/mOfDs;
          lOfAs = /*severe:StaticTypeError*/mOfOs;
          lOfAs = mOfAs;
          lOfAs = /*warning:DownCastComposite*/lOfDs;
          lOfAs = /*warning:DownCastComposite*/lOfOs;
          lOfAs = lOfAs;
        }
        {
          mOfDs = mOfDs;
          mOfDs = mOfOs;
          mOfDs = mOfAs;
          mOfDs = /*warning:DownCastImplicit*/lOfDs;
          mOfDs = /*warning:DownCastImplicit*/lOfOs;
          mOfDs = /*warning:DownCastImplicit*/lOfAs;
        }
        {
          mOfOs = mOfDs;
          mOfOs = mOfOs;
          mOfOs = mOfAs;
          mOfOs = /*warning:DownCastImplicit*/lOfDs;
          mOfOs = /*warning:DownCastImplicit*/lOfOs;
          mOfOs = /*severe:StaticTypeError*/lOfAs;
        }
        {
          mOfAs = /*warning:DownCastComposite*/mOfDs;
          mOfAs = /*warning:DownCastComposite*/mOfOs;
          mOfAs = mOfAs;
          mOfAs = /*warning:DownCastComposite*/lOfDs;
          mOfAs = /*warning:DownCastComposite*/lOfOs;
          mOfAs = /*warning:DownCastComposite*/lOfAs;
        }

      }
   '''
    }, relaxedCasts: true);
  });

  test('Subtyping literals', () {
    testChecker({
      '/main.dart': '''
          test() {
            Iterable i1 = [1, 2, 3];
            i1 = <int>[1, 2, 3];

            List l1 = [1, 2, 3];
            l1 = <int>[1, 2, 3];

            Iterable<int> i2 = /*severe:StaticTypeError*/[1, 2, 3];
            i2 = /*warning:DownCastComposite*/i1;
            i2 = /*warning:DownCastComposite*/l1;
            i2 = <int>[1, 2, 3];

            List<int> l2 = /*severe:StaticTypeError*/[1, 2, 3];
            l2 = /*warning:DownCastComposite*/i1;
            l2 = /*warning:DownCastComposite*/l1;

            l2 = /*severe:StaticTypeError*/new List();
            l2 = /*severe:StaticTypeError*/new List(10);
            l2 = /*severe:StaticTypeError*/new List.filled(10, 42);
          }
   '''
    }, inferDownwards: false);
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
               l = <int>[/*warning:DownCastImplicit*/n];
               l = <int>[i, /*warning:DownCastImplicit*/n, /*severe:StaticTypeError*/s];
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
               m = <String, int>{s: /*warning:DownCastImplicit*/n};
               m = <String, int>{s: i,
                                 s: /*warning:DownCastImplicit*/n,
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
    String mk(String error1, String error2) => '''
          class A {
            static const num n = 3.0;
            static const int i = /*$error2*/n;
            final int fi;
            const A(num a) : this.fi = /*$error1*/a;
          }
          class B extends A {
            const B(Object a) : super(/*$error1*/a);
          }
          void foo(Object o) {
            var a = const A(/*$error1*/o);
          }
     ''';
    testChecker(
        {'/main.dart': mk("warning:DownCastImplicit", "info:AssignmentCast")});
  });

  test('casts in conditionals', () {
    testChecker({
      '/main.dart': '''
          main() {
            bool b = true;
            num x = b ? 1 : 2.3;
            int y = /*info:AssignmentCast*/b ? 1 : 2.3;
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
            /*severe:InvalidMethodOverride,severe:InvalidMethodOverride*/dynamic f4;
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
            /*severe:InferableOverride,severe:InvalidMethodOverride*/var f3;
            /*severe:InvalidMethodOverride,severe:InvalidMethodOverride*/dynamic f4;
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
            /*severe:InvalidMethodOverride*/void set f3(value) {}
            /*severe:InvalidMethodOverride*/void set f4(dynamic value) {}
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
            /*severe:InvalidMethodOverride*/void set f3(value) {}
            /*severe:InvalidMethodOverride*/void set f4(dynamic value) {}
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
            /*severe:InvalidMethodOverride*/m5(value) {}
            /*severe:InvalidMethodOverride*/dynamic m6(dynamic value) {}
          }
       '''
    }, inferFromOverrides: true);
  });

  test('unary operators', () => testChecker({
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
        (/*info:DynamicInvoke*/~d);

        !/*severe:StaticTypeError*/a;
        !/*info:DynamicCast*/d;

        -a;
        (/*info:DynamicInvoke*/-d);

        ++a;
        --a;
        (/*info:DynamicInvoke*/++d);
        (/*info:DynamicInvoke*/--d);

        a++;
        a--;
        (/*info:DynamicInvoke*/d++);
        (/*info:DynamicInvoke*/d--);
      }'''
  }));

  test('binary and index operators', () {
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
            a = a * /*info:DynamicCast*/c;
            a = a / b;
            a = a ~/ b;
            a = a % b;
            a = a + b;
            a = a + /*severe:StaticTypeError*/a;
            a = a - b;
            b = /*severe:StaticTypeError*/b - b;
            a = a << b;
            a = a >> b;
            a = a & b;
            a = a ^ b;
            a = a | b;
            c = (/*info:DynamicInvoke*/c + b);

            String x = 'hello';
            int y = 42;
            x = x + x;
            x = x + /*info:DynamicCast*/c;
            x = x + /*severe:StaticTypeError*/y;

            bool p = true;
            p = p && p;
            p = p && /*info:DynamicCast*/c;
            p = (/*info:DynamicCast*/c) && p;
            p = (/*info:DynamicCast*/c) && /*info:DynamicCast*/c;
            p = (/*severe:StaticTypeError*/y) && p;
            p = c == y;

            a = a[b];
            a = a[/*info:DynamicCast*/c];
            c = (/*info:DynamicInvoke*/c[b]);
            a[/*severe:StaticTypeError*/y];
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
            (/*severe:StaticTypeError*/x += 3.14);

            double y = 0.0;
            y += 5;
            y += 3.14;

            num z = 0;
            z += 5;
            z += 3.14;

            x = /*warning:DownCastImplicit*/x + z;
            x += /*warning:DownCastImplicit*/z;
            y = /*warning:DownCastImplicit*/y + z;
            y += /*warning:DownCastImplicit*/z;

            dynamic w = 42;
            x += /*info:DynamicCast*/w;
            y += /*info:DynamicCast*/w;
            z += /*info:DynamicCast*/w;

            A a = new A();
            B b = new B();
            var c = foo();
            a = a * b;
            a *= b;
            a *= /*info:DynamicCast*/c;
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
            (/*info:DynamicInvoke*/c += b);

            var d = new D();
            a[b] += d;
            a[/*info:DynamicCast*/c] += d;
            a[/*severe:StaticTypeError*/z] += d;
            a[b] += /*info:DynamicCast*/c;
            a[b] += /*severe:StaticTypeError*/z;
            (/*info:DynamicInvoke*/(/*info:DynamicInvoke*/c[b]) += d);
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
                /*severe:InvalidMethodOverride,severe:InvalidMethodOverride*/m(a) {}
            }

            class T3 extends Object with /*severe:InvalidMethodOverride*/Base
                implements I1 {}

            class T4 extends Object with Base implements I1 {
                /*severe:InvalidMethodOverride,severe:InvalidMethodOverride*/m(a) {}
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

  test('invalid runtime checks', () {
    testChecker({
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
            b = /*severe:InvalidRuntimeCheckError*/foo is I2I;
            b = /*severe:InvalidRuntimeCheckError*/foo is D2I;
            b = /*severe:InvalidRuntimeCheckError*/foo is I2D;
            b = foo is D2D;

            b = /*severe:InvalidRuntimeCheckError*/bar is II2I;
            b = /*severe:InvalidRuntimeCheckError*/bar is DI2I;
            b = /*severe:InvalidRuntimeCheckError*/bar is ID2I;
            b = /*severe:InvalidRuntimeCheckError*/bar is II2D;
            b = /*severe:InvalidRuntimeCheckError*/bar is DD2I;
            b = /*severe:InvalidRuntimeCheckError*/bar is DI2D;
            b = /*severe:InvalidRuntimeCheckError*/bar is ID2D;
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
  });

  test('custom URL mappings', () => testChecker({
    '/main.dart': '''
      import 'dart:foobar' show Baz;
      main() {
        print(Baz.quux);
      }'''
  },
      customUrlMappings: {
    'dart:foobar': '$testDirectory/checker/dart_foobar.dart'
  }));

  group('function modifiers', () {
    test('async', () => testChecker({
      '/main.dart': '''
        import 'dart:async';

        dynamic x;

        foo1() async => x;
        Future foo2() async => x;
        Future<int> foo3() async => (/*info:DynamicCast*/x);
        Future<int> foo4() async => (/*severe:StaticTypeError*/new Future<int>(x));

        bar1() async { return x; }
        Future bar2() async { return x; }
        Future<int> bar3() async { return (/*info:DynamicCast*/x); }
        Future<int> bar4() async { return (/*severe:StaticTypeError*/new Future<int>(x)); }

        int y;
        Future<int> z;

        void baz() async {
          int a = /*info:DynamicCast*/await x;
          int b = await y;
          int c = await z;
          String d = /*severe:StaticTypeError*/await z;
        }

        Future<bool> get issue_264 async {
          await 42;
          return false;
        }
    '''
    }));

    test('async*', () => testChecker({
      '/main.dart': '''
        import 'dart:async';

        dynamic x;

        bar1() async* { yield x; }
        Stream bar2() async* { yield x; }
        Stream<int> bar3() async* { yield (/*info:DynamicCast*/x); }
        Stream<int> bar4() async* { yield (/*severe:StaticTypeError*/new Stream<int>()); }

        baz1() async* { yield* (/*info:DynamicCast*/x); }
        Stream baz2() async* { yield* (/*info:DynamicCast*/x); }
        Stream<int> baz3() async* { yield* (/*warning:DownCastComposite*/x); }
        Stream<int> baz4() async* { yield* new Stream<int>(); }
        Stream<int> baz5() async* { yield* (/*info:InferredTypeAllocation*/new Stream()); }
    '''
    }));

    test('sync*', () => testChecker({
      '/main.dart': '''
        import 'dart:async';

        dynamic x;

        bar1() sync* { yield x; }
        Iterable bar2() sync* { yield x; }
        Iterable<int> bar3() sync* { yield (/*info:DynamicCast*/x); }
        Iterable<int> bar4() sync* { yield (/*severe:StaticTypeError*/new Iterable<int>()); }

        baz1() sync* { yield* (/*info:DynamicCast*/x); }
        Iterable baz2() sync* { yield* (/*info:DynamicCast*/x); }
        Iterable<int> baz3() sync* { yield* (/*warning:DownCastComposite*/x); }
        Iterable<int> baz4() sync* { yield* new Iterable<int>(); }
        Iterable<int> baz5() sync* { yield* (/*info:InferredTypeAllocation*/new Iterable()); }
    '''
    }));
  });
}
