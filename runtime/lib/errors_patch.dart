// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

patch class NoSuchMethodError {
  /* patch */ static String safeToString(Object object) {
    if (object is int || object is double || object is bool || null == object) {
      return object.toString();
    }
    if (object is String) {
      // TODO(ahe): Remove hack when http://dartbug.com/4995 is fixed.
      const hack = '\\' '"';
      String escaped = object.replaceAll('"',  hack);
      return '"$escaped"';
    }
    return Object._toString(object);
  }
}
