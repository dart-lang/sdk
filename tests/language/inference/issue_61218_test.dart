// Copyright (c) 2025, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import '../static_type_helper.dart';

class A {} // Distance from the top type: 2 (Object? -> Object -> A).

mixin M {} // Distance from the top type: 2.
class AM = A with M; // Distance from the top type: 3.

class B extends AM {} // Distance from the top type: 4.

class C {} // Distance from the top type: 2.

class D extends C {} // Distance from the top type: 3.

class E extends D {} // Distance from the top type: 4.

class F1 extends B implements E {}

class F2 extends B implements E {}

// AM2 is desugared as follows:
//
//   - _AM2&A&M extends A implements M (anonymous mixin application).
//   - AM2 extends _AM2&A&M.
class AM2 extends A with M {} // Distance from the top type: 4.

class B2 extends AM2 {} // Distance from the top type: 5.

class F12 extends B2 implements E {}

class F22 extends B2 implements E {}

void f(bool b, F1 f1, F2 f2, F12 f12, F22 f22) {
  // F1 and F2 have same two supertypes, B and E. Both of the supertypes are of
  // distance 4 from the top type. The UP algorithm ignores all of the types of
  // the same distance in case there are more than one of those. The next types
  // in the supertype chains are AM and D, which are of equal distance 3 from
  // the top type and are dismissed by the UP algorithms as potential candidates
  // for the upper bound. The next types the algorithm tries are A, M, and
  // C. They all have the same distance 2 from the top type. Finally, their
  // supertype, which is Object, is yielded as the result.
  var x = b ? f1 : f2;
  x.expectStaticType<Exactly<Object>>();

  // F12 and F22 have same two supertypes, B2 and E. However, B2 is of a bigger
  // distance from the top type than E, so it's chosen as the upper bound by the
  // algorithm.
  var x2 = b ? f12 : f22;
  x2.expectStaticType<Exactly<B2>>();
}

void main() {}
