// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/*class: A:checkedTypeArgument,typeArgument*/
class A<T> {}

/*class: B:checkedInstance,checks=[],indirectInstance*/
class B<T> {}

/*class: C:checks=[],instance*/
class C<T> extends B<A<T>> {}

@pragma('dart2js:noInline')
test(o) => o is B<A<String>>;

main() {
  test(new C<String>());
  test(new C<int>());
}
