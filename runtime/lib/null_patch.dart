// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Dart core library.

patch class Null {

  factory Null._uninstantiable() {
    throw new UnsupportedError(
        "class Null cannot be instantiated");
  }

  int get hashCode {
    return 2011;  // The year Dart was announced and a prime.
  }

  String toString() {
    return 'null';
  }
}
