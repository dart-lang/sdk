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
      return new _GrowableObjectArray<E>(0);
    }
    // All error handling on the length parameter is done at the implementation
    // of new _ObjectArray.
    return new _ObjectArray<E>(length);
  }

  /* patch */ factory List.filled(int length, E fill) {
    // All error handling on the length parameter is done at the implementation
    // of new _ObjectArray.
    var result = new _ObjectArray<E>(length);
    if (fill != null) {
      for (int i = 0; i < length; i++) {
        result[i] = fill;
      }
    }
    return result;
  }

  /* patch */ factory List.from(Iterable other, { bool growable: true }) {
    // TODO(iposva): Avoid the iterators for the known lists and do the copy in
    // the VM directly.
    var len = null;
    // TODO(iposva): Remove this dance once dart2js does not implement
    // an Iterable that throws on calling length.
    try {
      len = other.length;
    } catch (e) {
      // Ensure that we try again below. 
      len = null;
    }
    if (len == null) {
      len = 0;
      try {
        var iter = other.iterator;
        while (iter.moveNext()) {
          len++;
        }
      } catch (e) {
        rethrow;  // Giving up and throwing to the caller.
      }
    }
    var result;
    if (growable) {
      result = new _GrowableObjectArray<E>.withCapacity(len);
      result.length = len;
    } else {
      result = new _ObjectArray<E>(len);
    }
    var iter = other.iterator;
    for (var i = 0; i < len; i++) {
      iter.moveNext();
      result[i] = iter.current;
    }
    return result;
  }

  // Factory constructing a mutable List from a parser generated List literal.
  // [elements] contains elements that are already type checked.
  factory List._fromLiteral(List elements) {
    if (elements.isEmpty) {
      return new _GrowableObjectArray<E>(0);
    }
    var result = new _GrowableObjectArray<E>.withData(elements);
    result._setLength(elements.length);
    return result;
  }
}
