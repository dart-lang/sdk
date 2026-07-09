// Copyright (c) 2016, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

class Base {}

mixin Mixin {
  foo() => print('foo');
}

class Sub extends Base with Mixin {}

main() {
  new Sub().foo();
}
