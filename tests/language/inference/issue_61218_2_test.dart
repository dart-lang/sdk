// Copyright (c) 2025, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import '../static_type_helper.dart';

class A {} // Distance from the top type: 2 (Object? -> Object -> A).

class B1 {} // Distance from the top type: 2.

class B2 extends B1 {} // Distance from the top type: 3.

mixin M1 {} // Distance from the top type: 2.

mixin M2 implements B2 {} // Distance from the top type: 4.

mixin M3 {} // Distance from the top type: 2.

// The following class hierarchy is synthesized:
//
//   - Object.
//       - Distance from the top type: 1.
//   - A extends Object.
//       - Distance from the top type: 2.
//   - _C&A&M1 extends A implements M1 (anonymous mixin application).
//       - Distance from the top type: 3.
//   - _C&A&M1&M2 extends _C&A&M1 implements M2 (anonymous).
//       - Distance from the top type: 5.
//       - _Note that M2 is of distance 4 from the top type._
//   - C extends _C&A&M1&M2 implements M3 (named mixin application).
//       - Distance from the top type: 6.
class C1 = A with M1, M2, M3;

class C2 extends C1 {} // Distance from the top type: 7.

class D1 {} // Distance from the top type: 2.

class D2 extends D1 {} // Distance from the top type: 3.

class D3 extends D2 {} // Distance from the top type: 4.

class D4 extends D3 {} // Distance from the top type: 5.

class D5 extends D4 {} // Distance from the top type: 6.

class D6 extends D5 {} // Distance from the top type: 7.

class E extends C2 implements D6 {}

class F extends C2 implements D6 {}

test(bool b, E e, F f) {
  // Both E and F have two immediate supertypes, C2 and D6, of equal distance 7
  // from the top type. The UP algorithm for interface types rejects both of
  // them and tries the types closer to the top. The next two types in the
  // supertype chain are C1 and D5, which are of equals distance 6 from the top
  // type. Going higher up in the supertype chains, the anonymous mixin
  // application _C&A&M1&M2 is compared against D4, but anonymous mixin
  // applications are ignored as potential candidates for the outcome of UP, so
  // D4 will be chosen.
  var ef = b ? e : f;
  ef.expectStaticType<Exactly<D4>>();
}

main() {}
