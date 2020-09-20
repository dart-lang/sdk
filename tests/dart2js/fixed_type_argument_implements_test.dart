// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Test that we emit the relation between B and A even when B is only live
// as a type argument through the supertype of D.

class A {}

class B implements A {}

class C<T> {}

class D implements C<B> {}

main() {
  C<A> c = new D();
  test(c);
}

@pragma('dart2js:noInline')
void test(C<A> c) {}
