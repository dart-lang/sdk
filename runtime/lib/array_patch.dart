// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// The _GrowableArrayMarker class is used to signal to the List() factory
// whether a parameter was passed.
class _GrowableArrayMarker implements int {
  const _GrowableArrayMarker();
}

const _GROWABLE_ARRAY_MARKER = const _GrowableArrayMarker();

patch class List<E> {
  /* patch */ factory List([int length = _GROWABLE_ARRAY_MARKER]) {
    if (identical(length, _GROWABLE_ARRAY_MARKER)) {
      return new _GrowableList<E>(0);
    }
    // All error handling on the length parameter is done at the implementation
    // of new _List.
    return new _List<E>(length);
  }

  /* patch */ factory List.filled(int length, E fill) {
    // All error handling on the length parameter is done at the implementation
    // of new _List.
    var result = new _List<E>(length);
    if (fill != null) {
      for (int i = 0; i < length; i++) {
        result[i] = fill;
      }
    }
    return result;
  }

  /* patch */ factory List.from(Iterable other, { bool growable: true }) {
    if (other is EfficientLength) {
      int length = other.length;
      var list = growable ? new _GrowableList<E>(length) : new _List<E>(length);
      int i = 0;
      for (var element in other) { list[i++] = element; }
      return list;
    }
    List<E> list = new _GrowableList<E>(0);
    for (E e in other) {
      list.add(e);
    }
    if (growable) return list;
    return makeListFixedLength(list);
  }

  // Factory constructing a mutable List from a parser generated List literal.
  // [elements] contains elements that are already type checked.
  factory List._fromLiteral(List elements) {
    if (elements.isEmpty) {
      return new _GrowableList<E>(0);
    }
    var result = new _GrowableList<E>.withData(elements);
    result._setLength(elements.length);
    return result;
  }
}
