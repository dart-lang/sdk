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
  initStrongModeTests();

  test('ternary operator', () {
    checkFile('''
        abstract class Comparable<T> {
          int compareTo(T other);
          static int compare(Comparable a, Comparable b) => a.compareTo(b);
        }
        typedef int Comparator<T>(T a, T b);

        typedef bool _Predicate<T>(T value);

        class SplayTreeMap<K, V> {
          Comparator<K> _comparator;
          _Predicate _validKey;

          // The warning on assigning to _comparator is legitimate. Since K has
          // no bound, all we know is that it's object. _comparator's function
          // type is effectively:              (Object, Object) -> int
          // We are assigning it a fn of type: (Comparable, Comparable) -> int
          // There's no telling if that will work. For example, consider:
          //
          //     new SplayTreeMap<Uri>();
          //
          // This would end up calling .compareTo() on a Uri, which doesn't
          // define that since it doesn't implement Comparable.
          SplayTreeMap([int compare(K key1, K key2),
                        bool isValidKey(potentialKey)])
            : _comparator = /*warning:DOWN_CAST_COMPOSITE*/(compare == null) ? Comparable.compare : compare,
              _validKey = (isValidKey != null) ? isValidKey : ((v) => true) {
            _Predicate<Object> v = (isValidKey != null)
                ? isValidKey : (/*info:INFERRED_TYPE_CLOSURE*/(_) => true);

            v = (isValidKey != null)
                 ? v : (/*info:INFERRED_TYPE_CLOSURE*/(_) => true);
          }
        }
        void main() {
          Object obj = 42;
          dynamic dyn = 42;
          int i = 42;

          // Check the boolean conversion of the condition.
          print(/*warning:NON_BOOL_CONDITION*/i ? false : true);
          print((/*info:DOWN_CAST_IMPLICIT*/obj) ? false : true);
          print((/*info:DYNAMIC_CAST*/dyn) ? false : true);
        }
      ''');
  });

  test('least upper bounds', () {
    checkFile('''
      typedef T Returns<T>();

      // regression test for https://github.com/dart-lang/sdk/issues/26094
      class A <S extends  Returns<S>, T extends Returns<T>> {
        int test(bool b) {
          S s;
          T t;
          if (b) {
            return /*warning:RETURN_OF_INVALID_TYPE*/b ? s : t;
          } else {
            return /*warning:RETURN_OF_INVALID_TYPE*/s ?? t;
          }
        }
      }

      class B<S, T extends S> {
        T t;
        S s;
        int test(bool b) {
          return /*warning:RETURN_OF_INVALID_TYPE*/b ? t : s;
        }
      }

      class C {
        // Check that the least upper bound of two types with the same
        // class but different type arguments produces the pointwise
        // least upper bound of the type arguments
        int test1(bool b) {
          List<int> li;
          List<double> ld;
          return /*warning:RETURN_OF_INVALID_TYPE*/b ? li : ld;
        }
        // TODO(leafp): This case isn't handled yet.  This test checks
        // the case where two related classes are instantiated with related
        // but different types.
        Iterable<num> test2(bool b) {
          List<int> li;
          Iterable<double> id;
          int x =
              /*info:ASSIGNMENT_CAST should be warning:INVALID_ASSIGNMENT*/
              b ? li : id;
          return /*warning:DOWN_CAST_COMPOSITE should be pass*/b ? li : id;
        }
      }
      ''');
  });

  test('setter return types', () {
    checkFile('''
      void voidFn() => null;
      class A {
        set a(y) => 4;
        set b(y) => voidFn();
        void set c(y) => /*warning:RETURN_OF_INVALID_TYPE*/4;
        void set d(y) => voidFn();
        /*warning:NON_VOID_RETURN_FOR_SETTER*/int set e(y) => 4;
        /*warning:NON_VOID_RETURN_FOR_SETTER*/int set f(y) =>
            /*warning:RETURN_OF_INVALID_TYPE*/voidFn();
        set g(y) {return /*warning:RETURN_OF_INVALID_TYPE*/4;}
        void set h(y) {return /*warning:RETURN_OF_INVALID_TYPE*/4;}
        /*warning:NON_VOID_RETURN_FOR_SETTER*/int set i(y) {return 4;}
      }
    ''');
  });

  test('if/for/do/while statements use boolean conversion', () {
    checkFile('''
      main() {
        dynamic dyn = 42;
        Object obj = 42;
        int i = 42;
        bool b = false;

        if (b) {}
        if (/*info:DYNAMIC_CAST*/dyn) {}
        if (/*info:DOWN_CAST_IMPLICIT*/obj) {}
        if (/*warning:NON_BOOL_CONDITION*/i) {}

        while (b) {}
        while (/*info:DYNAMIC_CAST*/dyn) {}
        while (/*info:DOWN_CAST_IMPLICIT*/obj) {}
        while (/*warning:NON_BOOL_CONDITION*/i) {}

        do {} while (b);
        do {} while (/*info:DYNAMIC_CAST*/dyn);
        do {} while (/*info:DOWN_CAST_IMPLICIT*/obj);
        do {} while (/*warning:NON_BOOL_CONDITION*/i);

        for (;b;) {}
        for (;/*info:DYNAMIC_CAST*/dyn;) {}
        for (;/*info:DOWN_CAST_IMPLICIT*/obj;) {}
        for (;/*warning:NON_BOOL_CONDITION*/i;) {}
      }
    ''');
  });

  test('for-in casts supertype sequence to iterable', () {
    checkFile('''
      main() {
        dynamic d;
        for (var i in /*info:DYNAMIC_CAST*/d) {}

        Object o;
        for (var i in /*info:DOWN_CAST_IMPLICIT*/o) {}
      }
    ''');
  });

  test('await for-in casts supertype sequence to stream', () {
    checkFile('''
      main() async {
        dynamic d;
        await for (var i in /*info:DYNAMIC_CAST*/d) {}

        Object o;
        await for (var i in /*info:DOWN_CAST_IMPLICIT*/o) {}
      }
    ''');
  });

  test('for-in casts iterable element to variable', () {
    checkFile('''
      main() {
        // Don't choke if sequence is not iterable.
        for (var i in /*warning:FOR_IN_OF_INVALID_TYPE*/1234) {}

        // Dynamic cast.
        for (String /*info:DYNAMIC_CAST*/s in <dynamic>[]) {}

        // Identity cast.
        for (String s in <String>[]) {}

        // Untyped.
        for (var s in <String>[]) {}

        // Downcast.
        for (int /*info:DOWN_CAST_IMPLICIT*/i in <num>[]) {}
      }
    ''');
  });

  test('await for-in casts stream element to variable', () {
    checkFile('''
      import 'dart:async';
      main() async {
        // Don't choke if sequence is not stream.
        await for (var i in /*warning:FOR_IN_OF_INVALID_TYPE*/1234) {}

        // Dynamic cast.
        await for (String /*info:DYNAMIC_CAST*/s in new Stream<dynamic>()) {}

        // Identity cast.
        await for (String s in new Stream<String>()) {}

        // Untyped.
        await for (var s in new Stream<String>()) {}

        // Downcast.
        await for (int /*info:DOWN_CAST_IMPLICIT*/i in new Stream<num>()) {}
      }
    ''');
  });

  test('dynamic invocation', () {
    checkFile('''
      typedef dynamic A(dynamic x);
      class B {
        int call(int x) => x;
        double col(double x) => x;
      }
      void main() {
        {
          B f = new B();
          int x;
          double y;
          x = f(3);
          x = /*warning:INVALID_ASSIGNMENT*/f.col(3.0);
          y = /*warning:INVALID_ASSIGNMENT*/f(3);
          y = f.col(3.0);
          f(/*warning:ARGUMENT_TYPE_NOT_ASSIGNABLE*/3.0);
          f.col(/*warning:ARGUMENT_TYPE_NOT_ASSIGNABLE*/3);
        }
        {
          Function f = new B();
          int x;
          double y;
          x = /*info:DYNAMIC_CAST, info:DYNAMIC_INVOKE*/f(3);
          x = /*info:DYNAMIC_CAST, info:DYNAMIC_INVOKE, info:INVALID_ASSIGNMENT*/f.col(3.0);
          y = /*info:DYNAMIC_CAST, info:DYNAMIC_INVOKE*/f(3);
          y = /*info:DYNAMIC_CAST, info:DYNAMIC_INVOKE*/f.col(3.0);
          /*info:DYNAMIC_INVOKE*/f(3.0);
          // Through type propagation, we know f is actually a B, hence the
          // hint.
          /*info:DYNAMIC_INVOKE*/f.col(/*info:ARGUMENT_TYPE_NOT_ASSIGNABLE*/3);
        }
        {
          A f = new B();
          int x;
          double y;
          x = /*info:DYNAMIC_CAST, info:DYNAMIC_INVOKE*/f(3);
          y = /*info:DYNAMIC_CAST, info:DYNAMIC_INVOKE*/f(3);
          /*info:DYNAMIC_INVOKE*/f(3.0);
        }
        {
          dynamic g = new B();
          /*info:DYNAMIC_INVOKE*/g.call(/*info:ARGUMENT_TYPE_NOT_ASSIGNABLE*/32.0);
          /*info:DYNAMIC_INVOKE*/g.col(42.0);
          /*info:DYNAMIC_INVOKE*/g.foo(42.0);
          /*info:DYNAMIC_INVOKE*/g./*info:UNDEFINED_GETTER*/x;
          A f = new B();
          /*info:DYNAMIC_INVOKE*/f.col(42.0);
          /*info:DYNAMIC_INVOKE*/f.foo(42.0);
          /*info:DYNAMIC_INVOKE*/f./*warning:UNDEFINED_GETTER*/x;
        }
      }
    ''');
  });

  test('conversion and dynamic invoke', () {
    addFile(
        '''
      dynamic toString = (int x) => x + 42;
      dynamic hashCode = "hello";
      ''',
        name: '/helper.dart');
    checkFile('''
      import 'helper.dart' as helper;

      class A {
        String x = "hello world";

        void baz1(y) { x + /*info:DYNAMIC_CAST*/y; }
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
        (/*info:DYNAMIC_INVOKE*/a1./*info:UNDEFINED_GETTER*/x);
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
    ''');
  });

  test('Constructors', () {
    checkFile('''
      const num z = 25;
      Object obj = "world";

      class A {
        int x;
        String y;

        A(this.x) : this.y = /*warning:FIELD_INITIALIZER_NOT_ASSIGNABLE*/42;

        A.c1(p): this.x = /*info:DOWN_CAST_IMPLICIT*/z, this.y = /*info:DYNAMIC_CAST*/p;

        A.c2(this.x, this.y);

        A.c3(/*severe:INVALID_PARAMETER_DECLARATION*/num this.x, String this.y);
      }

      class B extends A {
        B() : super(/*warning:ARGUMENT_TYPE_NOT_ASSIGNABLE*/"hello");

        B.c2(int x, String y) : super.c2(/*warning:ARGUMENT_TYPE_NOT_ASSIGNABLE*/y,
                                         /*warning:ARGUMENT_TYPE_NOT_ASSIGNABLE*/x);

        B.c3(num x, Object y) : super.c3(x, /*info:DOWN_CAST_IMPLICIT*/y);
      }

      void main() {
         A a = new A.c2(/*info:DOWN_CAST_IMPLICIT*/z, /*warning:ARGUMENT_TYPE_NOT_ASSIGNABLE*/z);
         var b = new B.c2(/*warning:ARGUMENT_TYPE_NOT_ASSIGNABLE*/"hello", /*info:DOWN_CAST_IMPLICIT*/obj);
      }
   ''');
  });

  test('Unbound variable', () {
    checkFile('''
      void main() {
         dynamic y = /*warning:UNDEFINED_IDENTIFIER should be error*/unboundVariable;
      }
   ''');
  });

  test('Unbound type name', () {
    checkFile('''
      void main() {
         /*warning:UNDEFINED_CLASS should be error*/AToB y;
      }
   ''');
  });

  // Regression test for https://github.com/dart-lang/sdk/issues/25069
  test('Void subtyping', () {
    checkFile('''
      typedef int Foo();
      void foo() {}
      void main () {
        Foo x = /*warning:INVALID_ASSIGNMENT,info:USE_OF_VOID_RESULT*/foo();
      }
   ''');
  });

  group('Ground type subtyping:', () {
    test('dynamic is top', () {
      checkFile('''

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
   ''');
    });

    test('dynamic downcasts', () {
      checkFile('''

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
   ''');
    });

    test('assigning a class', () {
      checkFile('''

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
         i = /*warning:INVALID_ASSIGNMENT*/a;
         d = /*warning:INVALID_ASSIGNMENT*/a;
         n = /*warning:INVALID_ASSIGNMENT*/a;
         a = a;
         b = /*info:DOWN_CAST_IMPLICIT*/a;
      }
   ''');
    });

    test('assigning a subclass', () {
      checkFile('''

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
         i = /*warning:INVALID_ASSIGNMENT*/b;
         d = /*warning:INVALID_ASSIGNMENT*/b;
         n = /*warning:INVALID_ASSIGNMENT*/b;
         a = b;
         b = b;
         c = /*warning:INVALID_ASSIGNMENT*/b;
      }
   ''');
    });

    test('interfaces', () {
      checkFile('''

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
           left = /*warning:INVALID_ASSIGNMENT*/right;
           left = bot;
         }
         {
           right = /*info:DOWN_CAST_IMPLICIT*/top;
           right = /*warning:INVALID_ASSIGNMENT*/left;
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
   ''');
    });
  });

  group('Function typing and subtyping:', () {
    test('int and object', () {
      checkFile('''

      typedef Object Top(int x);      // Top of the lattice
      typedef int Left(int x);        // Left branch
      typedef int Left2(int x);       // Left branch
      typedef Object Right(Object x); // Right branch
      typedef int Bot(Object x);      // Bottom of the lattice

      Object globalTop(int x) => x;
      int globalLeft(int x) => x;
      Object globalRight(Object x) => x;
      int bot_(Object x) => /*info:DOWN_CAST_IMPLICIT*/x;
      int globalBot(Object x) => x as int;

      void main() {
        // Note: use locals so we only know the type, not that it's a specific
        // function declaration. (we can issue better errors in that case.)
        var top = globalTop;
        var left = globalLeft;
        var right = globalRight;
        var bot = globalBot;

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
   ''');
    });

    test('classes', () {
      checkFile('''

      class A {}
      class B extends A {}

      typedef A Top(B x);   // Top of the lattice
      typedef B Left(B x);  // Left branch
      typedef B Left2(B x); // Left branch
      typedef A Right(A x); // Right branch
      typedef B Bot(A x);   // Bottom of the lattice

      B left(B x) => x;
      B bot_(A x) => /*info:DOWN_CAST_IMPLICIT*/x;
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
          f = /*severe:STATIC_TYPE_ERROR*/top;
          f = left;
          f = /*severe:STATIC_TYPE_ERROR*/right;
          f = bot;
        }
        {
          Right f;
          f = /*severe:STATIC_TYPE_ERROR*/top;
          f = /*severe:STATIC_TYPE_ERROR*/left;
          f = right;
          f = bot;
        }
        {
          Bot f;
          f = /*severe:STATIC_TYPE_ERROR*/top;
          f = /*severe:STATIC_TYPE_ERROR*/left;
          f = /*severe:STATIC_TYPE_ERROR*/right;
          f = bot;
        }
      }
   ''');
    });

    test('dynamic', () {
      checkFile('''

      class A {}

      typedef dynamic Top(dynamic x);     // Top of the lattice
      typedef dynamic Left(A x);          // Left branch
      typedef A Right(dynamic x);         // Right branch
      typedef A Bottom(A x);              // Bottom of the lattice

      void main() {
        Top top;
        Left left;
        Right right;
        Bottom bot;
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
   ''');
    });

    test('dynamic functions - closures are not fuzzy', () {
      // Regression test for
      // https://github.com/dart-lang/sdk/issues/26118
      // https://github.com/dart-lang/sdk/issues/26156
      checkFile('''
        void takesF(void f(int x)) {}

        typedef void TakesInt(int x);

        void update(_) {}
        void updateOpt([_]) {}
        void updateOptNum([num x]) {}

        class A {
          TakesInt f;
          A(TakesInt g) {
            f = update;
            f = updateOpt;
            f = updateOptNum;
          }
          TakesInt g(bool a, bool b) {
            if (a) {
              return update;
            } else if (b) {
              return updateOpt;
            } else {
              return updateOptNum;
            }
          }
        }

        void test0() {
          takesF(update);
          takesF(updateOpt);
          takesF(updateOptNum);
          TakesInt f;
          f = update;
          f = updateOpt;
          f = updateOptNum;
          new A(update);
          new A(updateOpt);
          new A(updateOptNum);
        }

        void test1() {
          void takesF(f(int x)) => null;
          takesF((dynamic y) => 3);
        }

        void test2() {
          int x;
          int f/*<T>*/(/*=T*/ t, callback(/*=T*/ x)) { return 3; }
          f(x, (y) => 3);
        }
     ''');
    });

    test('dynamic - known functions', () {
      // Our lattice should look like this:
      //
      //
      //           Bot -> Top
      //          /        \
      //      A -> Top    Bot -> A
      //       /     \      /
      // Top -> Top   A -> A
      //         \      /
      //         Top -> A
      //
      // Note that downcasts of known functions are promoted to
      // static type errors, since they cannot succeed.
      // This makes some of what look like downcasts turn into
      // type errors below.
      checkFile('''
        class A {}

        typedef dynamic BotTop(dynamic x);
        typedef dynamic ATop(A x);
        typedef A BotA(dynamic x);
        typedef A AA(A x);
        typedef A TopA(Object x);
        typedef dynamic TopTop(Object x);

        dynamic aTop(A x) => x;
        A aa(A x) => x;
        dynamic topTop(dynamic x) => x;
        A topA(dynamic x) => /*info:DYNAMIC_CAST*/x;
        void apply/*<T>*/(/*=T*/ f0, /*=T*/ f1, /*=T*/ f2,
                          /*=T*/ f3, /*=T*/ f4, /*=T*/ f5) {}
        void main() {
          BotTop botTop;
          BotA botA;
          {
            BotTop f;
            f = topA;
            f = topTop;
            f = aa;
            f = aTop;
            f = botA;
            f = botTop;
            apply/*<BotTop>*/(
                topA,
                topTop,
                aa,
                aTop,
                botA,
                botTop
                              );
            apply/*<BotTop>*/(
                (dynamic x) => new A(),
                (dynamic x) => (x as Object),
                (A x) => x,
                (A x) => null,
                botA,
                botTop
                              );
          }
          {
            ATop f;
            f = topA;
            f = topTop;
            f = aa;
            f = aTop;
            f = /*warning:DOWN_CAST_COMPOSITE should be severe:STATIC_TYPE_ERROR*/botA;
            f = /*warning:DOWN_CAST_COMPOSITE*/botTop;
            apply/*<ATop>*/(
                topA,
                topTop,
                aa,
                aTop,
                /*warning:DOWN_CAST_COMPOSITE should be severe:STATIC_TYPE_ERROR*/botA,
                /*warning:DOWN_CAST_COMPOSITE*/botTop
                            );
            apply/*<ATop>*/(
                (dynamic x) => new A(),
                (dynamic x) => (x as Object),
                (A x) => x,
                (A x) => null,
                /*warning:DOWN_CAST_COMPOSITE should be severe:STATIC_TYPE_ERROR*/botA,
                /*warning:DOWN_CAST_COMPOSITE*/botTop
                            );
          }
          {
            BotA f;
            f = topA;
            f = /*severe:STATIC_TYPE_ERROR*/topTop;
            f = aa;
            f = /*severe:STATIC_TYPE_ERROR*/aTop;
            f = botA;
            f = /*warning:DOWN_CAST_COMPOSITE*/botTop;
            apply/*<BotA>*/(
                topA,
                /*severe:STATIC_TYPE_ERROR*/topTop,
                aa,
                /*severe:STATIC_TYPE_ERROR*/aTop,
                botA,
                /*warning:DOWN_CAST_COMPOSITE*/botTop
                            );
            apply/*<BotA>*/(
                (dynamic x) => new A(),
                /*severe:STATIC_TYPE_ERROR*/(dynamic x) => (x as Object),
                (A x) => x,
                /*severe:STATIC_TYPE_ERROR*/(A x) => (x as Object),
                botA,
                /*warning:DOWN_CAST_COMPOSITE*/botTop
                            );
          }
          {
            AA f;
            f = topA;
            f = /*severe:STATIC_TYPE_ERROR*/topTop;
            f = aa;
            f = /*severe:STATIC_TYPE_ERROR*/aTop; // known function
            f = /*warning:DOWN_CAST_COMPOSITE*/botA;
            f = /*warning:DOWN_CAST_COMPOSITE*/botTop;
            apply/*<AA>*/(
                topA,
                /*severe:STATIC_TYPE_ERROR*/topTop,
                aa,
                /*severe:STATIC_TYPE_ERROR*/aTop, // known function
                /*warning:DOWN_CAST_COMPOSITE*/botA,
                /*warning:DOWN_CAST_COMPOSITE*/botTop
                          );
            apply/*<AA>*/(
                (dynamic x) => new A(),
                /*severe:STATIC_TYPE_ERROR*/(dynamic x) => (x as Object),
                (A x) => x,
                /*severe:STATIC_TYPE_ERROR*/(A x) => (x as Object), // known function
                /*warning:DOWN_CAST_COMPOSITE*/botA,
                /*warning:DOWN_CAST_COMPOSITE*/botTop
                          );
          }
          {
            TopTop f;
            f = topA;
            f = topTop;
            f = /*severe:STATIC_TYPE_ERROR*/aa;
            f = /*severe:STATIC_TYPE_ERROR*/aTop; // known function
            f = /*warning:DOWN_CAST_COMPOSITE should be severe:STATIC_TYPE_ERROR*/botA;
            f = /*warning:DOWN_CAST_COMPOSITE*/botTop;
            apply/*<TopTop>*/(
                topA,
                topTop,
                /*severe:STATIC_TYPE_ERROR*/aa,
                /*severe:STATIC_TYPE_ERROR*/aTop, // known function
                /*warning:DOWN_CAST_COMPOSITE should be severe:STATIC_TYPE_ERROR*/botA,
                /*warning:DOWN_CAST_COMPOSITE*/botTop
                              );
            apply/*<TopTop>*/(
                (dynamic x) => new A(),
                (dynamic x) => (x as Object),
                /*severe:STATIC_TYPE_ERROR*/(A x) => x,
                /*severe:STATIC_TYPE_ERROR*/(A x) => (x as Object), // known function
                /*warning:DOWN_CAST_COMPOSITE should be severe:STATIC_TYPE_ERROR*/botA,
                /*warning:DOWN_CAST_COMPOSITE*/botTop
                              );
          }
          {
            TopA f;
            f = topA;
            f = /*severe:STATIC_TYPE_ERROR*/topTop; // known function
            f = /*severe:STATIC_TYPE_ERROR*/aa; // known function
            f = /*severe:STATIC_TYPE_ERROR*/aTop; // known function
            f = /*warning:DOWN_CAST_COMPOSITE*/botA;
            f = /*warning:DOWN_CAST_COMPOSITE*/botTop;
            apply/*<TopA>*/(
                topA,
                /*severe:STATIC_TYPE_ERROR*/topTop, // known function
                /*severe:STATIC_TYPE_ERROR*/aa, // known function
                /*severe:STATIC_TYPE_ERROR*/aTop, // known function
                /*warning:DOWN_CAST_COMPOSITE*/botA,
                /*warning:DOWN_CAST_COMPOSITE*/botTop
                            );
            apply/*<TopA>*/(
                (dynamic x) => new A(),
                /*severe:STATIC_TYPE_ERROR*/(dynamic x) => (x as Object), // known function
                /*severe:STATIC_TYPE_ERROR*/(A x) => x, // known function
                /*severe:STATIC_TYPE_ERROR*/(A x) => (x as Object), // known function
                /*warning:DOWN_CAST_COMPOSITE*/botA,
                /*warning:DOWN_CAST_COMPOSITE*/botTop
                            );
          }
        }
     ''');
    });

    test('function literal variance', () {
      checkFile('''

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
          f = /*severe:STATIC_TYPE_ERROR*/top;
          f = left;
          f = /*severe:STATIC_TYPE_ERROR*/right;
          f = bot;
        }
        {
          Function2<A, A> f;
          f = /*severe:STATIC_TYPE_ERROR*/top;
          f = /*severe:STATIC_TYPE_ERROR*/left;
          f = right;
          f = bot;
        }
        {
          Function2<A, B> f;
          f = /*severe:STATIC_TYPE_ERROR*/top;
          f = /*severe:STATIC_TYPE_ERROR*/left;
          f = /*severe:STATIC_TYPE_ERROR*/right;
          f = bot;
        }
      }
   ''');
    });

    test('function variable variance', () {
      checkFile('''

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
   ''');
    });

    test('static method variance', () {
      checkFile('''

      class A {}
      class B extends A {}

      class C {
        static A top(B x) => x;
        static B left(B x) => x;
        static A right(A x) => x;
        static B bot(A x) => x as B;
      }

      typedef T Function2<S, T>(S z);

      void main() {
        {
          Function2<B, A> f;
          f = C.top;
          f = C.left;
          f = C.right;
          f = C.bot;
        }
        {
          Function2<B, B> f;
          f = /*severe:STATIC_TYPE_ERROR*/C.top;
          f = C.left;
          f = /*severe:STATIC_TYPE_ERROR*/C.right;
          f = C.bot;
        }
        {
          Function2<A, A> f;
          f = /*severe:STATIC_TYPE_ERROR*/C.top;
          f = /*severe:STATIC_TYPE_ERROR*/C.left;
          f = C.right;
          f = C.bot;
        }
        {
          Function2<A, B> f;
          f = /*severe:STATIC_TYPE_ERROR*/C.top;
          f = /*severe:STATIC_TYPE_ERROR*/C.left;
          f = /*severe:STATIC_TYPE_ERROR*/C.right;
          f = C.bot;
        }
      }
   ''');
    });

    test('instance method variance', () {
      checkFile('''

      class A {}
      class B extends A {}

      class C {
        A top(B x) => x;
        B left(B x) => x;
        A right(A x) => x;
        B bot(A x) => x as B;
      }

      typedef T Function2<S, T>(S z);

      void main() {
        C c = new C();
        {
          Function2<B, A> f;
          f = c.top;
          f = c.left;
          f = c.right;
          f = c.bot;
        }
        {
          Function2<B, B> f;
          f = /*warning:DOWN_CAST_COMPOSITE*/c.top;
          f = c.left;
          f = /*warning:DOWN_CAST_COMPOSITE*/c.right;
          f = c.bot;
        }
        {
          Function2<A, A> f;
          f = /*warning:DOWN_CAST_COMPOSITE*/c.top;
          f = /*warning:DOWN_CAST_COMPOSITE*/c.left;
          f = c.right;
          f = c.bot;
        }
        {
          Function2<A, B> f;
          f = /*warning:DOWN_CAST_COMPOSITE*/c.top;
          f = /*warning:DOWN_CAST_COMPOSITE*/c.left;
          f = /*warning:DOWN_CAST_COMPOSITE*/c.right;
          f = c.bot;
        }
      }
   ''');
    });

    test('higher order function literals 1', () {
      checkFile('''

      class A {}
      class B extends A {}

      typedef T Function2<S, T>(S z);

      typedef A BToA(B x);  // Top of the base lattice
      typedef B AToB(A x);  // Bot of the base lattice

      BToA top(AToB f) => f;
      AToB left(AToB f) => f;
      BToA right(BToA f) => f;
      AToB bot_(BToA f) => /*warning:DOWN_CAST_COMPOSITE*/f;
      AToB bot(BToA f) => f as AToB;

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
          f = /*severe:STATIC_TYPE_ERROR*/top;
          f = left;
          f = /*severe:STATIC_TYPE_ERROR*/right;
          f = bot;
        }
        {
          Function2<BToA, BToA> f; // Right
          f = /*severe:STATIC_TYPE_ERROR*/top;
          f = /*severe:STATIC_TYPE_ERROR*/left;
          f = right;
          f = bot;
        }
        {
          Function2<BToA, AToB> f; // Bot
          f = bot;
          f = /*severe:STATIC_TYPE_ERROR*/left;
          f = /*severe:STATIC_TYPE_ERROR*/top;
          f = /*severe:STATIC_TYPE_ERROR*/left;
        }
      }
   ''');
    });

    test('higher order function literals 2', () {
      checkFile('''

      class A {}
      class B extends A {}

      typedef T Function2<S, T>(S z);

      typedef A BToA(B x);  // Top of the base lattice
      typedef B AToB(A x);  // Bot of the base lattice

      Function2<B, A> top(AToB f) => f;
      Function2<A, B> left(AToB f) => f;
      Function2<B, A> right(BToA f) => f;
      Function2<A, B> bot_(BToA f) => /*warning:DOWN_CAST_COMPOSITE*/f;
      Function2<A, B> bot(BToA f) => f as Function2<A, B>;

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
          f = /*severe:STATIC_TYPE_ERROR*/top;
          f = left;
          f = /*severe:STATIC_TYPE_ERROR*/right;
          f = bot;
        }
        {
          Function2<BToA, BToA> f; // Right
          f = /*severe:STATIC_TYPE_ERROR*/top;
          f = /*severe:STATIC_TYPE_ERROR*/left;
          f = right;
          f = bot;
        }
        {
          Function2<BToA, AToB> f; // Bot
          f = bot;
          f = /*severe:STATIC_TYPE_ERROR*/left;
          f = /*severe:STATIC_TYPE_ERROR*/top;
          f = /*severe:STATIC_TYPE_ERROR*/left;
        }
      }
   ''');
    });

    test('higher order function literals 3', () {
      checkFile('''

      class A {}
      class B extends A {}

      typedef T Function2<S, T>(S z);

      typedef A BToA(B x);  // Top of the base lattice
      typedef B AToB(A x);  // Bot of the base lattice

      BToA top(Function2<A, B> f) => f;
      AToB left(Function2<A, B> f) => f;
      BToA right(Function2<B, A> f) => f;
      AToB bot_(Function2<B, A> f) => /*warning:DOWN_CAST_COMPOSITE*/f;
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
          f = /*severe:STATIC_TYPE_ERROR*/top;
          f = left;
          f = /*severe:STATIC_TYPE_ERROR*/right;
          f = bot;
        }
        {
          Function2<BToA, BToA> f; // Right
          f = /*severe:STATIC_TYPE_ERROR*/top;
          f = /*severe:STATIC_TYPE_ERROR*/left;
          f = right;
          f = bot;
        }
        {
          Function2<BToA, AToB> f; // Bot
          f = bot;
          f = /*severe:STATIC_TYPE_ERROR*/left;
          f = /*severe:STATIC_TYPE_ERROR*/top;
          f = /*severe:STATIC_TYPE_ERROR*/left;
        }
      }
   ''');
    });

    test('higher order function variables', () {
      checkFile('''

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
   ''');
    });

    test('named and optional parameters', () {
      checkFile('''

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
         r = /*warning:INVALID_ASSIGNMENT*/n;
         r = /*warning:INVALID_ASSIGNMENT*/rr;
         r = ro;
         r = rn;
         r = oo;
         r = /*warning:INVALID_ASSIGNMENT*/nn;
         r = /*warning:INVALID_ASSIGNMENT*/nnn;

         o = /*warning:DOWN_CAST_COMPOSITE*/r;
         o = o;
         o = /*warning:INVALID_ASSIGNMENT*/n;
         o = /*warning:INVALID_ASSIGNMENT*/rr;
         o = /*warning:INVALID_ASSIGNMENT*/ro;
         o = /*warning:INVALID_ASSIGNMENT*/rn;
         o = oo;
         o = /*warning:INVALID_ASSIGNMENT*/nn;
         o = /*warning:INVALID_ASSIGNMENT*/nnn;

         n = /*warning:INVALID_ASSIGNMENT*/r;
         n = /*warning:INVALID_ASSIGNMENT*/o;
         n = n;
         n = /*warning:INVALID_ASSIGNMENT*/rr;
         n = /*warning:INVALID_ASSIGNMENT*/ro;
         n = /*warning:INVALID_ASSIGNMENT*/rn;
         n = /*warning:INVALID_ASSIGNMENT*/oo;
         n = nn;
         n = nnn;

         rr = /*warning:INVALID_ASSIGNMENT*/r;
         rr = /*warning:INVALID_ASSIGNMENT*/o;
         rr = /*warning:INVALID_ASSIGNMENT*/n;
         rr = rr;
         rr = ro;
         rr = /*warning:INVALID_ASSIGNMENT*/rn;
         rr = oo;
         rr = /*warning:INVALID_ASSIGNMENT*/nn;
         rr = /*warning:INVALID_ASSIGNMENT*/nnn;

         ro = /*warning:DOWN_CAST_COMPOSITE*/r;
         ro = /*warning:INVALID_ASSIGNMENT*/o;
         ro = /*warning:INVALID_ASSIGNMENT*/n;
         ro = /*warning:DOWN_CAST_COMPOSITE*/rr;
         ro = ro;
         ro = /*warning:INVALID_ASSIGNMENT*/rn;
         ro = oo;
         ro = /*warning:INVALID_ASSIGNMENT*/nn;
         ro = /*warning:INVALID_ASSIGNMENT*/nnn;

         rn = /*warning:DOWN_CAST_COMPOSITE*/r;
         rn = /*warning:INVALID_ASSIGNMENT*/o;
         rn = /*warning:INVALID_ASSIGNMENT*/n;
         rn = /*warning:INVALID_ASSIGNMENT*/rr;
         rn = /*warning:INVALID_ASSIGNMENT*/ro;
         rn = rn;
         rn = /*warning:INVALID_ASSIGNMENT*/oo;
         rn = /*warning:INVALID_ASSIGNMENT*/nn;
         rn = /*warning:INVALID_ASSIGNMENT*/nnn;

         oo = /*warning:DOWN_CAST_COMPOSITE*/r;
         oo = /*warning:DOWN_CAST_COMPOSITE*/o;
         oo = /*warning:INVALID_ASSIGNMENT*/n;
         oo = /*warning:DOWN_CAST_COMPOSITE*/rr;
         oo = /*warning:DOWN_CAST_COMPOSITE*/ro;
         oo = /*warning:INVALID_ASSIGNMENT*/rn;
         oo = oo;
         oo = /*warning:INVALID_ASSIGNMENT*/nn;
         oo = /*warning:INVALID_ASSIGNMENT*/nnn;

         nn = /*warning:INVALID_ASSIGNMENT*/r;
         nn = /*warning:INVALID_ASSIGNMENT*/o;
         nn = /*warning:DOWN_CAST_COMPOSITE*/n;
         nn = /*warning:INVALID_ASSIGNMENT*/rr;
         nn = /*warning:INVALID_ASSIGNMENT*/ro;
         nn = /*warning:INVALID_ASSIGNMENT*/rn;
         nn = /*warning:INVALID_ASSIGNMENT*/oo;
         nn = nn;
         nn = nnn;

         nnn = /*warning:INVALID_ASSIGNMENT*/r;
         nnn = /*warning:INVALID_ASSIGNMENT*/o;
         nnn = /*warning:DOWN_CAST_COMPOSITE*/n;
         nnn = /*warning:INVALID_ASSIGNMENT*/rr;
         nnn = /*warning:INVALID_ASSIGNMENT*/ro;
         nnn = /*warning:INVALID_ASSIGNMENT*/rn;
         nnn = /*warning:INVALID_ASSIGNMENT*/oo;
         nnn = /*warning:DOWN_CAST_COMPOSITE*/nn;
         nnn = nnn;
      }
   ''');
    });

    test('Function subtyping: objects with call methods', () {
      checkFile('''

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
           f = /*warning:INVALID_ASSIGNMENT*/new B();
           f = i2i;
           f = /*severe:STATIC_TYPE_ERROR*/n2n;
           f = /*warning:DOWN_CAST_COMPOSITE*/i2i as Object;
           f = /*warning:DOWN_CAST_COMPOSITE*/n2n as Function;
         }
         {
           N2N f;
           f = /*warning:INVALID_ASSIGNMENT*/new A();
           f = new B();
           f = /*severe:STATIC_TYPE_ERROR*/i2i;
           f = n2n;
           f = /*warning:DOWN_CAST_COMPOSITE*/i2i as Object;
           f = /*warning:DOWN_CAST_COMPOSITE*/n2n as Function;
         }
         {
           A f;
           f = new A();
           f = /*warning:INVALID_ASSIGNMENT*/new B();
           f = /*warning:INVALID_ASSIGNMENT*/i2i;
           f = /*warning:INVALID_ASSIGNMENT*/n2n;
           f = /*info:DOWN_CAST_IMPLICIT*/i2i as Object;
           f = /*info:DOWN_CAST_IMPLICIT*/n2n as Function;
         }
         {
           B f;
           f = /*warning:INVALID_ASSIGNMENT*/new A();
           f = new B();
           f = /*warning:INVALID_ASSIGNMENT*/i2i;
           f = /*warning:INVALID_ASSIGNMENT*/n2n;
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
   ''');
    });

    test('void', () {
      checkFile('''

      class A {
        void bar() => null;
        void foo() => bar(); // allowed
      }
   ''');
    });

    test('uninferred closure', () {
      checkFile('''
        typedef num Num2Num(num x);
        void main() {
          Num2Num g = /*info:INFERRED_TYPE_CLOSURE,severe:STATIC_TYPE_ERROR*/(int x) { return x; };
          print(g(42));
        }
      ''');
    });

    test('subtype of universal type', () {
      checkFile('''
        void main() {
          nonGenericFn(x) => null;
          {
            /*=R*/ f/*<P, R>*/(/*=P*/ p) => null;
            /*=T*/ g/*<S, T>*/(/*=S*/ s) => null;

            var local = f;
            local = g; // valid

            // Non-generic function cannot subtype a generic one.
            local = /*warning:INVALID_ASSIGNMENT*/(x) => null;
            local = /*warning:INVALID_ASSIGNMENT*/nonGenericFn;
          }
          {
            Iterable/*<R>*/ f/*<P, R>*/(List/*<P>*/ p) => null;
            List/*<T>*/ g/*<S, T>*/(Iterable/*<S>*/ s) => null;

            var local = f;
            local = g; // valid

            var local2 = g;
            local = local2;
            local2 = /*severe:STATIC_TYPE_ERROR*/f;
            local2 = /*warning:DOWN_CAST_COMPOSITE*/local;

            // Non-generic function cannot subtype a generic one.
            local = /*warning:INVALID_ASSIGNMENT*/(x) => null;
            local = /*warning:INVALID_ASSIGNMENT*/nonGenericFn;
          }
        }
      ''');
    });
  });

  test('Relaxed casts', () {
    checkFile('''

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
          lOfDs = new L(); // Reset type propagation.
        }
        {
          lOfOs = mOfDs;
          lOfOs = mOfOs;
          lOfOs = mOfAs;
          lOfOs = lOfDs;
          lOfOs = lOfOs;
          lOfOs = lOfAs;
          lOfOs = new L<Object>(); // Reset type propagation.
        }
        {
          lOfAs = /*warning:DOWN_CAST_COMPOSITE*/mOfDs;
          lOfAs = /*warning:INVALID_ASSIGNMENT*/mOfOs;
          lOfAs = mOfAs;
          lOfAs = /*warning:DOWN_CAST_COMPOSITE*/lOfDs;
          lOfAs = /*info:DOWN_CAST_IMPLICIT*/lOfOs;
          lOfAs = lOfAs;
          lOfAs = new L<A>(); // Reset type propagation.
        }
        {
          mOfDs = mOfDs;
          mOfDs = mOfOs;
          mOfDs = mOfAs;
          mOfDs = /*info:DOWN_CAST_IMPLICIT*/lOfDs;
          mOfDs = /*info:DOWN_CAST_IMPLICIT*/lOfOs;
          mOfDs = /*warning:DOWN_CAST_COMPOSITE*/lOfAs;
          mOfDs = new M(); // Reset type propagation.
        }
        {
          mOfOs = mOfDs;
          mOfOs = mOfOs;
          mOfOs = mOfAs;
          mOfOs = /*info:DOWN_CAST_IMPLICIT*/lOfDs;
          mOfOs = /*info:DOWN_CAST_IMPLICIT*/lOfOs;
          mOfOs = /*warning:INVALID_ASSIGNMENT*/lOfAs;
          mOfOs = new M<Object>(); // Reset type propagation.
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
   ''');
  });

  test('Type checking literals', () {
    checkFile('''
          test() {
            num n = 3;
            int i = 3;
            String s = "hello";
            {
               List<int> l = <int>[i];
               l = <int>[/*warning:LIST_ELEMENT_TYPE_NOT_ASSIGNABLE*/s];
               l = <int>[/*info:DOWN_CAST_IMPLICIT*/n];
               l = <int>[i, /*info:DOWN_CAST_IMPLICIT*/n, /*warning:LIST_ELEMENT_TYPE_NOT_ASSIGNABLE*/s];
            }
            {
               List l = /*info:INFERRED_TYPE_LITERAL*/[i];
               l = /*info:INFERRED_TYPE_LITERAL*/[s];
               l = /*info:INFERRED_TYPE_LITERAL*/[n];
               l = /*info:INFERRED_TYPE_LITERAL*/[i, n, s];
            }
            {
               Map<String, int> m = <String, int>{s: i};
               m = <String, int>{s: /*warning:MAP_VALUE_TYPE_NOT_ASSIGNABLE*/s};
               m = <String, int>{s: /*info:DOWN_CAST_IMPLICIT*/n};
               m = <String, int>{s: i,
                                 s: /*info:DOWN_CAST_IMPLICIT*/n,
                                 s: /*warning:MAP_VALUE_TYPE_NOT_ASSIGNABLE*/s};
            }
           // TODO(leafp): We can't currently test for key errors since the
           // error marker binds to the entire entry.
            {
               Map m = /*info:INFERRED_TYPE_LITERAL*/{s: i};
               m = /*info:INFERRED_TYPE_LITERAL*/{s: s};
               m = /*info:INFERRED_TYPE_LITERAL*/{s: n};
               m = /*info:INFERRED_TYPE_LITERAL*/
                   {s: i,
                    s: n,
                    s: s};
               m = /*info:INFERRED_TYPE_LITERAL*/
                   {i: s,
                    n: s,
                    s: s};
            }
          }
   ''');
  });

  test('casts in constant contexts', () {
    checkFile('''
          class A {
            static const num n = 3.0;
            // The severe error is from constant evaluation where we know the
            // concrete type.
            static const int /*severe:VARIABLE_TYPE_MISMATCH*/i = /*info:ASSIGNMENT_CAST*/n;
            final int fi;
            const A(num a) : this.fi = /*info:DOWN_CAST_IMPLICIT*/a;
          }
          class B extends A {
            const B(Object a) : super(/*info:DOWN_CAST_IMPLICIT*/a);
          }
          void foo(Object o) {
            var a = const A(/*info:DOWN_CAST_IMPLICIT, severe:CONST_WITH_NON_CONSTANT_ARGUMENT, severe:INVALID_CONSTANT*/o);
          }
     ''');
  });

  test('casts in conditionals', () {
    checkFile('''
          main() {
            bool b = true;
            num x = b ? 1 : 2.3;
            int y = /*info:ASSIGNMENT_CAST*/b ? 1 : 2.3;
            String z = !b ? "hello" : null;
            z = b ? null : "hello";
          }
      ''');
  });

  // This is a regression test for https://github.com/dart-lang/sdk/issues/25071
  test('unbound redirecting constructor', () {
    checkFile('''
      class Foo {
        Foo() : /*severe:REDIRECT_GENERATIVE_TO_MISSING_CONSTRUCTOR*/this.init();
      }
       ''');
  });

  test('redirecting constructor', () {
    checkFile('''
          class A {
            A(A x) {}
            A.two() : this(/*warning:ARGUMENT_TYPE_NOT_ASSIGNABLE*/3);
          }
       ''');
  });

  test('super constructor', () {
    checkFile('''
          class A { A(A x) {} }
          class B extends A {
            B() : super(/*warning:ARGUMENT_TYPE_NOT_ASSIGNABLE*/3);
          }
       ''');
  });

  test('factory constructor downcast', () {
    checkFile(r'''
        class Animal {
          Animal();
          factory Animal.cat() => new Cat();
        }

        class Cat extends Animal {}

        void main() {
          Cat c = /*info:ASSIGNMENT_CAST*/new Animal.cat();
          c = /*severe:STATIC_TYPE_ERROR*/new Animal();
        }''');
  });

  test('field/field override', () {
    checkFile('''
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
       ''');
  });

  test('private override', () {
    addFile(
        '''
          import 'main.dart' as main;

          class Base {
            var f1;
            var _f2;
            var _f3;
            get _f4 => null;

            int _m1() => null;
          }

          class GrandChild extends main.Child {
            /*severe:INVALID_FIELD_OVERRIDE*/var _f2;
            /*severe:INVALID_FIELD_OVERRIDE*/var _f3;
            var _f4;

            /*severe:INVALID_METHOD_OVERRIDE*/String
                /*warning:INVALID_METHOD_OVERRIDE_RETURN_TYPE*/_m1() => null;
          }
    ''',
        name: '/helper.dart');
    checkFile('''
          import 'helper.dart' as helper;

          class Child extends helper.Base {
            /*severe:INVALID_FIELD_OVERRIDE*/var f1;
            var _f2;
            var _f4;

            String _m1() => null;
          }
    ''');
  });

  test('getter/getter override', () {
    checkFile('''
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
       ''');
  });

  test('field/getter override', () {
    checkFile('''
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

          class /*warning:NON_ABSTRACT_CLASS_INHERITS_ABSTRACT_MEMBER_FOUR*/Child2 implements Base {
            /*severe:INVALID_METHOD_OVERRIDE*/A get f1 => null;
            C get f2 => null;
            get f3 => null;
            /*severe:INVALID_METHOD_OVERRIDE*/dynamic get f4 => null;
          }
       ''');
  });

  test('setter/setter override', () {
    checkFile('''
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
       ''');
  });

  test('field/setter override', () {
    checkFile('''
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
       ''');
  });

  test('method override', () {
    checkFile('''
          class A {}
          class B extends A {}
          class C extends B {}

          class Base {
            B m1(B a) => null;
            B m2(B a) => null;
            B m3(B a) => null;
            B m4(B a) => null;
            B m5(B a) => null;
            B m6(B a) => null;
          }

          class Child extends Base {
            /*severe:INVALID_METHOD_OVERRIDE*/A m1(A value) => null;
            /*severe:INVALID_METHOD_OVERRIDE*/C m2(C value) => null;
            /*severe:INVALID_METHOD_OVERRIDE*/A m3(C value) => null;
            C m4(A value) => null;
            m5(value) => null;
            /*severe:INVALID_METHOD_OVERRIDE*/dynamic m6(dynamic value) => null;
          }
       ''');
  });

  test('method override, fuzzy arrows', () {
    checkFile('''
      abstract class A {
        bool operator ==(Object object);
      }

      class B implements A {}


      class F {
        void f(x) {}
        void g(int x) {}
      }

      class G extends F {
        /*severe:INVALID_METHOD_OVERRIDE*/void f(int x) {}
        void g(dynamic x) {}
      }

      class H implements F {
        /*severe:INVALID_METHOD_OVERRIDE*/void f(int x) {}
        void g(dynamic x) {}
      }

      ''');
  });

  test('getter override, fuzzy arrows', () {
    checkFile('''
      typedef void ToVoid<T>(T x);
      class F {
        ToVoid<dynamic> get f => null;
        ToVoid<int> get g => null;
      }

      class G extends F {
        ToVoid<int> get f => null;
        /*severe:INVALID_METHOD_OVERRIDE*/ToVoid<dynamic> get g => null;
      }

      class H implements F {
        ToVoid<int> get f => null;
        /*severe:INVALID_METHOD_OVERRIDE*/ToVoid<dynamic> get g => null;
      }
       ''');
  });

  test('setter override, fuzzy arrows', () {
    checkFile('''
      typedef void ToVoid<T>(T x);
      class F {
        void set f(ToVoid<dynamic> x) {}
        void set g(ToVoid<int> x) {} 
        void set h(dynamic x) {}
        void set i(int x) {}
     }

      class G extends F {
        /*severe:INVALID_METHOD_OVERRIDE*/void set f(ToVoid<int> x) {}
        void set g(ToVoid<dynamic> x) {}
        void set h(int x) {}
        /*severe:INVALID_METHOD_OVERRIDE*/void set i(dynamic x) {}
      }

      class H implements F {
        /*severe:INVALID_METHOD_OVERRIDE*/void set f(ToVoid<int> x) {}
        void set g(ToVoid<dynamic> x) {}
        void set h(int x) {}
        /*severe:INVALID_METHOD_OVERRIDE*/void set i(dynamic x) {}
      }
       ''');
  });

  test('field override, fuzzy arrows', () {
    checkFile('''
      typedef void ToVoid<T>(T x);
      class F {
        final ToVoid<dynamic> f = null;
        final ToVoid<int> g = null;
      }

      class G extends F {
        /*severe:INVALID_FIELD_OVERRIDE*/final ToVoid<int> f = null;
        /*severe:INVALID_FIELD_OVERRIDE, severe:INVALID_METHOD_OVERRIDE*/final ToVoid<dynamic> g = null;
      }

      class H implements F {
        final ToVoid<int> f = null;
        /*severe:INVALID_METHOD_OVERRIDE*/final ToVoid<dynamic> g = null;
      }
       ''');
  });

  test('generic class method override', () {
    checkFile('''
          class A {}
          class B extends A {}

          class Base<T extends B> {
            T foo() => null;
          }

          class Derived<S extends A> extends Base<B> {
            /*severe:INVALID_METHOD_OVERRIDE*/S
                /*warning:INVALID_METHOD_OVERRIDE_RETURN_TYPE*/foo() => null;
          }

          class Derived2<S extends B> extends Base<B> {
            S foo() => null;
          }
       ''');
  });

  test('generic method override', () {
    checkFile('''
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
      ''');
  });

  test('generic function wrong number of arguments', () {
    checkFile(r'''
          /*=T*/ foo/*<T>*/(/*=T*/ x, /*=T*/ y) => x;
          /*=T*/ bar/*<T>*/({/*=T*/ x, /*=T*/ y}) => x;

          main() {
            String x;
            // resolving these shouldn't crash.
            foo/*warning:EXTRA_POSITIONAL_ARGUMENTS*/(1, 2, 3);
            x = foo/*warning:EXTRA_POSITIONAL_ARGUMENTS*/('1', '2', '3');
            foo/*warning:NOT_ENOUGH_REQUIRED_ARGUMENTS*/(1);
            x = foo/*warning:NOT_ENOUGH_REQUIRED_ARGUMENTS*/('1');
            x = /*info:DYNAMIC_CAST*/foo/*warning:EXTRA_POSITIONAL_ARGUMENTS*/(1, 2, 3);
            x = /*info:DYNAMIC_CAST*/foo/*warning:NOT_ENOUGH_REQUIRED_ARGUMENTS*/(1);

            // named arguments
            bar(y: 1, x: 2, /*warning:UNDEFINED_NAMED_PARAMETER*/z: 3);
            x = bar(/*warning:UNDEFINED_NAMED_PARAMETER*/z: '1', x: '2', y: '3');
            bar(y: 1);
            x = bar(x: '1', /*warning:UNDEFINED_NAMED_PARAMETER*/z: 42);
            x = /*info:DYNAMIC_CAST*/bar(y: 1, x: 2, /*warning:UNDEFINED_NAMED_PARAMETER*/z: 3);
            x = /*info:DYNAMIC_CAST*/bar(x: 1);
          }
      ''');
  });

  test('type promotion from dynamic', () {
    checkFile(r'''
          f() {
            dynamic x;
            if (x is int) {
              int y = x;
              String z = /*warning:INVALID_ASSIGNMENT*/x;
            }
          }
          g() {
            Object x;
            if (x is int) {
              int y = x;
              String z = /*warning:INVALID_ASSIGNMENT*/x;
            }
          }
    ''');
  });

  test('unary operators', () {
    checkFile('''
      class A {
        A operator ~() => null;
        A operator +(int x) => null;
        A operator -(int x) => null;
        A operator -() => null;
      }

      foo() => new A();

      test() {
        A a = new A();
        var c = foo();
        dynamic d;

        ~a;
        (/*info:DYNAMIC_INVOKE*/~d);

        !/*warning:NON_BOOL_NEGATION_EXPRESSION*/a;
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
      }''');
  });

  test('binary and index operators', () {
    checkFile('''
          class A {
            A operator *(B b) => null;
            A operator /(B b) => null;
            A operator ~/(B b) => null;
            A operator %(B b) => null;
            A operator +(B b) => null;
            A operator -(B b) => null;
            A operator <<(B b) => null;
            A operator >>(B b) => null;
            A operator &(B b) => null;
            A operator ^(B b) => null;
            A operator |(B b) => null;
            A operator[](B b) => null;
          }

          class B {
            A operator -(B b) => null;
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
            a = a + /*warning:ARGUMENT_TYPE_NOT_ASSIGNABLE*/a;
            a = a - b;
            b = /*warning:INVALID_ASSIGNMENT*/b - b;
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
            x = x + /*warning:ARGUMENT_TYPE_NOT_ASSIGNABLE*/y;

            bool p = true;
            p = p && p;
            p = p && /*info:DYNAMIC_CAST*/c;
            p = (/*info:DYNAMIC_CAST*/c) && p;
            p = (/*info:DYNAMIC_CAST*/c) && /*info:DYNAMIC_CAST*/c;
            p = /*warning:NON_BOOL_OPERAND*/y && p;
            p = c == y;

            a = a[b];
            a = a[/*info:DYNAMIC_CAST*/c];
            c = (/*info:DYNAMIC_INVOKE*/c[b]);
            a[/*warning:ARGUMENT_TYPE_NOT_ASSIGNABLE*/y];
          }
       ''');
  });

  test('null coalescing operator', () {
    checkFile('''
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
       ''');
  });

  test('compound assignments', () {
    checkFile('''
          class A {
            A operator *(B b) => null;
            A operator /(B b) => null;
            A operator ~/(B b) => null;
            A operator %(B b) => null;
            A operator +(B b) => null;
            A operator -(B b) => null;
            A operator <<(B b) => null;
            A operator >>(B b) => null;
            A operator &(B b) => null;
            A operator ^(B b) => null;
            A operator |(B b) => null;
            D operator [](B index) => null;
            void operator []=(B index, D value) => null;
          }

          class B {
            A operator -(B b) => null;
          }

          class D {
            D operator +(D d) => null;
          }

          foo() => new A();

          test() {
            int x = 0;
            x += 5;
            /*severe:STATIC_TYPE_ERROR*/x += 3.14;

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
            a += /*warning:ARGUMENT_TYPE_NOT_ASSIGNABLE*/a;
            a -= b;
            /*severe:STATIC_TYPE_ERROR*/b -= /*warning:INVALID_ASSIGNMENT*/b;
            a <<= b;
            a >>= b;
            a &= b;
            a ^= b;
            a |= b;
            /*info:DYNAMIC_INVOKE*/c += b;

            var d = new D();
            a[b] += d;
            a[/*info:DYNAMIC_CAST*/c] += d;
            a[/*warning:ARGUMENT_TYPE_NOT_ASSIGNABLE*/z] += d;
            a[b] += /*info:DYNAMIC_CAST*/c;
            a[b] += /*warning:ARGUMENT_TYPE_NOT_ASSIGNABLE*/z;
            /*info:DYNAMIC_INVOKE,info:DYNAMIC_INVOKE*/c[b] += d;
          }
       ''');
  });

  test('super call placement', () {
    checkFile('''
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
       ''');
  });

  test('for loop variable', () {
    checkFile('''
          foo() {
            for (int i = 0; i < 10; i++) {
              i = /*warning:INVALID_ASSIGNMENT*/"hi";
            }
          }
          bar() {
            for (var i = 0; i < 10; i++) {
              int j = i + 1;
            }
          }
        ''');
  });

  test('loadLibrary', () {
    addFile('''library lib1;''', name: '/lib1.dart');
    checkFile(r'''
        import 'lib1.dart' deferred as lib1;
        import 'dart:async' show Future;
        main() {
          Future f = lib1.loadLibrary();
        }''');
  });

  group('invalid overrides', () {
    test('child override', () {
      checkFile('''
            class A {}
            class B {}

            class Base {
                A f;
            }

            class T1 extends Base {
              /*warning:MISMATCHED_GETTER_AND_SETTER_TYPES_FROM_SUPERTYPE, severe:INVALID_FIELD_OVERRIDE, severe:INVALID_METHOD_OVERRIDE*/B get
                  /*warning:INVALID_GETTER_OVERRIDE_RETURN_TYPE*/f => null;
            }

            class T2 extends Base {
              /*warning:MISMATCHED_GETTER_AND_SETTER_TYPES_FROM_SUPERTYPE, severe:INVALID_FIELD_OVERRIDE, severe:INVALID_METHOD_OVERRIDE*/set f(
                  /*warning:INVALID_SETTER_OVERRIDE_NORMAL_PARAM_TYPE*/B b) => null;
            }

            class T3 extends Base {
              /*severe:INVALID_FIELD_OVERRIDE, severe:INVALID_METHOD_OVERRIDE*/final B
                  /*warning:FINAL_NOT_INITIALIZED, warning:INVALID_GETTER_OVERRIDE_RETURN_TYPE*/f;
            }
            class T4 extends Base {
              // two: one for the getter one for the setter.
              /*severe:INVALID_FIELD_OVERRIDE, severe:INVALID_METHOD_OVERRIDE, severe:INVALID_METHOD_OVERRIDE*/B
                  /*warning:INVALID_GETTER_OVERRIDE_RETURN_TYPE, warning:INVALID_SETTER_OVERRIDE_NORMAL_PARAM_TYPE*/f;
            }

            class /*warning:NON_ABSTRACT_CLASS_INHERITS_ABSTRACT_MEMBER_ONE*/T5 implements Base {
              /*warning:MISMATCHED_GETTER_AND_SETTER_TYPES_FROM_SUPERTYPE, severe:INVALID_METHOD_OVERRIDE*/B get
                  /*warning:INVALID_GETTER_OVERRIDE_RETURN_TYPE*/f => null;
            }

            class /*warning:NON_ABSTRACT_CLASS_INHERITS_ABSTRACT_MEMBER_ONE*/T6 implements Base {
              /*warning:MISMATCHED_GETTER_AND_SETTER_TYPES_FROM_SUPERTYPE, severe:INVALID_METHOD_OVERRIDE*/set f(
                  /*warning:INVALID_SETTER_OVERRIDE_NORMAL_PARAM_TYPE*/B b) => null;
            }

            class /*warning:NON_ABSTRACT_CLASS_INHERITS_ABSTRACT_MEMBER_ONE*/T7 implements Base {
              /*severe:INVALID_METHOD_OVERRIDE*/final B
                  /*warning:INVALID_GETTER_OVERRIDE_RETURN_TYPE*/f = null;
            }
            class T8 implements Base {
              // two: one for the getter one for the setter.
              /*severe:INVALID_METHOD_OVERRIDE, severe:INVALID_METHOD_OVERRIDE*/B
                  /*warning:INVALID_GETTER_OVERRIDE_RETURN_TYPE, warning:INVALID_SETTER_OVERRIDE_NORMAL_PARAM_TYPE*/f;
            }
         ''');
    });

    test('child override 2', () {
      checkFile('''
            class A {}
            class B {}

            class Base {
                m(A a) {}
            }

            class Test extends Base {
              /*severe:INVALID_METHOD_OVERRIDE*/m(
                    /*warning:INVALID_METHOD_OVERRIDE_NORMAL_PARAM_TYPE*/B a) {}
            }
         ''');
    });
    test('grandchild override', () {
      checkFile('''
            class A {}
            class B {}

            class Grandparent {
                m(A a) {}
                int x;
            }
            class Parent extends Grandparent {
            }

            class Test extends Parent {
                /*severe:INVALID_METHOD_OVERRIDE*/m(
                      /*warning:INVALID_METHOD_OVERRIDE_NORMAL_PARAM_TYPE*/B a) {}
                /*severe:INVALID_FIELD_OVERRIDE*/int x;
            }
         ''');
    });

    test('double override', () {
      checkFile('''
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
                /*severe:INVALID_METHOD_OVERRIDE*/m(
                    /*warning:INVALID_METHOD_OVERRIDE_NORMAL_PARAM_TYPE*/B a) {}
            }
         ''');
    });

    test('double override 2', () {
      checkFile('''
            class A {}
            class B {}

            class Grandparent {
                m(A a) {}
            }
            class Parent extends Grandparent {
              /*severe:INVALID_METHOD_OVERRIDE*/m(
                  /*warning:INVALID_METHOD_OVERRIDE_NORMAL_PARAM_TYPE*/B a) {}
            }

            class Test extends Parent {
                m(B a) {}
            }
         ''');
    });

    test('mixin override to base', () {
      checkFile('''
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

            class /*warning:INCONSISTENT_METHOD_INHERITANCE*/T1 extends Base
                with /*severe:INVALID_METHOD_OVERRIDE*/M1 {}
            class /*warning:INCONSISTENT_METHOD_INHERITANCE*/T2 extends Base
                with /*severe:INVALID_METHOD_OVERRIDE*/M1, /*severe:INVALID_FIELD_OVERRIDE*/M2 {}
            class /*warning:INCONSISTENT_METHOD_INHERITANCE*/T3 extends Base
                with /*severe:INVALID_FIELD_OVERRIDE*/M2, /*severe:INVALID_METHOD_OVERRIDE*/M1 {}
         ''');
    });

    test('mixin override to mixin', () {
      checkFile('''
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

            class /*warning:INCONSISTENT_METHOD_INHERITANCE*/T1 extends Base
                with M1,
                /*severe:INVALID_METHOD_OVERRIDE,severe:INVALID_FIELD_OVERRIDE*/M2 {}
         ''');
    });

    // This is a regression test for a bug in an earlier implementation were
    // names were hiding errors if the first mixin override looked correct,
    // but subsequent ones did not.
    test('no duplicate mixin override', () {
      checkFile('''
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

            class /*warning:INCONSISTENT_METHOD_INHERITANCE*/T1 extends Base
                with M1, /*severe:INVALID_METHOD_OVERRIDE*/M2, M3 {}
         ''');
    });

    test('class override of interface', () {
      checkFile('''
            class A {}
            class B {}

            abstract class I {
                m(A a);
            }

            class T1 implements I {
              /*severe:INVALID_METHOD_OVERRIDE*/m(
                  /*warning:INVALID_METHOD_OVERRIDE_NORMAL_PARAM_TYPE*/B a) {}
            }
         ''');
    });

    test('base class override to child interface', () {
      checkFile('''
            class A {}
            class B {}

            abstract class I {
                m(A a);
            }

            class Base {
                m(B a) {}
            }

            class /*warning:INCONSISTENT_METHOD_INHERITANCE*/T1
                /*severe:INVALID_METHOD_OVERRIDE*/extends Base implements I {}
         ''');
    });

    test('mixin override of interface', () {
      checkFile('''
            class A {}
            class B {}

            abstract class I {
                m(A a);
            }

            class M {
                m(B a) {}
            }

            class /*warning:INCONSISTENT_METHOD_INHERITANCE*/T1
                extends Object with /*severe:INVALID_METHOD_OVERRIDE*/M
                implements I {}
         ''');
    });

    // This is a case were it is incorrect to say that the base class
    // incorrectly overrides the interface.
    test('no errors if subclass correctly overrides base and interface', () {
      checkFile('''
            class A {}
            class B {}

            class Base {
                m(A a) {}
            }

            class I1 {
                m(B a) {}
            }

            class /*warning:INCONSISTENT_METHOD_INHERITANCE*/T1
                /*severe:INVALID_METHOD_OVERRIDE*/extends Base
                implements I1 {}

            class T2 extends Base implements I1 {
                m(a) {}
            }

            class /*warning:INCONSISTENT_METHOD_INHERITANCE*/T3
                extends Object with /*severe:INVALID_METHOD_OVERRIDE*/Base
                implements I1 {}

            class T4 extends Object with Base implements I1 {
                m(a) {}
            }
         ''');
    });
  });

  group('class override of grand interface', () {
    test('interface of interface of child', () {
      checkFile('''
              class A {}
              class B {}

              abstract class I1 {
                  m(A a);
              }
              abstract class I2 implements I1 {}

              class T1 implements I2 {
                /*severe:INVALID_METHOD_OVERRIDE*/m(
                    /*warning:INVALID_METHOD_OVERRIDE_NORMAL_PARAM_TYPE*/B a) {}
              }
           ''');
    });
    test('superclass of interface of child', () {
      checkFile('''
              class A {}
              class B {}

              abstract class I1 {
                  m(A a);
              }
              abstract class I2 extends I1 {}

              class T1 implements I2 {
                /*severe:INVALID_METHOD_OVERRIDE*/m(
                    /*warning:INVALID_METHOD_OVERRIDE_NORMAL_PARAM_TYPE*/B a) {}
              }
           ''');
    });
    test('mixin of interface of child', () {
      checkFile('''
              class A {}
              class B {}

              abstract class M1 {
                  m(A a);
              }
              abstract class I2 extends Object with M1 {}

              class T1 implements I2 {
                /*severe:INVALID_METHOD_OVERRIDE*/m(
                    /*warning:INVALID_METHOD_OVERRIDE_NORMAL_PARAM_TYPE*/B a) {}
              }
           ''');
    });
    test('interface of abstract superclass', () {
      checkFile('''
              class A {}
              class B {}

              abstract class I1 {
                  m(A a);
              }
              abstract class Base implements I1 {}

              class T1 extends Base {
                /*severe:INVALID_METHOD_OVERRIDE*/m(
                    /*warning:INVALID_METHOD_OVERRIDE_NORMAL_PARAM_TYPE*/B a) {}
              }
           ''');
    });
    test('interface of concrete superclass', () {
      checkFile('''
              class A {}
              class B {}

              abstract class I1 {
                  m(A a);
              }

              class /*warning:NON_ABSTRACT_CLASS_INHERITS_ABSTRACT_MEMBER_ONE*/Base
                  implements I1 {}

              class T1 extends Base {
                  // not reported technically because if the class is concrete,
                  // it should implement all its interfaces and hence it is
                  // sufficient to check overrides against it.
                  m(/*warning:INVALID_METHOD_OVERRIDE_NORMAL_PARAM_TYPE*/B a) {}
              }
           ''');
    });
  });

  group('mixin override of grand interface', () {
    test('interface of interface of child', () {
      checkFile('''
              class A {}
              class B {}

              abstract class I1 {
                  m(A a);
              }
              abstract class I2 implements I1 {}

              class M {
                  m(B a) {}
              }

              class /*warning:INCONSISTENT_METHOD_INHERITANCE*/T1
                  extends Object with /*severe:INVALID_METHOD_OVERRIDE*/M
                  implements I2 {}
           ''');
    });
    test('superclass of interface of child', () {
      checkFile('''
              class A {}
              class B {}

              abstract class I1 {
                  m(A a);
              }
              abstract class I2 extends I1 {}

              class M {
                  m(B a) {}
              }

              class /*warning:INCONSISTENT_METHOD_INHERITANCE*/T1
                  extends Object with /*severe:INVALID_METHOD_OVERRIDE*/M
                  implements I2 {}
           ''');
    });
    test('mixin of interface of child', () {
      checkFile('''
              class A {}
              class B {}

              abstract class M1 {
                  m(A a);
              }
              abstract class I2 extends Object with M1 {}

              class M {
                  m(B a) {}
              }

              class /*warning:INCONSISTENT_METHOD_INHERITANCE*/T1
                  extends Object with /*severe:INVALID_METHOD_OVERRIDE*/M
                  implements I2 {}
           ''');
    });
    test('interface of abstract superclass', () {
      checkFile('''
              class A {}
              class B {}

              abstract class I1 {
                  m(A a);
              }
              abstract class Base implements I1 {}

              class M {
                  m(B a) {}
              }

              class /*warning:INCONSISTENT_METHOD_INHERITANCE*/T1 extends Base
                  with /*severe:INVALID_METHOD_OVERRIDE*/M {}
           ''');
    });
    test('interface of concrete superclass', () {
      checkFile('''
              class A {}
              class B {}

              abstract class I1 {
                  m(A a);
              }

              class /*warning:NON_ABSTRACT_CLASS_INHERITS_ABSTRACT_MEMBER_ONE*/Base
                  implements I1 {}

              class M {
                  m(B a) {}
              }

              class /*warning:INCONSISTENT_METHOD_INHERITANCE*/T1 extends Base
                  with M {}
           ''');
    });
  });

  group('superclass override of grand interface', () {
    test('interface of interface of child', () {
      checkFile('''
              class A {}
              class B {}

              abstract class I1 {
                  m(A a);
              }
              abstract class I2 implements I1 {}

              class Base {
                  m(B a) {}
              }

              class /*warning:INCONSISTENT_METHOD_INHERITANCE*/T1
                  /*severe:INVALID_METHOD_OVERRIDE*/extends Base implements I2 {}
           ''');
    });
    test('superclass of interface of child', () {
      checkFile('''
              class A {}
              class B {}

              abstract class I1 {
                  m(A a);
              }
              abstract class I2 extends I1 {}

              class Base {
                  m(B a) {}
              }

              class /*warning:INCONSISTENT_METHOD_INHERITANCE*/T1
                  /*severe:INVALID_METHOD_OVERRIDE*/extends Base
                  implements I2 {}
           ''');
    });
    test('mixin of interface of child', () {
      checkFile('''
              class A {}
              class B {}

              abstract class M1 {
                  m(A a);
              }
              abstract class I2 extends Object with M1 {}

              class Base {
                  m(B a) {}
              }

              class /*warning:INCONSISTENT_METHOD_INHERITANCE*/T1
                  /*severe:INVALID_METHOD_OVERRIDE*/extends Base
                  implements I2 {}
           ''');
    });
    test('interface of abstract superclass', () {
      checkFile('''
              class A {}
              class B {}

              abstract class I1 {
                  m(A a);
              }

              abstract class Base implements I1 {
                /*severe:INVALID_METHOD_OVERRIDE*/m(
                    /*warning:INVALID_METHOD_OVERRIDE_NORMAL_PARAM_TYPE*/B a) {}
              }

              class T1 extends Base {
                  // we consider the base class incomplete because it is
                  // abstract, so we report the error here too.
                  // TODO(sigmund): consider tracking overrides in a fine-grain
                  // manner, then this and the double-overrides would not be
                  // reported.
                  /*severe:INVALID_METHOD_OVERRIDE*/m(B a) {}
              }
           ''');
    });
    test('interface of concrete superclass', () {
      checkFile('''
              class A {}
              class B {}

              abstract class I1 {
                  m(A a);
              }

              class Base implements I1 {
                /*severe:INVALID_METHOD_OVERRIDE*/m(
                    /*warning:INVALID_METHOD_OVERRIDE_NORMAL_PARAM_TYPE*/B a) {}
              }

              class T1 extends Base {
                  m(B a) {}
              }
           ''');
    });
  });

  group('no duplicate reports from overriding interfaces', () {
    test('type overrides same method in multiple interfaces', () {
      checkFile('''
              class A {}
              class B {}

              abstract class I1 {
                  m(A a);
              }
              abstract class I2 implements I1 {
                  m(A a);
              }

              class Base {}

              class T1 implements I2 {
                /*severe:INVALID_METHOD_OVERRIDE*/m(
                    /*warning:INVALID_METHOD_OVERRIDE_NORMAL_PARAM_TYPE*/B a) {}
              }
           ''');
    });

    test('type and base type override same method in interface', () {
      checkFile('''
              class A {}
              class B {}

              abstract class I1 {
                  m(A a);
              }

              class Base {
                  m(B a) {}
              }

              // Note: no error reported in `extends Base` to avoid duplicating
              // the error in T1.
              class T1 extends Base implements I1 {
                /*severe:INVALID_METHOD_OVERRIDE*/m(
                    /*warning:INVALID_METHOD_OVERRIDE_NORMAL_PARAM_TYPE*/B a) {}
              }

              // If there is no error in the class, we do report the error at
              // the base class:
              class /*warning:INCONSISTENT_METHOD_INHERITANCE*/T2
                  /*severe:INVALID_METHOD_OVERRIDE*/extends Base
                  implements I1 {}
           ''');
    });

    test('type and mixin override same method in interface', () {
      checkFile('''
              class A {}
              class B {}

              abstract class I1 {
                  m(A a);
              }

              class M {
                  m(B a) {}
              }

              class T1 extends Object with M implements I1 {
                /*severe:INVALID_METHOD_OVERRIDE*/m(
                    /*warning:INVALID_METHOD_OVERRIDE_NORMAL_PARAM_TYPE*/B a) {}
              }

              class /*warning:INCONSISTENT_METHOD_INHERITANCE*/T2
                  extends Object with /*severe:INVALID_METHOD_OVERRIDE*/M
                  implements I1 {}
           ''');
    });

    test('two grand types override same method in interface', () {
      checkFile('''
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
              class Parent2 extends Grandparent {}

              // Note: otherwise both errors would be reported on this line
              class /*warning:INCONSISTENT_METHOD_INHERITANCE*/T1
                  /*severe:INVALID_METHOD_OVERRIDE*/extends Parent1
                  implements I1 {}
              class /*warning:INCONSISTENT_METHOD_INHERITANCE*/T2
                  /*severe:INVALID_METHOD_OVERRIDE*/extends Parent2
                  implements I1 {}
           ''');
    });

    test('two mixins override same method in interface', () {
      checkFile('''
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
              class /*warning:INCONSISTENT_METHOD_INHERITANCE*/T1 extends Object
                  with /*severe:INVALID_METHOD_OVERRIDE*/M1,
                  /*severe:INVALID_METHOD_OVERRIDE*/M2
                  implements I1 {}
           ''');
    });

    test('base type and mixin override same method in interface', () {
      checkFile('''
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
              class /*warning:INCONSISTENT_METHOD_INHERITANCE*/T1
                  /*severe:INVALID_METHOD_OVERRIDE*/extends Base
                  with /*severe:INVALID_METHOD_OVERRIDE*/M
                  implements I1 {}
           ''');
    });
  });

  test('invalid runtime checks', () {
    checkFile('''
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
      ''');
  });

  group('function modifiers', () {
    test('async', () {
      checkFile('''
        import 'dart:async';
        import 'dart:math' show Random;

        dynamic x;

        foo1() async => x;
        Future foo2() async => x;
        Future<int> foo3() async => /*info:DYNAMIC_CAST*/x;
        Future<int> foo4() async => new Future<int>.value(/*info:DYNAMIC_CAST*/x);
        Future<int> foo5() async =>
            /*warning:RETURN_OF_INVALID_TYPE*/new Future<String>.value(/*info:DYNAMIC_CAST*/x);

        bar1() async { return x; }
        Future bar2() async { return x; }
        Future<int> bar3() async { return /*info:DYNAMIC_CAST*/x; }
        Future<int> bar4() async { return new Future<int>.value(/*info:DYNAMIC_CAST*/x); }
        Future<int> bar5() async {
          return /*warning:RETURN_OF_INVALID_TYPE*/new Future<String>.value(/*info:DYNAMIC_CAST*/x);
        }

        int y;
        Future<int> z;

        baz() async {
          int a = /*info:DYNAMIC_CAST*/await x;
          int b = await y;
          int c = await z;
          String d = /*warning:INVALID_ASSIGNMENT*/await z;
        }

        Future<bool> get issue_264 async {
          await 42;
          if (new Random().nextBool()) {
            return true;
          } else {
            return new Future<bool>.value(false);
          }
        }
    ''');
    });

    test('async*', () {
      checkFile('''
        import 'dart:async';

        dynamic x;

        bar1() async* { yield x; }
        Stream bar2() async* { yield x; }
        Stream<int> bar3() async* { yield /*info:DYNAMIC_CAST*/x; }
        Stream<int> bar4() async* { yield /*warning:YIELD_OF_INVALID_TYPE*/new Stream<int>(); }

        baz1() async* { yield* /*info:DYNAMIC_CAST*/x; }
        Stream baz2() async* { yield* /*info:DYNAMIC_CAST*/x; }
        Stream<int> baz3() async* { yield* /*warning:DOWN_CAST_COMPOSITE*/x; }
        Stream<int> baz4() async* { yield* new Stream<int>(); }
        Stream<int> baz5() async* { yield* /*info:INFERRED_TYPE_ALLOCATION*/new Stream(); }
    ''');
    });

    test('sync*', () {
      checkFile('''
        dynamic x;

        bar1() sync* { yield x; }
        Iterable bar2() sync* { yield x; }
        Iterable<int> bar3() sync* { yield /*info:DYNAMIC_CAST*/x; }
        Iterable<int> bar4() sync* { yield /*warning:YIELD_OF_INVALID_TYPE*/bar3(); }

        baz1() sync* { yield* /*info:DYNAMIC_CAST*/x; }
        Iterable baz2() sync* { yield* /*info:DYNAMIC_CAST*/x; }
        Iterable<int> baz3() sync* { yield* /*warning:DOWN_CAST_COMPOSITE*/x; }
        Iterable<int> baz4() sync* { yield* bar3(); }
        Iterable<int> baz5() sync* { yield* /*info:INFERRED_TYPE_ALLOCATION*/new List(); }
    ''');
    });
  });
}
