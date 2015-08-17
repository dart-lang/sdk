// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import "dart:math";
import "dart:typed_data";

// Equivalent of calling FATAL from C++ code.
_fatal(msg) native "DartCore_fatal";

// The members of this class are cloned and added to each class that
// represents an enum type.
class _EnumHelper {
  // Declare the list of enum value names private. When this field is
  // cloned into a user-defined enum class, the field will be inaccessible
  // because of the library-specific name suffix. The toString() function
  // below can access it because it uses the same name suffix.
  static const List<String> _enum_names = null;
  String toString() => _enum_names[index];
  int get hashCode => _enum_names[index].hashCode;
}

// _SyncIterable and _syncIterator are used by the compiler to
// implement sync* generator functions. A sync* generator allocates
// and returns a new _SyncIterable object.

typedef bool SyncGeneratorCallback(Iterator iterator);

class _SyncIterable extends IterableBase {
  // moveNextFn is the closurized body of the generator function.
  final SyncGeneratorCallback moveNextFn;

  const _SyncIterable(this.moveNextFn);

  get iterator {
    return new _SyncIterator(moveNextFn._clone());
  }
}

class _SyncIterator implements Iterator {
  bool isYieldEach;  // Set by generated code for the yield* statement.
  Iterator yieldEachIterator;
  var current;  // Set by generated code for the yield and yield* statement.
  SyncGeneratorCallback moveNextFn;

  _SyncIterator(this.moveNextFn);

  bool moveNext() {
    if (moveNextFn == null) {
      return false;
    }
    while(true) {
      if (yieldEachIterator != null) {
        if (yieldEachIterator.moveNext()) {
          current = yieldEachIterator.current;
          return true;
        }
        yieldEachIterator = null;
      }
      isYieldEach = false;
      if (!moveNextFn(this)) {
        moveNextFn = null;
        current = null;
        return false;
      }
      if (isYieldEach) {
        // Spec mandates: it is a dynamic error if the class of [the object
        // returned by yield*] does not implement Iterable.
        yieldEachIterator = (current as Iterable).iterator;
        continue;
      }
      return true;
    }
  }
}
