// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import "dart:math";
import "dart:typed_data";

// We need to pass the exception object as second parameter to the continuation.
// See vm/ast_transformer.cc for usage.
void  _asyncCatchHelper(catchFunction, continuation) {
  catchFunction((e) => continuation(null, e));
}
