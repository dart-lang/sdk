// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Iterator for lists with fixed size.
class _FixedSizeListIterator<T> extends _VariableSizeListIterator<T> {
  _FixedSizeListIterator(List<T> list)
      : super(list),
        _length = list.length;

  bool hasNext() => _length > _pos;

  final int _length;  // Cache list length for faster access.
}

// Iterator for lists with variable size.
class _VariableSizeListIterator<T> implements Iterator<T> {
  _VariableSizeListIterator(List<T> list)
      : _list = list,
        _pos = 0;

  bool hasNext() => _list.length > _pos;

  T next() {
    if (!hasNext()) {
      throw const NoMoreElementsException();
    }
    return _list[_pos++];
  }

  final List<T> _list;
  int _pos;
}
