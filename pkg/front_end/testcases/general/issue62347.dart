// Copyright (c) 2026, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

mixin A<X> {
  foo<Y extends X>() {}
}

class B {
  foo<Z extends num>() {}
}

// Interface member: B.foo.
// Declared member: A<num>.foo.
class C extends B with A<num> {}
