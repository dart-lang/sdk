// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

class Object {
  const Object();
  String toString() native "Object_toString";
  bool operator ==(other) {
    return this === other;
  }
  void noSuchMethod(String function_name, Array args) native "Object_noSuchMethod";

  /**
   * Return this object without type information.
   */
  get dynamic() { return this; }
}
