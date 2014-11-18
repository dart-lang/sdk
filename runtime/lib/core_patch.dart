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

// The members of this class are cloned and added to each class that
// represents an enum type.
class _EnumHelper {
  // Declare the list of enum value names private. When this field is
  // cloned into a user-defined enum class, the field will be inaccessible
  // because of the library-specific name suffix. The toString() function
  // below can access it because it uses the same name suffix.
  static const List<String> _enum_names = null;
  String toString() => _enum_names[index];
}
