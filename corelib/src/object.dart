// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/**
 * Everything in Dart is an [Object].
 */
class Object {
  const Object();

  String toString() => ObjectImplementation.toStringImpl(this);

  void noSuchMethod(String name, List args) {
    ObjectImplementation.noSuchMethodImpl(this, name, args);
  }

  operator ==(other) => this === other;

  get dynamic() => this;
}
