// Copyright (c) 2021, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

class A<T> {}

typedef B<X extends A<X>> = A<X>;

foo() {
  B<A<int>> x1;
  A<B<A<int>>> x2;
}

B<A<int>> bar1a() => throw 42;
A<B<A<int>>> bar1b() => throw 42;

bar2a(B<A<int>> x) => throw 42;
bar2b(A<B<A<int>>> x) => throw 42;

bar3a<X extends B<A<int>>>() => throw 42;
bar3b<X extends A<B<A<int>>>>() => throw 42;

class Bar1<X extends B<A<int>>> {
  B<A<int>> barBar11() => throw 42;
  barBar12(B<A<int>> x) => throw 42;
  barBar13<X extends B<A<int>>>() => throw 42;
}

class Bar2<X extends A<B<A<int>>>> {
  A<B<A<int>>> barBar21() => throw 42;
  barBar22(A<B<A<int>>> x) => throw 42;
  barBar23<X extends A<B<A<int>>>>() => throw 42;
}

typedef Baz1 = B<A<int>>;
typedef Baz2 = A<B<A<int>>>;

main() {}
