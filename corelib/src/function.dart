// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Dart core library.

abstract class Function {
  factory Function._uninstantiable() {
    throw const UnsupportedOperationException(
        "abstract class Function cannot be instantiated");
  }
}
