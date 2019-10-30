// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Copied from tests/compiler/dartdevc_native/runtime_utils_nnbd.dart.

import 'dart:_runtime' as dart;

/// The runtime representation of the never type.
final neverType = dart.wrapType(dart.never_);

/// Sets the mode of the runtime subtype checks.
///
/// In tests the mode should be set only once at the very beginning of the test.
/// Changing the mode after any calls to dart.isSubtype() is not supported.
void strictSubtypeChecks(bool flag) => dart.strictSubtypeChecks(flag);

/// Returns tWrapped? as a wrapped type.
Type nullable(Type tWrapped) {
  var t = dart.unwrapType(tWrapped);
  var tNullable = dart.nullable(t);
  return dart.wrapType(tNullable);
}

/// Returns tWrapped* as a wrapped type.
Type legacy(Type tWrapped) {
  var t = dart.unwrapType(tWrapped);
  var tLegacy = dart.legacy(t);
  return dart.wrapType(tLegacy);
}
