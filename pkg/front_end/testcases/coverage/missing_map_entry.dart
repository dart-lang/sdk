// Copyright (c) 2026, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Based on tests/co19/src/Language/Expressions/Maps/syntax_t05.dart

test() {
  <String, int>{"key1": 1, "key2" : 2,,"key3": 3};
}