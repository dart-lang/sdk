// Copyright (c) 2026, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import "dart:_compact_hash" show createConstMapFromMapOfDeeplyImmutables;
import "dart:_internal" show patch;
import "dart:_vm" show FinalThreadLocal;

@patch
final class _HeaderValue {
  @patch
  _HeaderValue(String value, Map<String, String?> parameters)
    : _value = value,
      parameters = createConstMapFromMapOfDeeplyImmutables(parameters);
}
