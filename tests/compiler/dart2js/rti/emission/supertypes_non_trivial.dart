// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// @dart = 2.7

/*class: A:checkedInstance,checks=[],indirectInstance*/
class A<T> {}

/*class: B:checks=[],instance*/
class B<S, T> extends A<T> {} // Non-trivial substitution of A.

/*class: C:checks=[$isA],instance*/
class C<S, T> implements B<S, T> {} // Non-trivial substitution of A

@pragma('dart2js:noInline')
test(o) => o is A<String>;

main() {
  test(new C<int, String>());
  test(new B<String, int>());
}
