// Copyright (c) 2016, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE.md file.

import "mixin_library.dart" show Mixin;

class Super<S> {
  foo() => 40;
  f() => 3;
}

class C<V> extends Super<V> with Mixin<V> {}

class D extends Super with Mixin {}

class C2<V> = Super<V> with Mixin<V>;

class D2 = Super with Mixin;

main() {
  print(new C().foo());
  print(new C2().foo());
}
