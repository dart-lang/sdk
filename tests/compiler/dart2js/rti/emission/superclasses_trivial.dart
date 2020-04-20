// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// @dart = 2.7

/*class: A:checkedInstance,checks=[],indirectInstance*/
class A<T> {}

/*class: B:checks=[],instance*/
class B<S, T> extends A<T> {} // Non-trivial substitution of A.

/*class: C:checks=[],instance*/
class C<T> extends B<T, T> {} // Trivial substitution of A

@pragma('dart2js:noInline')
test(o) => o is A<String>;

main() {
  test(new C<String>());
  test(new B<String, int>());
}
