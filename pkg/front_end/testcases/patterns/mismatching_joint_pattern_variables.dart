// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

test(dynamic x) {
  switch (x) {
    case int y when y == 0: // Error
    case [var y] when y == 0:
      return y;
    case int y when y == 0: // Error
    case [final int y] when y == 0:
      return y;
    case int y || [var y] when y == 0: // Error.
      return y;
    case int y || [final int y] when y == 0: // Error.
      return y;
    default:
      return null;
  }
}
