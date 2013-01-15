// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Note that the optimizing compiler depends on the algorithm which
// returns a _GrowableObjectArray if length is null, otherwise returns
// fixed size array.
patch class List<E> {
  /* patch */ factory List([int length = 0]) {
    if ((length is! int) || (length < 0)) {
      _throwArgumentError(length);
    }
    _GrowableObjectArray<E> result = new _GrowableObjectArray<E>(length);
    return result;
  }

  /* patch */ factory List.fixedLength(int length, {E fill: null}) {
    if ((length is! int) || (length < 0)) {
      _throwArgumentError(length);
    }
    _ObjectArray<E> result = new _ObjectArray<E>(length);
    if (fill != null) {
      for (int i = 0; i < length; i++) {
        result[i] = fill;
      }
    }
    return result;
  }

  /* patch */ factory List.filled(int length, E fill) {
    if ((length is! int) || (length < 0)) {
      _throwArgumentError(length);
    }
    _GrowableObjectArray<E> result =
        new _GrowableObjectArray<E>.withCapacity(length < 4 ? 4 : length);
    result.length = length;
    if (fill != null) {
      for (int i = 0; i < length; i++) {
        result[i] = fill;
      }
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

  static void _throwArgumentError(int length) {
    throw new ArgumentError("Length must be a positive integer: $length.");
  }
}
