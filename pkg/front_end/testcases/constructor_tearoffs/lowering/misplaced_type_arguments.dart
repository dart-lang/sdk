// Copyright (c) 2021, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

class A<T> {
  A();
  A.named();
  factory A.fact() => new A();
  factory A.redirect() = A;
}

typedef B<T extends num> = A<T>;

test() {
  A.new<int>;
  A.named<int>;
  A.fact<int>;
  A.redirect<int>;
  B.new<int>;
  B.named<int>;
  B.fact<int>;
  B.redirect<int>;
}

main() {}
