// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

test(String? x) {
  switch (x) {
    case String? foobar? when foobar is Never:
    case String? foobar when foobar != null:
    case String? foobar! when foobar == "foobar":
      return foobar.startsWith("foo"); // The static type of 'foobar' is expected to be the non-nullable 'String'.
    default:
      return null;
  }
}
