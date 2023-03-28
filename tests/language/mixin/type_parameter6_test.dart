// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// TODO(51557): Decide if the mixins being applied in this test should be
// "mixin", "mixin class" or the test should be left at 2.19.
// @dart=2.19

class A<T> {}

class B<S> {
  int? foo(S s) => null;
}

class C extends A<int> with B<String> {}

main() {
  var list = <String>['foo'];
  var c = new C();
  list.map(c.foo);
}
