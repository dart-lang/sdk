// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library test;

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
  E(T a) : super(throw '', a);
}

class F<S, T> extends A<S, T> {
  F(S x, T y, {required List<S> a, required List<T> b}) : super(x, y);
  F.named(S x, T y, [S? a, T? b]) : super(x, y);
}

void test() {
  {
    A<int, String> a0 = new A(3, "hello");
    A<int, String> a1 = new A.named(3, "hello");
    A<int, String> a2 = new A<int, String>(3, "hello");
    A<int, String> a3 = new A<int, String>.named(3, "hello");
    A<int, String> a4 = /*error:INVALID_CAST_NEW_EXPR*/ new A<int, dynamic>(
      3,
      "hello",
    );
    A<int, String> a5 =
        /*error:INVALID_CAST_NEW_EXPR*/ new A<dynamic, dynamic>.named(
          3,
          "hello",
        );
  }
  {
    A<int, String> a0 = new A(
      /*error:ARGUMENT_TYPE_NOT_ASSIGNABLE*/ "hello",
      /*error:ARGUMENT_TYPE_NOT_ASSIGNABLE*/ 3,
    );
    A<int, String> a1 = new A.named(
      /*error:ARGUMENT_TYPE_NOT_ASSIGNABLE*/ "hello",
      /*error:ARGUMENT_TYPE_NOT_ASSIGNABLE*/ 3,
    );
  }
  {
    A<int, String> a0 = new B("hello", 3);
    A<int, String> a1 = new B.named("hello", 3);
    A<int, String> a2 = new B<String, int>("hello", 3);
    A<int, String> a3 = new B<String, int>.named("hello", 3);
    A<int, String> a4 = /*error:INVALID_ASSIGNMENT*/ new B<String, dynamic>(
      "hello",
      3,
    );
    A<int, String> a5 =
        /*error:INVALID_ASSIGNMENT*/ new B<dynamic, dynamic>.named("hello", 3);
  }
  {
    A<int, String> a0 = new B(
      /*error:ARGUMENT_TYPE_NOT_ASSIGNABLE*/ 3,
      /*error:ARGUMENT_TYPE_NOT_ASSIGNABLE*/ "hello",
    );
    A<int, String> a1 = new B.named(
      /*error:ARGUMENT_TYPE_NOT_ASSIGNABLE*/ 3,
      /*error:ARGUMENT_TYPE_NOT_ASSIGNABLE*/ "hello",
    );
  }
  {
    A<int, int> a0 = new C(3);
    A<int, int> a1 = new C.named(3);
    A<int, int> a2 = new C<int>(3);
    A<int, int> a3 = new C<int>.named(3);
    A<int, int> a4 = /*error:INVALID_ASSIGNMENT*/ new C<dynamic>(3);
    A<int, int> a5 = /*error:INVALID_ASSIGNMENT*/ new C<dynamic>.named(3);
  }
  {
    A<int, int> a0 = new C(/*error:ARGUMENT_TYPE_NOT_ASSIGNABLE*/ "hello");
    A<int, int> a1 = new C.named(
      /*error:ARGUMENT_TYPE_NOT_ASSIGNABLE*/ "hello",
    );
  }
  {
    A<int, String> a0 = new D("hello");
    A<int, String> a1 = new D.named("hello");
    A<int, String> a2 = new D<int, String>("hello");
    A<int, String> a3 = new D<String, String>.named("hello");
    A<int, String> a4 = /*error:INVALID_ASSIGNMENT*/ new D<num, dynamic>(
      "hello",
    );
    A<int, String> a5 =
        /*error:INVALID_ASSIGNMENT*/ new D<dynamic, dynamic>.named("hello");
  }
  {
    A<int, String> a0 = new D(/*error:ARGUMENT_TYPE_NOT_ASSIGNABLE*/ 3);
    A<int, String> a1 = new D.named(/*error:ARGUMENT_TYPE_NOT_ASSIGNABLE*/ 3);
  }
  {
    A<C<int>, String> a0 = new E("hello");
  }
  {
    // Check named and optional arguments
    A<int, String> a0 = new F(3, "hello", a: [3], b: ["hello"]);
    A<int, String> a1 = new F(
      3,
      "hello",
      a: [/*error:LIST_ELEMENT_TYPE_NOT_ASSIGNABLE*/ "hello"],
      b: [/*error:LIST_ELEMENT_TYPE_NOT_ASSIGNABLE*/ 3],
    );
    A<int, String> a2 = new F.named(3, "hello", 3, "hello");
    A<int, String> a3 = new F.named(3, "hello");
    A<int, String> a4 = new F.named(
      3,
      "hello",
      /*error:ARGUMENT_TYPE_NOT_ASSIGNABLE*/ "hello",
      /*error:ARGUMENT_TYPE_NOT_ASSIGNABLE*/ 3,
    );
    A<int, String> a5 = new F.named(
      3,
      "hello",
      /*error:ARGUMENT_TYPE_NOT_ASSIGNABLE*/ "hello",
    );
  }
}

main() {}
