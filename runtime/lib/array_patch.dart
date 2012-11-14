// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Note that the optimizing compiler depends on the algorithm which
// returns a _GrowableObjectArray if length is null, otherwise returns
// fixed size array.
patch class _ListImpl<E> {
  /* patch */ factory List([int length = null]) {
    if (length == null) {
      return new _GrowableObjectArray<E>();
    } else {
      return new _ObjectArray<E>(length);
    }
  }

  /* patch */ factory List.from(Iterable<E> other) {
    _GrowableObjectArray<E> list = new _GrowableObjectArray<E>();
    for (final e in other) {
      list.add(e);
    }
    return list;
  }

  // Factory constructing a mutable List from a parser generated List literal.
  // [elements] contains elements that are already type checked.
  factory List._fromLiteral(List elements) {
    var list = new List<E>();
    if (elements.length > 0) {
      list._setData(elements);
      list.length = elements.length;
    }
    return list;
  }
}
