// Copyright (c) 2024, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

class Field {
  var _ = 10;

  void member() {
    var _ = 1;
    int _ = 2;

    // Assigns to field.
    _ = 3;
  }
}
