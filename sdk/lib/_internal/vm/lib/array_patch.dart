// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// part of "core_patch.dart";

@patch
class List<E> {
  @patch
  factory List.empty({bool growable = false}) {
    return growable ? <E>[] : _List<E>(0);
  }

  @patch
  factory List([int? length]) native "List_new";

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
    if (elements is EfficientLengthIterable<E>) {
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
    // If elements is an Iterable<E>, we won't need a type-test for each
    // element. In the "common case" that elements is an Iterable<E>, this
    // replaces a type-test on every element with a single type-test before
    // starting the loop.
    if (elements is Iterable<E>) {
      List<E> list = new _GrowableList<E>(0);
      for (E e in elements) {
        list.add(e);
      }
      if (growable) return list;
      return makeListFixedLength(list);
    } else {
      List<E> list = new _GrowableList<E>(0);
      for (E e in elements) {
        list.add(e);
      }
      if (growable) return list;
      return makeListFixedLength(list);
    }
  }

  @patch
  factory List.of(Iterable<E> elements, {bool growable: true}) {
    // TODO(32937): Specialize to benefit from known element type.
    return List.from(elements, growable: growable);
  }

  @patch
  @pragma("vm:prefer-inline")
  factory List.generate(int length, E generator(int index),
      {bool growable = true}) {
    final List<E> result =
        growable ? new _GrowableList<E>(length) : new _List<E>(length);
    for (int i = 0; i < result.length; ++i) {
      result[i] = generator(i);
    }
    return result;
  }

  @patch
  factory List.unmodifiable(Iterable elements) {
    final result = new List<E>.from(elements, growable: false);
    return makeFixedListUnmodifiable(result);
  }

  // Factory constructing a mutable List from a parser generated List literal.
  // [elements] contains elements that are already type checked.
  @pragma("vm:entry-point", "call")
  factory List._fromLiteral(List elements) {
    if (elements.isEmpty) {
      return new _GrowableList<E>(0);
    }
    final result = new _GrowableList<E>._withData(unsafeCast<_List>(elements));
    result._setLength(elements.length);
    return result;
  }
}
