// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

patch class Object {
  /* patch */ String toString() => _toString(this);

  /* patch */ void noSuchMethod(String functionName, List args) {
    _noSuchMethod(this, functionName, args);
  }

  static void _noSuchMethod(Object obj, String functionName, List args)
      native "Object_noSuchMethod";

  static String _toString(Object obj) native "Object_toString";
}
