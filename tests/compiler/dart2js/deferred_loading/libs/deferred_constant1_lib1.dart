// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library deferred_constants1_lib1;

class C {
  /*element: C.value:OutputUnit(main, {})*/
  final value;
  /*element: C.:OutputUnit(main, {})*/
  const C(this.value);
}

/// ---------------------------------------------------------------------------
/// Constant used from main: not deferred.
/// ---------------------------------------------------------------------------

/*element: C1:OutputUnit(main, {})*/
const C1 = /*OutputUnit(main, {})*/ const C(1);

/// ---------------------------------------------------------------------------
/// Constant completely deferred.
/// ---------------------------------------------------------------------------

/*element: C2:OutputUnit(1, {lib2})*/
const C2 = /*OutputUnit(1, {lib2})*/ const C(2);

/// ---------------------------------------------------------------------------
/// Constant field not used from main, but the constant value is: so the field
/// and the constant value are in different output units.
/// ---------------------------------------------------------------------------

/*element: C3:OutputUnit(1, {lib2})*/
const C3 = /*OutputUnit(main, {})*/ const C(1);
