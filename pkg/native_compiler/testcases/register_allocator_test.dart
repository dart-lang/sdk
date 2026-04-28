// Copyright (c) 2026, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// From dart:_internal::SystemHash.

int combine(int hash, int argalue) {
  hash = 0x1fffffff & (hash + argalue);
  hash = 0x1fffffff & (hash + ((0x0007ffff & hash) << 10));
  return hash ^ (hash >> 6);
}

int finish(int hash) {
  hash = 0x1fffffff & (hash + ((0x03ffffff & hash) << 3));
  hash = hash ^ (hash >> 11);
  return 0x1fffffff & (hash + ((0x00003fff & hash) << 15));
}

int hash19(
  int arg1,
  int arg2,
  int arg3,
  int arg4,
  int arg5,
  int arg6,
  int arg7,
  int arg8,
  int arg9,
  int arg10,
  int arg11,
  int arg12,
  int arg13,
  int arg14,
  int arg15,
  int arg16,
  int arg17,
  int arg18,
  int arg19,
  int seed,
) {
  var hash = seed;
  hash = combine(hash, arg1);
  hash = combine(hash, arg2);
  hash = combine(hash, arg3);
  hash = combine(hash, arg4);
  hash = combine(hash, arg5);
  hash = combine(hash, arg6);
  hash = combine(hash, arg7);
  hash = combine(hash, arg8);
  hash = combine(hash, arg9);
  hash = combine(hash, arg10);
  hash = combine(hash, arg11);
  hash = combine(hash, arg12);
  hash = combine(hash, arg13);
  hash = combine(hash, arg14);
  hash = combine(hash, arg15);
  hash = combine(hash, arg16);
  hash = combine(hash, arg17);
  hash = combine(hash, arg18);
  hash = combine(hash, arg19);
  return finish(hash);
}

// dart:collection::ListBase._compareAny.

int compareAny(dynamic a, dynamic b) {
  return Comparable.compare(a as Comparable, b as Comparable);
}

// dart:async

class _Future<T> {}

class BroadcastStreamController {
  _Future<void>? _doneFuture;
  _Future<void> ensureDoneFuture() => _doneFuture ??= _Future<void>();
}

abstract class _AsBroadcastStreamController<T> {
  bool get isClosed;
  void add(T data);
  StreamSubscription<T> _subscribe(
    void onData(T data)?,
    Function? onError,
    void onDone()?,
    bool cancelOnError,
  );
}

abstract class Stream<T> {
  StreamSubscription<T> listen(
    void onData(T event)?, {
    Function? onError,
    void onDone()?,
    bool? cancelOnError,
  });
}

class StreamSubscription<T> {
  StreamSubscription(void onDone()?);
}

class AsBroadcastStream<T> extends Stream<T> {
  final Stream<T> _source;
  _AsBroadcastStreamController<T>? _controller;
  StreamSubscription<T>? _subscription;

  AsBroadcastStream(this._source);

  StreamSubscription<T> listen(
    void onData(T data)?, {
    Function? onError,
    void onDone()?,
    bool? cancelOnError,
  }) {
    var controller = _controller;
    if (controller == null || controller.isClosed) {
      // Return a dummy subscription backed by nothing, since
      // it will only ever send one done event.
      return new StreamSubscription<T>(onDone);
    }
    _subscription ??= _source.listen(controller.add);
    return controller._subscribe(
      onData,
      onError,
      onDone,
      cancelOnError ?? false,
    );
  }
}

class Zone {
  static _Zone _current = _Zone();
  static _Zone _enter(_Zone zone) {
    return _current;
  }

  static void _leave(_Zone previous) {}
}

class _Zone extends Zone {}

R rootRunBinary<R, T1, T2>(
  Zone? self,
  Zone zone,
  R f(T1 arg1, T2 arg2),
  T1 arg1,
  T2 arg2,
) {
  if (identical(Zone._current, zone)) return f(arg1, arg2);

  if (zone is! _Zone) {
    throw ArgumentError.value(zone, "zone", "Can only run in platform zones");
  }

  _Zone old = Zone._enter(zone);
  try {
    return f(arg1, arg2);
  } finally {
    Zone._leave(old);
  }
}

// From dart:collection

class SplayTreeMap<K, V> {
  int Function(K, K)? compare;
  bool Function(Object?)? isValidKey;
  SplayTreeMap(this.compare, this.isValidKey);

  factory SplayTreeMap.from(
    Map<Object?, Object?> other, [
    int Function(K key1, K key2)? compare,
    bool Function(dynamic potentialKey)? isValidKey,
  ]) {
    if (other is Map<K, V>) {
      return SplayTreeMap<K, V>.of(other, compare, isValidKey);
    }
    final result = SplayTreeMap<K, V>(compare, isValidKey);
    other.forEach((dynamic k, dynamic v) {});
    return result;
  }

  factory SplayTreeMap.of(
    Map<K, V> other, [
    int Function(K key1, K key2)? compare,
    bool Function(dynamic potentialKey)? isValidKey,
  ]) => SplayTreeMap<K, V>(compare, isValidKey);
}

// dart:core::_StringBase.replaceAll

String replaceAll(String thisString, Pattern pattern, String replacement) {
  var startIndex = 0;
  // String fragments that replace the prefix [this] up to [startIndex].
  List matches = [];
  var length = 0; // Length of all fragments.
  int replacementLength = replacement.length;

  if (replacementLength == 0) {
    for (Match match in pattern.allMatches(thisString)) {
      length += _addReplaceSlice(matches, startIndex, match.start);
      startIndex = match.end;
    }
  } else {
    for (Match match in pattern.allMatches(thisString)) {
      length += _addReplaceSlice(matches, startIndex, match.start);
      matches.add(replacement);
      length += replacementLength;
      startIndex = match.end;
    }
  }
  // No match, or a zero-length match at start with zero-length replacement.
  if (startIndex == 0 && length == 0) return thisString;
  length += _addReplaceSlice(matches, startIndex, thisString.length);
  bool replacementIsOneByte = _isOneByte(replacement);
  if (replacementIsOneByte && length < 500 && _isOneByte(thisString)) {
    // TODO: Is there a cut-off point, or is runtime always faster?
    return _joinReplaceAllOneByteResult(thisString, matches, length);
  }
  return _joinReplaceAllResult(
    thisString,
    matches,
    length,
    replacementIsOneByte,
  );
}

external bool _isOneByte(String str);
external int _addReplaceSlice(List matches, int start, int end);
external String _joinReplaceAllOneByteResult(
  String base,
  List matches,
  int length,
);
external String _joinReplaceAllResult(
  String base,
  List matches,
  int length,
  bool replacementStringsAreOneByte,
);

void main() {}
