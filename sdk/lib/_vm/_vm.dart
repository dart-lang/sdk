// Copyright (c) 2025, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library dart._vm;

import "dart:_internal" show unsafeCast;

@pragma("vm:deeply-immutable")
@pragma('vm:entry-point')
final class ScopedThreadLocal<T> {
  /// Creates scoped thread local value with the given [initializer] function.
  ///
  /// [initializer] must be trivially shareable.
  ScopedThreadLocal([this._initializer]) : _id = _allocateId();

  /// Execute [f] binding this [ScopedThreadLocal] to the given
  /// [value] for the duration of the execution.
  R runWith<R>(T value, R Function(T) f) {
    bool hadValue = _hasValue(_id);
    Object? previous_value = hadValue ? _getValue(_id) : null;
    _setValue(_id, value);
    R result = f(value);
    if (hadValue) {
      _setValue(_id, previous_value!);
    } else {
      _clearValue(_id);
    }
    return result;
  }

  /// Execute [f] initializing this [ScopedThreadLocal] using default initializer if needed.
  /// Throws [StateError] if this [ScopedThreadLocal] does not have an initializer.
  R runInitialized<R>(R Function(T) f) {
    bool hadValue = _hasValue(_id);
    Object? previous_value = hadValue ? _getValue(_id) : null;
    late T v;
    if (!isBound) {
      if (_initializer == null) {
        throw StateError(
          "No initializer was provided for this ScopedThreadLocal.",
        );
      }
      v = _initializer!();
      _setValue(_id, v);
    } else {
      v = unsafeCast<T>(_getValue(_id));
    }
    R result = f(v);
    if (hadValue) {
      _setValue(_id, previous_value!);
    } else {
      _clearValue(_id);
    }
    return result;
  }

  /// Returns the value specified by the closest enclosing invocation of
  /// [runWith] or [runInititalized] or throws [StateError] if this
  /// [ScopedThreadLocal] is not bound to a value.
  T get value {
    if (!_hasValue(_id)) {
      throw StateError(
        "Attempt to access value that was not bound. "
        "Use runInititalized or runWith.",
      );
    }
    return unsafeCast<T>(_getValue(_id));
  }

  /// Returns `true` if this [ScopedThreadLocal] is bound to a value.
  bool get isBound => _hasValue(_id);

  @pragma("vm:external-name", "ScopedThreadLocal_allocateId")
  external static int _allocateId();

  @pragma("vm:external-name", "ScopedThreadLocal_hasValue")
  external static bool _hasValue(int id);

  @pragma("vm:external-name", "ScopedThreadLocal_getValue")
  external static Object? _getValue(int id);

  @pragma("vm:external-name", "ScopedThreadLocal_setValue")
  external static void _setValue(int id, Object? value);

  @pragma("vm:external-name", "ScopedThreadLocal_clearValue")
  external static void _clearValue(int id);

  final int _id;
  final T Function()? _initializer;
}
