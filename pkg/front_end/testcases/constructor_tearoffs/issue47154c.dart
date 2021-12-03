// Copyright (c) 2021, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// A potentially constant type expression is supported for `as` (and `is`)
class A<X> {
  final List<X> x;
  const A(x) : x = x is List<X> ? x : x as List<X>;
}

void m<X>(X x) {}

// Generic function instantiation to a type parameter is supported implicitly.
class B<X> {
  final void Function(X) f;
  const B() : f = m;
}

// But it is not supported explicitly.
class C<X> {
  final f;
  const C() : f = m<X>; // Error, but should be accepted.
}

void main() {
  const A<int>(<int>[1]); // OK.
  const b = B<String>(); // OK.
  print(b.f.runtimeType); // OK: 'String => void'.
  const c = C<
      String>(); // Compile-time error in `C`, but should be accepted when it works.
  print(c.f.runtimeType); // (Never executed, so we don't know).
}
