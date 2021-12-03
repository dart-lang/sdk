// Copyright (c) 2021, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

class A {
  final int Function(int) x;
  const A(bool b)
      : x = (b
            ? id
            : other)<int>; // OK, `(...)<T1..Tk>` is potentially constant.
}

X id<X>(X x) => x;
X other<X>(X x) => throw '$x';

void main() {
  const c1 =
      id<int>; // Already supported prior to the addition on this feature.
  const c2 =
      id; // Make `c2` a constant expression whose value is a function object.
  const c3 = c2<int>; // OK, perform generic function instantiation on `c2`.
  const c4 = A(
      true); // OK, `(b ? id : other)<int>` is constant after substitution `b` -> `true`.
  print('$c1, $c2, $c3, $c4');
}
