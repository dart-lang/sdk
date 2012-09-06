// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/**
 * Everything in Dart is an [Object].
 */
class Object {
  const Object();

  bool operator ==(other) => this === other;

  get dynamic => this;

  external String toString();

  external void noSuchMethod(String name, List args);
}
