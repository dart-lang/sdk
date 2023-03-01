// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// TODO(51557): Decide if the mixins being applied in this test should be
// "mixin", "mixin class" or the test should be left at 2.19.
// @dart=2.19

class Mixin {}

class A {
  const A(foo);
}

class B extends A with Mixin {
  const B(foo) : super(foo);
}

main() {
  var a = const B(42);
}
