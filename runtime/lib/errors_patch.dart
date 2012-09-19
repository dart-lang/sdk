// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

patch class NoSuchMethodError {
  /* patch */ static String safeToString(Object object) {
    if (object is int || object is double || object is bool || null == object) {
      return object.toString();
    }
    if (object is String) {
      String escaped = object.replaceAll('"', '\\"');
      return '"$escaped"';
    }
    return Object._toString(object);
  }
}
