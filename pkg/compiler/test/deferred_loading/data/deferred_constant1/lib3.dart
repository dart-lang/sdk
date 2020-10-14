// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// @dart = 2.7

library deferred_constants1_lib3;

/*class: C:
 class_unit=main{},
 type_unit=main{}
*/
class C {
  /*member: C.value:member_unit=main{}*/
  final value;

  const C(this.value);
}

/// ---------------------------------------------------------------------------
/// Constant used from main: not deferred.
/// ---------------------------------------------------------------------------

const C1 = const C(1);

/// ---------------------------------------------------------------------------
/// Constant completely deferred.
/// ---------------------------------------------------------------------------

const C2 = const C(2);

/// ---------------------------------------------------------------------------
/// Constant fields not used from main, but the constant value are: so the field
/// and the constants are in different output units.
/// ---------------------------------------------------------------------------

const C3 = const C(1);

const C4 = const C(4);

/// ---------------------------------------------------------------------------
/// Constant value used form a closure within main.
/// ---------------------------------------------------------------------------

const C5 = const C(5);

/// ---------------------------------------------------------------------------
/// Deferred constants, used after a deferred load.
/// ---------------------------------------------------------------------------

const C6 = "string6";

const C7 = const C(const C(7));
