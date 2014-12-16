/// General type checking tests
library ddc.test.checker_test;

import 'package:unittest/compact_vm_config.dart';
import 'package:unittest/unittest.dart';

import 'package:ddc/src/testing.dart';

main() {
  useCompactVMConfiguration();

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
      class C extends A {}

      void main() {
         dynamic y;
         Object o;
         int i;
         double d;
         num n;
         A a;
         B b;
         C c;
         y = o;
         y = /*config:Box*/i;
         y = /*config:Box*/d;
         y = n;
         y = a;
         y = b;
         y = c;
      }
   '''
    });
  });

  test('Ground type subtyping: dynamic downcasts', () {
    testChecker({
      '/main.dart': '''

      class A {}
      class B extends A {}
      class C extends A {}

      void main() {
         dynamic y;
         Object o;
         int i;
         double d;
         num n;
         A a;
         B b;
         C c;
         o = y;
         i = /*info:Unbox*/y;
         d = /*info:Unbox*/y;
         n = /*info:DownCast*/y;
         a = /*info:DownCast*/y;
         b = /*info:DownCast*/y;
         c = /*info:DownCast*/y;
      }
   '''
    });
  });

  test('Ground type subtyping: assigning a class', () {
    testChecker({
      '/main.dart': '''

      class A {}
      class B extends A {}
      class C extends A {}

      void main() {
         dynamic y;
         Object o;
         int i;
         double d;
         num n;
         A a;
         B b;
         C c;
         y = a;
         o = a;
         i = /*severe:StaticTypeError*/a;
         d = /*severe:StaticTypeError*/a;
         n = /*severe:StaticTypeError*/a;
         a = a;
         b = /*info:DownCast*/a;
         c = /*info:DownCast*/a;
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
         int i;
         double d;
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

      Object top(int x) => /*config:Box*/x;
      int left(int x) => x;
      Object right(Object x) => x;
      int _bot(Object x) => /*info:Unbox should be warning:DownCast*/x;
      int bot(Object x) => /*pass should be info:Unbox*/x as int;

      void main() {
        { // Check typedef equality
          Left f = left;
          Left2 g = f;
        }
        // TODO(leafp) Decide on ClosureWrap vs DownCast (or error).
        {
          Top f;
          f = top;
          f = /*warning:ClosureWrap*/left;
          f = /*warning:ClosureWrap*/right;
          f = /*warning:ClosureWrap*/bot;
        }
        {
          Left f;
          f = /*warning:ClosureWrap*/top;
          f = left;
          f = /*warning:ClosureWrap should be severe:StaticTypeError*/right;
          f = /*warning:ClosureWrap*/bot;
        }
        {
          Right f;
          f = /*warning:ClosureWrap*/top;
          f = /*warning:ClosureWrap should be severe:StaticTypeError*/left;
          f = right;
          f = /*warning:ClosureWrap*/bot;
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
          f = /*warning:DownCast*/top;
          f = left;
          f = /*severe:StaticTypeError*/right;
          f = bot;
        }
        {
          Right f;
          f = /*warning:DownCast*/top;
          f = /*severe:StaticTypeError*/left;
          f = right;
          f = bot;
        }
        {
          Bot f;
          f = /*warning:DownCast*/top;
          f = /*warning:DownCast*/left;
          f = /*warning:DownCast*/right;
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
        // TODO(leafp) Should we consider allowing more unchecked casts
        // when dynamic is involved?
        {
          Top f;
          f = top;
          f = left;
          f = right;
          f = bot;
        }
        {
          Left f;
          f = /*warning:DownCast*/top;
          f = left;
          f = /*warning:ClosureWrap should be severe:StaticTypeError*/right;
          f = bot;
        }
        {
          Right f;
          f = /*warning:DownCast*/top;
          f = /*warning:ClosureWrap should be severe:StaticTypeError*/left;
          f = right;
          f = bot;
        }
        {
          Bot f;
          f = /*warning:DownCast*/top;
          f = /*warning:DownCast*/left;
          f = /*warning:DownCast*/right;
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
          f = /*warning:DownCast*/top;
          f = left;
          f = /*severe:StaticTypeError*/right;
          f = bot;
        }
        {
          Function2<A, A> f;
          f = /*warning:DownCast*/top;
          f = /*severe:StaticTypeError*/left;
          f = right;
          f = bot;
        }
        {
          Function2<A, B> f;
          f = /*warning:DownCast*/top;
          f = /*warning:DownCast*/left;
          f = /*warning:DownCast*/right;
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

          left = /*warning:DownCast*/top;
          left = left;
          left = /*severe:StaticTypeError*/right;
          left = bot;

          right = /*warning:DownCast*/top;
          right = /*severe:StaticTypeError*/left;
          right = right;
          right = bot;

          bot = /*warning:DownCast*/top;
          bot = /*warning:DownCast*/left;
          bot = /*warning:DownCast*/right;
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
      AToB _bot(BToA f) => /*warning:DownCast*/f;
      AToB bot(BToA f) => /*severe:InvalidRuntimeCheckError*/f as AToB;

      Function2<B, A> top(AToB f) => f;
      Function2<A, B> left(AToB f) => f;
      Function2<B, A> right(BToA f) => f;
      Function2<A, B> _bot(BToA f) => /*warning:DownCast*/f;
      Function2<A, B> bot(BToA f) =>
        /*severe:InvalidRuntimeCheckError*/f as Function2<A, B>;


      BToA top(Function2<A, B> f) => f;
      AToB left(Function2<A, B> f) => f;
      BToA right(Function2<B, A> f) => f;
      AToB _bot(Function2<B, A> f) => /*warning:DownCast*/f;
      AToB bot(Function2<B, A> f) =>
        /*severe:InvalidRuntimeCheckError*/f as AToB;

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
          f = /*warning:DownCast*/top;
          f = left;
          f = /*severe:StaticTypeError*/right;
          f = bot;
        }
        {
          Function2<BToA, BToA> f; // Right
          f = /*warning:DownCast*/top;
          f = /*severe:StaticTypeError*/left; 
          f = right;
          f = bot;
        }
        {
          Function2<BToA, AToB> f; // Bot
          f = bot;
          f = /*warning:DownCast*/left;
          f = /*warning:DownCast*/top;
          f = /*warning:DownCast*/left;
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

          left = /*pass should be warning:DownCast*/top;
          left = left;
          left = /*pass should be severe:StaticTypeError*/right;
          left = bot;

          right = /*pass should be warning:DownCast*/top;
          right = /*pass should be severe:StaticTypeError*/left;
          right = right;
          right = bot;

          bot = /*pass should be warning:DownCast*/top;
          bot = /*pass should be warning:DownCast*/left;
          bot = /*pass should be warning:DownCast*/right;
          bot = bot;
        }
      }
   '''
    });
  });
}
