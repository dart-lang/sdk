// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Dart core library.

class Object native "Object" {

  const Object();

  bool operator ==(Object other) {
    return this === other;
  }

  String toString() {
    return "Object";
  }

  /**
   * Return this object without type information.
   */
  get dynamic() { return this; }
}
