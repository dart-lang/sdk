// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:_runtime' as dart;

// Returns tWrapped? as a wrapped type.
Type nullable(Type tWrapped) {
  var t = dart.unwrapType(tWrapped);
  var tNullable = dart.nullable(t);
  return dart.wrapType(tNullable);
}

// Returns tWrapped* as a wrapped type.
Type legacy(Type tWrapped) {
  var t = dart.unwrapType(tWrapped);
  var tLegacy = dart.legacy(t);
  return dart.wrapType(tLegacy);
}
