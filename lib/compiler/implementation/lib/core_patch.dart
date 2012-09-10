// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Patch file for dart:core classes.
#import('js_helper.dart');

// Patch for Object implementation.
patch class Object {
  patch String toString() {
    return Primitives.objectToString(this);
  }

  patch void noSuchMethod(String name, List args) {
    throw new NoSuchMethodException(this, name, args);
  }
}
