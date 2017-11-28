// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/// Note: the VM concatenates all patch files into a single patch file. This
/// file is the first patch in "dart:core" which contains all the imports
/// used by patches of that library. We plan to change this when we have a
/// shared front end and simply use parts.

import "dart:_internal" as internal show Symbol;

import "dart:_internal"
    show
        ClassID,
        CodeUnits,
        EfficientLengthIterable,
        FixedLengthListBase,
        IterableElementError,
        ListIterator,
        Lists,
        POWERS_OF_TEN,
        SubListIterable,
        UnmodifiableListBase,
        is64Bit,
        makeFixedListUnmodifiable,
        makeListFixedLength,
        patch;

import "dart:async" show Completer, Future, Timer;

import "dart:collection"
    show
        HashMap,
        IterableBase,
        LinkedHashMap,
        LinkedList,
        LinkedListEntry,
        ListBase,
        Maps,
        UnmodifiableMapView;

import "dart:convert" show ascii, Encoding, json, latin1, utf8;

import "dart:isolate" show Isolate;

import "dart:math" show Random;

import "dart:typed_data" show Uint8List, Int64List, Uint16List, Uint32List;

/// These are the additional parts of this patch library:
// part "array.dart";
// part "array_patch.dart";
// part "bigint.dart";
// part "bool_patch.dart";
// part "date_patch.dart";
// part "double.dart";
// part "double_patch.dart";
// part "errors_patch.dart";
// part "expando_patch.dart";
// part "function.dart";
// part "function_patch.dart";
// part "growable_array.dart";
// part "identical_patch.dart";
// part "immutable_map.dart";
// part "integers.dart";
// part "integers_patch.dart";
// part "invocation_mirror_patch.dart";
// part "lib_prefix.dart";
// part "map_patch.dart";
// part "null_patch.dart";
// part "object_patch.dart";
// part "regexp_patch.dart";
// part "stacktrace.dart";
// part "stopwatch_patch.dart";
// part "string_buffer_patch.dart";
// part "string_patch.dart";
// part "type_patch.dart";
// part "uri_patch.dart";
// part "weak_property.dart";

@patch
class num {
  num _addFromInteger(int other);
  num _subFromInteger(int other);
  num _mulFromInteger(int other);
  int _truncDivFromInteger(int other);
  num _moduloFromInteger(int other);
  num _remainderFromInteger(int other);
  bool _greaterThanFromInteger(int other);
  bool _equalToInteger(int other);
  num _toBigintOrDouble();
}

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

typedef bool _SyncGeneratorCallback<T>(_SyncIterator<T> iterator);

class _SyncIterable<T> extends IterableBase<T> {
  // _moveNextFn is the closurized body of the generator function.
  final _SyncGeneratorCallback<T> _moveNextFn;

  const _SyncIterable(this._moveNextFn);

  Iterator<T> get iterator {
    // Note: _Closure._clone returns _Closure which is not related to
    // _SyncGeneratorCallback, which means we need explicit cast.
    return new _SyncIterator<T>(
        (_moveNextFn as _Closure)._clone() as _SyncGeneratorCallback<T>);
  }
}

class _SyncIterator<T> implements Iterator<T> {
  _SyncGeneratorCallback<T> _moveNextFn;
  Iterator<T> _yieldEachIterator;

  // These two fields are set by generated code for the yield and yield*
  // statement.
  T _current;
  Iterable<T> _yieldEachIterable;

  T get current =>
      _yieldEachIterator != null ? _yieldEachIterator.current : _current;

  _SyncIterator(this._moveNextFn);

  bool moveNext() {
    if (_moveNextFn == null) {
      return false;
    }
    while (true) {
      if (_yieldEachIterator != null) {
        if (_yieldEachIterator.moveNext()) {
          return true;
        }
        _yieldEachIterator = null;
      }
      // _moveNextFn() will update the values of _yieldEachIterable
      //  and _current.
      if (!_moveNextFn(this)) {
        _moveNextFn = null;
        _current = null;
        return false;
      }
      if (_yieldEachIterable != null) {
        // Spec mandates: it is a dynamic error if the class of [the object
        // returned by yield*] does not implement Iterable.
        _yieldEachIterator = _yieldEachIterable.iterator;
        _yieldEachIterable = null;
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
