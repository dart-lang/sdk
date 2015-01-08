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

      void main() {
         dynamic y;
         Object o;
         int i;
         double d;
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
         int i;
         double d;
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
         int i;
         double d;
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
    }, covariantGenerics: false);
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
        lOfAs = /*info:DownCast*/lRaw;
        lOfAs = /*info:DownCast*/lOfDynamics;

        // M<dynamic> </:/> L<A>
        lOfAs = /*severe:StaticTypeError*/mRaw;
        lOfAs = /*severe:StaticTypeError*/mOfDynamics;

        // L<T> <: L<S> iff S = dynamic or S=T
        lOfBs = /*info:DownCast*/lRaw;
        lOfBs = /*info:DownCast*/lOfDynamics;

        // M<dynamic> </:/> L<B>
        lOfBs = /*severe:StaticTypeError*/mRaw;
        lOfBs = /*severe:StaticTypeError*/mOfDynamics;

        // L<T> <: L<S> iff S = dynamic or S=T
        lOfCs = /*info:DownCast*/lRaw;
        lOfCs = /*info:DownCast*/lOfDynamics;

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
        mOfAs = /*info:DownCast*/mRaw;
        mOfAs = /*info:DownCast*/mOfDynamics;

        // M<T> <: L<S> iff S = dynamic or S=T
        mOfBs = /*info:DownCast*/lRaw;
        mOfBs = /*info:DownCast*/lOfDynamics;

        // M<dynamic> </:/> M<B>
        mOfBs = /*info:DownCast*/mRaw;
        mOfBs = /*info:DownCast*/mOfDynamics;

        // M<T> <: L<S> iff S = dynamic or S=T
        mOfCs = /*info:DownCast*/lRaw;
        mOfCs = /*info:DownCast*/lOfDynamics;

        // M<dynamic> </:/> M<C>
        mOfCs = /*info:DownCast*/mRaw;
        mOfCs = /*info:DownCast*/mOfDynamics;

        // Concrete subclass subtyping
        ns = /*info:DownCast*/lRaw;
        ns = /*info:DownCast*/lOfDynamics;
        ns = /*info:DownCast*/mRaw;
        ns = /*info:DownCast*/mOfDynamics;
      }
   '''
    }, covariantGenerics: false);
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
        lOfDA = /*info:DownCast*/lRaw;
        lOfDA = /*info:DownCast*/lOfD_;
        lOfDA = /*info:DownCast*/lOfA_;
        lOfDA = lOfDA;
        lOfDA = /*severe:StaticTypeError*/lOfAD;
        lOfDA = /*info:DownCast*/lOfDD;
        lOfDA = lOfAA;

        // L<A, dynamic>
        lOfAD = /*info:DownCast*/lRaw;
        lOfAD = /*info:DownCast*/lOfD_;
        lOfAD = /*info:DownCast*/lOfA_;
        lOfAD = /*severe:StaticTypeError*/lOfDA;
        lOfAD = lOfAD;
        lOfAD = /*info:DownCast*/lOfDD;
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
        lOfAA = /*info:DownCast*/lRaw;
        lOfAA = /*info:DownCast*/lOfD_;
        lOfAA = /*info:DownCast*/lOfA_;
        lOfAA = /*info:DownCast*/lOfDA;
        lOfAA = /*info:DownCast*/lOfAD;
        lOfAA = /*info:DownCast*/lOfDD;
        lOfAA = lOfAA;
      }
   '''
    }, covariantGenerics: false);
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
    }, covariantGenerics: true);
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
            /*warning:InferableOverride*/var f3;
            /*severe:InvalidMethodOverride*/dynamic f4;
          }
       '''
    });
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
            /*warning:InferableOverride*/get f3 => null;
            /*severe:InvalidMethodOverride*/dynamic get f4 => null;
          }
       '''
    });
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
            /*warning:InferableOverride*/get f3 => null;
            /*severe:InvalidMethodOverride*/dynamic get f4 => null;
          }
       '''
    });
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
            /*pass should be warning:InferableOverride*/set f5(B value) {}
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
            /*pass should be warning:InferableOverride*/set f5(B value) {}
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
            /*warning:InferableOverride*/m5(value) {}
            /*severe:InvalidMethodOverride*/dynamic m6(dynamic value) {}
          }
       '''
    });
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
            (/*severe:StaticTypeError*/y += 5);
            y += 3.14;

            num z = 0;
            z += 5;
            z += 3.14;

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
}
