// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

patch class ListImplementation<E> {
  /* patch */ factory List([int length = null]) {
    if (length === null) {
      return new GrowableObjectArray<E>();
    } else {
      return new ObjectArray<E>(length);
    }
  }

  /* patch */ static _from(Iterable other) {
    GrowableObjectArray list = new GrowableObjectArray();
    for (final e in other) {
      list.add(e);
    }
    return list;
  }
}
