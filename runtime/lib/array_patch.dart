// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Note that optimizing compiler depends on the algorithm which
// returns a _GrowableObjectArray if length is null, otherwise returns
// fixed size array.
patch class ListImplementation<E> {
  /* patch */ factory List([int length = null]) {
    if (length === null) {
      return new _GrowableObjectArray<E>();
    } else {
      return new _ObjectArray<E>(length);
    }
  }

  /* patch */ static _from(Iterable other) {
    _GrowableObjectArray list = new _GrowableObjectArray();
    for (final e in other) {
      list.add(e);
    }
    return list;
  }
}
