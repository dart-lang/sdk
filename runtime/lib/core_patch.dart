// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import "dart:async";
import 'dart:convert' show ASCII, JSON;
import "dart:isolate";
import "dart:math";
import "dart:typed_data";
import 'dart:_internal' as internal;

// The members of this class are cloned and added to each class that
// represents an enum type.
class _EnumHelper {
  String _name;
  String toString() => _name;
  int get hashCode => _name.hashCode;
}

// _SyncIterable and _syncIterator are used by the compiler to
// implement sync* generator functions. A sync* generator allocates
// and returns a new _SyncIterable object.

typedef bool _SyncGeneratorCallback(Iterator iterator);

class _SyncIterable extends IterableBase {
  // _moveNextFn is the closurized body of the generator function.
  final _SyncGeneratorCallback _moveNextFn;

  const _SyncIterable(this._moveNextFn);

  get iterator {
    return new _SyncIterator(_moveNextFn._clone());
  }
}

class _SyncIterator implements Iterator {
  bool isYieldEach; // Set by generated code for the yield* statement.
  Iterator yieldEachIterator;
  var _current; // Set by generated code for the yield and yield* statement.
  _SyncGeneratorCallback _moveNextFn;

  get current =>
      yieldEachIterator != null ? yieldEachIterator.current : _current;

  _SyncIterator(this._moveNextFn);

  bool moveNext() {
    if (_moveNextFn == null) {
      return false;
    }
    while (true) {
      if (yieldEachIterator != null) {
        if (yieldEachIterator.moveNext()) {
          return true;
        }
        yieldEachIterator = null;
      }
      isYieldEach = false;
      // _moveNextFn() will update the values of isYieldEach and _current.
      if (!_moveNextFn(this)) {
        _moveNextFn = null;
        _current = null;
        return false;
      }
      if (isYieldEach) {
        // Spec mandates: it is a dynamic error if the class of [the object
        // returned by yield*] does not implement Iterable.
        yieldEachIterator = (_current as Iterable).iterator;
        _current = null;
        continue;
      }
      return true;
    }
  }
}

@patch
class StackTrace {
  @patch
  static StackTrace get current native "StackTrace_current";
}
