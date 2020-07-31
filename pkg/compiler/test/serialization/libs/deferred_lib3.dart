// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// @dart = 2.7

library deferred_constants1_lib3;

import 'dart:async';

class C {
  final value;

  const C(this.value);
}

FutureOr<T> func<T>(@Deprecated('bar') foo) => null;

/// ---------------------------------------------------------------------------
/// Constant used from main: not deferred.
/// ---------------------------------------------------------------------------

const C1 = const C(1);

/// ---------------------------------------------------------------------------
/// Constant completely deferred.
/// ---------------------------------------------------------------------------

const C2 = C;

/// ---------------------------------------------------------------------------
/// Constant fields not used from main, but the constant value are: so the field
/// and the constants are in different output units.
/// ---------------------------------------------------------------------------

const C3 = func;

const C4 = const [1, 1.5, bool];

/// ---------------------------------------------------------------------------
/// Constant value used form a closure within main.
/// ---------------------------------------------------------------------------

const C5 = const {};

/// ---------------------------------------------------------------------------
/// Deferred constants, used after a deferred load.
/// ---------------------------------------------------------------------------

const FutureOr<int> Function(dynamic) C6 = func;

const C7 = null;
