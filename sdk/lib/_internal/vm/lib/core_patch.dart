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
        allocateOneByteString,
        allocateTwoByteString,
        ClassID,
        CodeUnits,
        copyRangeFromUint8ListToOneByteString,
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
        patch,
        unsafeCast,
        writeIntoOneByteString,
        writeIntoTwoByteString;

import "dart:async" show Completer, Future, Timer;

import "dart:collection"
    show
        HashMap,
        IterableBase,
        LinkedHashMap,
        LinkedList,
        LinkedListEntry,
        ListBase,
        MapBase,
        Maps,
        UnmodifiableMapBase,
        UnmodifiableMapView;

import "dart:convert" show ascii, Encoding, json, latin1, utf8;

import "dart:isolate" show Isolate;

import "dart:math" show Random;

import "dart:typed_data"
    show Endian, Uint8List, Int64List, Uint16List, Uint32List;

/// These are the additional parts of this patch library:
// part "array.dart";
// part "array_patch.dart";
// part "bigint_patch.dart";
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
}

// _SyncIterable and _syncIterator are used by the compiler to
// implement sync* generator functions. A sync* generator allocates
// and returns a new _SyncIterable object.

typedef _SyncGeneratorCallback<T> = bool Function(_SyncIterator<T>);
typedef _SyncGeneratorCallbackCallback<T> = _SyncGeneratorCallback<T>
    Function();

class _SyncIterable<T> extends IterableBase<T> {
  // Closure that effectively "clones" the inner _moveNextFn.
  // This means a _SyncIterable creates _SyncIterators that do not share state.
  final _SyncGeneratorCallbackCallback<T> _moveNextFnMaker;

  const _SyncIterable(this._moveNextFnMaker);

  Iterator<T> get iterator {
    return _SyncIterator<T>(_moveNextFnMaker());
  }
}

class _SyncIterator<T> implements Iterator<T> {
  _SyncGeneratorCallback<T>? _moveNextFn;
  Iterator<T>? _yieldEachIterator;

  // Stack of suspended _moveNextFn.
  List<_SyncGeneratorCallback<T>>? _stack;

  // These two fields are set by generated code for the yield and yield*
  // statement.
  T? _current;
  Iterable<T>? _yieldEachIterable;

  @override
  T get current {
    final iterator = _yieldEachIterator;
    if (iterator != null) {
      return iterator.current;
    } else {
      final cur = _current;
      return (cur != null) ? cur : cur as T;
    }
  }

  _SyncIterator(this._moveNextFn);

  @override
  bool moveNext() {
    if (_moveNextFn == null) {
      return false;
    }

    while (true) {
      // If the active iterator isn't a nested _SyncIterator, we have to
      // delegate downwards from the immediate iterator.
      final iterator = _yieldEachIterator;
      if (iterator != null) {
        if (iterator.moveNext()) {
          return true;
        }
        _yieldEachIterator = null;
      }

      final stack = _stack;
      if (!_moveNextFn!.call(this)) {
        _moveNextFn = null;
        _current = null;
        // If we have any suspended parent generators, continue next one up:
        if (stack != null && stack.isNotEmpty) {
          _moveNextFn = stack.removeLast();
          continue;
        }
        return false;
      }

      final iterable = _yieldEachIterable;
      if (iterable != null) {
        if (iterable is _SyncIterable) {
          // We got a recursive yield* of sync* function. Instead of creating
          // a new iterator we replace our _moveNextFn (remembering the
          // current _moveNextFn for later resumption).
          if (stack == null) {
            _stack = [];
          }
          _stack!.add(_moveNextFn!);
          final typedIterable = unsafeCast<_SyncIterable<T>>(iterable);
          _moveNextFn = typedIterable._moveNextFnMaker();
        } else {
          _yieldEachIterator = iterable.iterator;
        }
        _yieldEachIterable = null;
        _current = null;

        // Fetch the next item.
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
