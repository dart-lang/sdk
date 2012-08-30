// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Dart core library.

abstract class Comparable {
  factory Comparable._uninstantiable() {
    throw const UnsupportedOperationException(
        "abstract class Comparable cannot be instantiated");
  }
  abstract int compareTo(Comparable other);
}
