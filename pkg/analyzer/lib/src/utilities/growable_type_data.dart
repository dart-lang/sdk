// Copyright (c) 2026, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:typed_data';

final Uint32List _emptyUint32List = Uint32List(0);
final Uint8List _emptyUint8List = Uint8List(0);

/// Wrapper around Uint32List that automatically grows the underlying Uint32List
/// as needed. For use when we would otherwise add to a `List<int>` and later
/// convert it to a Uint32List to avoid unneeded overhead.
///
/// Uses the same growth strategy as [List].
class GrowableUint32List {
  Uint32List _array = _emptyUint32List;
  int _arrayLength = 0;

  int get length => _arrayLength;

  int operator [](int index) {
    assert(index < _arrayLength);
    return _array[index];
  }

  void add(int value) {
    if (_arrayLength >= _array.length) {
      _grow();
    }
    _array[_arrayLength++] = value;
  }

  bool equalToUint32List(Uint32List other) {
    if (_arrayLength != other.length) return false;
    for (int i = 0; i < _arrayLength; i++) {
      if (_array[i] != other[i]) return false;
    }
    return true;
  }

  /// Returns a (fixed size) Uint32List of size [length] and resets this class
  /// so it can be used again if needed.
  Uint32List takeAndReset() {
    Uint32List result;
    if (_arrayLength == _array.length) {
      result = _array;
    } else {
      result = Uint32List(_arrayLength);
      result.setRange(/* start = */ 0, _arrayLength, _array);
    }
    _array = _emptyUint32List;
    _arrayLength = 0;
    return result;
  }

  void _grow() {
    // New size copied from the sdks _GrowableList.
    Uint32List newArray = Uint32List((_arrayLength * 2) | 3);
    if (_arrayLength > 0) {
      newArray.setRange(/* start = */ 0, _arrayLength, _array);
    }
    _array = newArray;
  }
}

/// Wrapper around Uint8List that automatically grows the underlying Uint8List
/// as needed. For use when we would otherwise add to a `List<int>` and later
/// convert it to a Uint8List to avoid unneeded overhead.
///
/// Uses the same growth strategy as [List].
class GrowableUint8List {
  Uint8List _array = _emptyUint8List;
  int _arrayLength = 0;

  int get length => _arrayLength;

  int operator [](int index) {
    assert(index < _arrayLength);
    return _array[index];
  }

  void add(int value) {
    if (_arrayLength >= _array.length) {
      _grow();
    }
    _array[_arrayLength++] = value;
  }

  /// Returns a (fixed size) Uint8List of size [length] and resets this class
  /// so it can be used again if needed.
  Uint8List takeAndReset() {
    Uint8List result;
    if (_arrayLength == _array.length) {
      result = _array;
    } else {
      result = Uint8List(_arrayLength);
      result.setRange(/* start = */ 0, _arrayLength, _array);
    }
    _array = _emptyUint8List;
    _arrayLength = 0;
    return result;
  }

  void _grow() {
    // New size copied from the sdks _GrowableList.
    Uint8List newArray = Uint8List((_arrayLength * 2) | 3);
    if (_arrayLength > 0) {
      newArray.setRange(/* start = */ 0, _arrayLength, _array);
    }
    _array = newArray;
  }
}
