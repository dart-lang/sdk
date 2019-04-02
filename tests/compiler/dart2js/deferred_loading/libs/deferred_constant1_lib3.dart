// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library deferred_constants1_lib3;

/*class: C:OutputUnit(main, {})*/
class C {
  /*element: C.value:OutputUnit(main, {})*/
  final value;
  /*strong.element: C.:OutputUnit(main, {})*/
  const C(this.value);
}

/// ---------------------------------------------------------------------------
/// Constant used from main: not deferred.
/// ---------------------------------------------------------------------------

/*strong.element: C1:OutputUnit(main, {})*/
const C1 = /*strong.OutputUnit(main, {})*/ const C(1);

/// ---------------------------------------------------------------------------
/// Constant completely deferred.
/// ---------------------------------------------------------------------------

/*strong.element: C2:OutputUnit(1, {lib2})*/
const C2 = /*strong.OutputUnit(1, {lib2})*/ const C(2);

/// ---------------------------------------------------------------------------
/// Constant fields not used from main, but the constant value are: so the field
/// and the constants are in different output units.
/// ---------------------------------------------------------------------------

/*strong.element: C3:OutputUnit(1, {lib2})*/
const C3 = /*strong.OutputUnit(main, {})*/ const C(1);

/*strong.element: C4:OutputUnit(1, {lib2})*/
const C4 = /*strong.OutputUnit(main, {})*/ const C(4);

/// ---------------------------------------------------------------------------
/// Constant value used form a closure within main.
/// ---------------------------------------------------------------------------

/*strong.element: C5:OutputUnit(1, {lib2})*/
const C5 = /*strong.OutputUnit(main, {})*/ const C(5);

/// ---------------------------------------------------------------------------
/// Deferred constants, used after a deferred load.
/// ---------------------------------------------------------------------------

/*strong.element: C6:OutputUnit(1, {lib2})*/
const C6 = "string6";

/*strong.element: C7:OutputUnit(1, {lib2})*/
const C7 = /*strong.OutputUnit(1, {lib2})*/ const C(const C(7));
