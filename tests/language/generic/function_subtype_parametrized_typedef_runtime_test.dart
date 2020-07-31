// TODO(multitest): This was automatically migrated from a multitest and may
// contain strange or dead code.

// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Test of the subtype relationship that includes parametrized typedefs and
// invariant occurrences of types.

typedef H<X> = void Function<Y extends X>();

class A {}

class B extends A {}

class C extends B {}

void foo(H<A> ha, H<B> hb, H<C> hc) {











}

main() {}
