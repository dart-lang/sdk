// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// part of "core_patch.dart";

// The _GrowableArrayMarker class is used to signal to the List() factory
// whether a parameter was passed.
class _GrowableArrayMarker implements int {
  const _GrowableArrayMarker();
}

const _GROWABLE_ARRAY_MARKER = const _GrowableArrayMarker();

@patch
class List<E> {
  @patch
  factory List([int length]) = List<E>._internal;

  @patch
  factory List.filled(int length, E fill, {bool growable: false}) {
    // All error handling on the length parameter is done at the implementation
    // of new _List.
    var result = growable ? new _GrowableList<E>(length) : new _List<E>(length);
    if (fill != null) {
      for (int i = 0; i < length; i++) {
        result[i] = fill;
      }
    }
    return result;
  }

  @patch
  factory List.from(Iterable elements, {bool growable: true}) {
    if (elements is EfficientLengthIterable) {
      int length = elements.length;
      var list = growable ? new _GrowableList<E>(length) : new _List<E>(length);
      if (length > 0) {
        // Avoid creating iterator unless necessary.
        int i = 0;
        for (var element in elements) {
          list[i++] = element;
        }
      }
      return list;
    }
    List<E> list = new _GrowableList<E>(0);
    for (E e in elements) {
      list.add(e);
    }
    if (growable) return list;
    return makeListFixedLength(list);
  }

  @patch
  factory List.unmodifiable(Iterable elements) {
    List result = new List<E>.from(elements, growable: false);
    return makeFixedListUnmodifiable(result);
  }

  // The List factory constructor redirects to this one so that we can change
  // length's default value from the one in the SDK's implementation.
  factory List._internal([int length = _GROWABLE_ARRAY_MARKER]) {
    if (identical(length, _GROWABLE_ARRAY_MARKER)) {
      return new _GrowableList<E>(0);
    }
    // All error handling on the length parameter is done at the implementation
    // of new _List.
    return new _List<E>(length);
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
