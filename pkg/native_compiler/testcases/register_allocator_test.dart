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

abstract class BroadcastStreamController {
  _Future<void>? _doneFuture;
  _Future<void> ensureDoneFuture() => _doneFuture ??= _Future<void>();

  bool get _mayAddEvent;
  Error _addEventError();
  void _addError(Object error, StackTrace stackTrace);

  void addError(Object error, [StackTrace? stackTrace]) {
    if (!_mayAddEvent) throw _addEventError();
    AsyncError(:error, :stackTrace) = _interceptUserError(error, stackTrace);
    _addError(error, stackTrace);
  }
}

final class AsyncError implements Error {
  final Object error;
  final StackTrace stackTrace;
  AsyncError(this.error, this.stackTrace);
}

external AsyncError _interceptUserError(Object error, StackTrace? stackTrace);

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

class _StreamControllerAddStreamState<T> {
  dynamic _varData;
}

class _PendingEvents<T> {}

abstract class StreamController<T> {
  Object? _varData;
  bool get _isAddingStream;

  _PendingEvents<T>? get pendingEvents {
    if (!_isAddingStream) {
      return _varData as dynamic;
    }
    _StreamControllerAddStreamState<T> state = _varData as dynamic;
    return state._varData;
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

// dart:convert::_ChunkedJsonParser

abstract class ChunkedJsonParser {
  static const int MINUS = 0x2d;
  static const int DECIMALPOINT = 0x2e;
  static const int CHAR_0 = 0x30;
  static const int CHAR_9 = 0x39;
  static const int CHAR_e = 0x65;
  static const int NUM_SIGN = 0; // After initial '-'.
  static const int NUM_ZERO = 4; // After '0' as first digit.
  static const int NUM_DIGIT = 8; // After digit, no '.' or 'e' seen.
  static const int NUM_DOT = 12; // After '.'.
  static const int NUM_DOT_DIGIT = 16; // After a decimal digit (after '.').
  static const int NUM_E = 20; // After 'e' or 'E'.
  static const int NUM_E_SIGN = 24; // After '-' or '+' after 'e' or 'E'.
  static const int NUM_E_DIGIT = 28; // After exponent digit.
  static const int NUM_SUCCESS = 32; // Never stored as partial state.
  static const POWERS_OF_TEN = [];

  int parseNumber(int char, int position) {
    // Also called on any unexpected character.
    // Format:
    //  '-'?('0'|[1-9][0-9]*)('.'[0-9]+)?([eE][+-]?[0-9]+)?
    var start = position;
    int length = chunkEnd;
    // Collects an int value while parsing. Used for both an integer literal,
    // and the exponent part of a double literal.
    // Stored as negative to ensure we can represent -2^63.
    var intValue = 0;
    var doubleValue = 0.0; // Collect double value while parsing.
    // 1 if there is no leading -, -1 if there is.
    var sign = 1;
    var isDouble = false;
    // Break this block when the end of the number literal is reached.
    // At that time, position points to the next character, and isDouble
    // is set if the literal contains a decimal point or an exponential.
    if (char == MINUS) {
      sign = -1;
      position++;
      if (position == length) return beginChunkNumber(NUM_SIGN, start);
      char = _getCharUnsafe(position);
    }
    int digit = char ^ CHAR_0;
    if (digit > 9) {
      if (sign < 0) {
        fail(position, "Missing expected digit");
      } else {
        // If it doesn't even start out as a numeral.
        fail(position);
      }
    }
    if (digit == 0) {
      position++;
      if (position == length) return beginChunkNumber(NUM_ZERO, start);
      char = _getCharUnsafe(position);
      digit = char ^ CHAR_0;
      // If starting with zero, next character must not be digit.
      if (digit <= 9) fail(position);
    } else {
      var digitCount = 0;
      do {
        if (digitCount >= 18) {
          // Check for overflow.
          // Is 1 if digit is 8 or 9 and sign == 0, or digit is 9 and sign < 0;
          int highDigit = digit >> 3;
          if (sign < 0) highDigit &= digit;
          if (digitCount == 19 || intValue - highDigit < -922337203685477580) {
            isDouble = true;
            // Big value that we know is not trusted to be exact later,
            // forcing reparsing using `double.parse`.
            doubleValue = 9223372036854775808.0;
          }
        }
        intValue = 10 * intValue - digit;
        digitCount++;
        position++;
        if (position == length) return beginChunkNumber(NUM_DIGIT, start);
        char = _getCharUnsafe(position);
        digit = char ^ CHAR_0;
      } while (digit <= 9);
    }
    if (char == DECIMALPOINT) {
      if (!isDouble) {
        isDouble = true;
        doubleValue = (intValue == 0) ? 0.0 : -intValue.toDouble();
      }
      intValue = 0;
      position++;
      if (position == length) return beginChunkNumber(NUM_DOT, start);
      char = _getCharUnsafe(position);
      digit = char ^ CHAR_0;
      if (digit > 9) fail(position);
      do {
        doubleValue = 10.0 * doubleValue + digit;
        intValue -= 1;
        position++;
        if (position == length) return beginChunkNumber(NUM_DOT_DIGIT, start);
        char = _getCharUnsafe(position);
        digit = char ^ CHAR_0;
      } while (digit <= 9);
    }
    if ((char | 0x20) == CHAR_e) {
      if (!isDouble) {
        isDouble = true;
        doubleValue = (intValue == 0) ? 0.0 : -intValue.toDouble();
        intValue = 0;
      }
      position++;
      if (position == length) return beginChunkNumber(NUM_E, start);
      char = _getCharUnsafe(position);
      var expSign = 1;
      var exponent = 0;
      if (((char + 1) | 2) == 0x2e /*+ or -*/ ) {
        expSign = 0x2C - char; // -1 for MINUS, +1 for PLUS
        position++;
        if (position == length) return beginChunkNumber(NUM_E_SIGN, start);
        char = _getCharUnsafe(position);
      }
      digit = char ^ CHAR_0;
      if (digit > 9) {
        fail(position, "Missing expected digit");
      }
      var exponentOverflow = false;
      do {
        exponent = 10 * exponent + digit;
        if (exponent > 400) exponentOverflow = true;
        position++;
        if (position == length) return beginChunkNumber(NUM_E_DIGIT, start);
        char = _getCharUnsafe(position);
        digit = char ^ CHAR_0;
      } while (digit <= 9);
      if (exponentOverflow) {
        if (doubleValue == 0.0 || expSign < 0) {
          listener.handleNumber(sign < 0 ? -0.0 : 0.0);
        } else {
          listener.handleNumber(
            sign < 0 ? double.negativeInfinity : double.infinity,
          );
        }
        return position;
      }
      intValue += expSign * exponent;
    }
    if (!isDouble) {
      int bitFlag = -(sign + 1) >> 1; // 0 if sign == -1, -1 if sign == 1
      // Negate if bitFlag is -1 by doing ~intValue + 1
      listener.handleNumber((intValue ^ bitFlag) - bitFlag);
      return position;
    }
    // Double values at or above this value (2 ** 53) may have lost precision.
    // Only trust results that are below this value.
    const maxExactDouble = 9007199254740992.0;
    if (doubleValue < maxExactDouble) {
      var exponent = intValue;
      double signedMantissa = doubleValue * sign;
      if (exponent >= -22) {
        if (exponent < 0) {
          listener.handleNumber(signedMantissa / POWERS_OF_TEN[-exponent]);
          return position;
        }
        if (exponent == 0) {
          listener.handleNumber(signedMantissa);
          return position;
        }
        if (exponent <= 22) {
          listener.handleNumber(signedMantissa * POWERS_OF_TEN[exponent]);
          return position;
        }
      }
    }
    // If the value is outside the range +/-maxExactDouble or
    // exponent is outside the range +/-22, then we can't trust simple double
    // arithmetic to get the exact result, so we use the system double parsing.
    listener.handleNumber(parseDouble(start, position));
    return position;
  }

  dynamic get listener;
  int get chunkEnd;
  int beginChunkNumber(int state, int start);
  int _getCharUnsafe(int position);
  Never fail(int position, [String? message]);
  double parseDouble(int start, int end);
}

void main() {}
