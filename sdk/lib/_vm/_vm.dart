// Copyright (c) 2025, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library dart._vm;

import "dart:_internal" show unsafeCast;
import "dart:ffi" show Handle, Native;
import "dart:isolate" show Isolate, SendPort;

@pragma("vm:deeply-immutable")
@pragma('vm:entry-point')
final class ThreadLocal<T> {
  /// Creates dart thread local variable.
  ThreadLocal() : _id = _allocateId();

  /// Returns the value of this thread-local variable or throws [StateError]
  /// if it has no value.
  T get value {
    if (!_hasValue(_id)) {
      throw StateError(
        "Attempt to access variable that was not assigned a value.",
      );
    }
    return unsafeCast<T>(_getValue(_id));
  }

  /// Sets the value of this variable. Overwrites old value if it was previously
  /// set.
  set value(T newValue) {
    _setValue(_id, newValue);
  }

  /// Returns `true` if some value was assigned to this variable.
  bool get hasValue => _hasValue(_id);

  // Clears this variable of its assigned value.
  void clearValue() {
    _clearValue(_id);
  }

  @pragma("vm:external-name", "ThreadLocal_allocateId")
  external static int _allocateId();

  @pragma("vm:recognized", "graph-intrinsic")
  @pragma("vm:external-name", "ThreadLocal_hasValue")
  external static bool _hasValue(int id);

  @pragma("vm:recognized", "graph-intrinsic")
  @pragma("vm:external-name", "ThreadLocal_getValue")
  external static Object? _getValue(int id);

  @pragma("vm:external-name", "ThreadLocal_setValue")
  external static void _setValue(int id, Object? value);

  @pragma("vm:external-name", "ThreadLocal_clearValue")
  external static void _clearValue(int id);

  final int _id;
}

@pragma("vm:deeply-immutable")
@pragma('vm:entry-point')
final class ScopedThreadLocal<T> {
  /// Creates scoped thread-local variable with given [initializer] function.
  ///
  /// [initializer] must be trivially shareable.
  ScopedThreadLocal([this._initializer]);

  /// Execute [f] binding this [ScopedThreadLocal] to the given
  /// [value] for the duration of the execution.
  R runWith<R>(T newValue, R Function(T) f) {
    bool hadValue = variable.hasValue;
    T? previousValue = hadValue ? variable.value : null;
    variable.value = newValue;
    R result = f(newValue);
    if (hadValue) {
      variable.value = previousValue as T;
    } else {
      variable.clearValue();
    }
    return result;
  }

  /// Execute [f] initializing this [ScopedThreadLocal] using default initializer if needed.
  /// Throws [StateError] if this [ScopedThreadLocal] does not have an initializer.
  R runInitialized<R>(R Function(T) f) {
    bool hadValue = variable.hasValue;
    T? previousValue = hadValue ? variable.value : null;
    if (!variable.hasValue) {
      if (_initializer == null) {
        throw StateError(
          "No initializer was provided for this ScopedThreadLocal.",
        );
      }
      variable.value = _initializer!();
    }
    R result = f(variable.value);
    if (hadValue) {
      variable.value = previousValue as T;
    } else {
      variable.clearValue();
    }
    return result;
  }

  /// Returns the value specified by the closest enclosing invocation of
  /// [runWith] or [runInititalized] or throws [StateError] if this
  /// [ScopedThreadLocal] is not bound to a value.
  T get value => variable.value;

  /// Returns `true` if this [ScopedThreadLocal] is bound to a value.
  bool get isBound => variable.hasValue;
  final T Function()? _initializer;

  final variable = ThreadLocal<T>();
}

@pragma("vm:deeply-immutable")
@pragma('vm:entry-point')
final class FinalThreadLocal<T> {
  /// Creates thread local value with the given [initializer] function.
  ///
  /// The value can be assigned only once, remains assigned for the duration
  /// of this dart thread lifetime.
  ///
  /// [initializer] must be trivially shareable.
  FinalThreadLocal(this._initializer);

  /// Returns the value bound to [FinalThreadLocal].
  T get value {
    if (!variable.hasValue) {
      final v = _initializer();
      variable.value = v;
      return v;
    }
    return unsafeCast<T>(ThreadLocal._getValue(variable._id));
  }

  set value(_) {
    throw StateError("Final value can not be updated");
  }

  final T Function() _initializer;

  final variable = ThreadLocal<T>();
}

/// Should be moved to dart:isolate when --experimental-shared-data
/// flag is removed.
abstract interface class IsolateGroup {
  @Native<Handle Function(Handle)>(symbol: "IsolateGroup_runSync")
  external static Object? _runSync(Object computation);

  /// Runs [computation] in isolate-group bound context.
  static R runSync<R>(R computation()) => _runSync(computation) as R;
}

extension IsolateExperimental on Isolate {
  @pragma("vm:external-name", "Isolate_runSync_")
  external static R _runSync<R>(SendPort controlPort, R Function() f);

  /// Execute the given function in the context of the given isolate.
  ///
  /// This function will throw if target isolate is running.
  ///
  /// Throws an error if target isolate is pinned to another thread and
  /// thus can't be entered from this thread. See [pinToCurrentThread] and
  /// [isPinnedToCurrentThread].
  ///
  /// Throws an error if the target isolate belongs to another isolate group.
  ///
  /// Throws an error if [f] is not deeply immutable.
  ///
  /// Throws an error if result returned by [f] is not deeply immutable.
  R runSync<R>(R Function() f) {
    return IsolateExperimental._runSync(controlPort, f);
  }

  @pragma("vm:external-name", "Isolate_create_")
  external static List _create(String? debugName);

  /// Create a new isolate in the current isolate group.
  ///
  /// Similar to `Dart_CreateIsolateInGroup` Dart VM C API.
  ///
  /// The isolate has been created, but its event loop is not running.
  ///
  /// To start processing isolate's messages:
  ///
  /// * start isolate's event loop synchronously on the current thread
  ///   by calling [Isolate.runEventLoopSync]
  /// * integrate isolate's event loop with an external event loop by
  ///   registering event callback ([Isolate.onEvent]) to forward
  ///   event notifications to an external event loop and then draining
  ///   pending events ([Isolate.handleEvent]) from that event loop.
  static Isolate create({String? debugName}) {
    final List created = IsolateExperimental._create(debugName);
    final SendPort controlPort = created[0];
    final List capabilities = created[1];
    return Isolate(
      controlPort,
      pauseCapability: capabilities[0],
      terminateCapability: capabilities[1],
    );
  }

  @pragma("vm:external-name", "Isolate_shutdownSync_")
  external static void _shutdownSync(SendPort controlPort);

  /// Shut down target isolate.
  ///
  /// Shutting down the isolate stops its event loop without processing
  /// any pending messages and closes all open receive ports owned by the
  /// isolate.
  ///
  /// This function will block until it acquires exclusive access to the
  /// target isolate. Isolate can only be entered for synchronous execution
  /// between turns of its event loop, when no other thread is
  /// executing code in the target isolate.
  void shutdownSync() {
    return IsolateExperimental._shutdownSync(controlPort);
  }

  @pragma("vm:external-name", "Isolate_pinToCurrentThread")
  external static bool _pinToCurrentThread();

  /// Pin current isolate to the current OS thread.
  ///
  /// Once an isolate is pinned to an OS thread it cannot be
  /// entered by any other OS thread. An attempt to acquire
  /// exclusive access to it from another thread will fail with
  /// an error.
  ///
  /// Equivalent to `Dart_SetCurrentThreadOwnsIsolate` Dart VM C API.
  ///
  /// Returns `true` on success and `false` otherwise (e.g. if target isolate
  /// is already pinned to another thread).
  static bool pinToCurrentThread() {
    return IsolateExperimental._pinToCurrentThread();
  }

  @pragma("vm:external-name", "Isolate_isPinnedToCurrentThread")
  external static bool _isPinnedToCurrentThread(SendPort controlPort);

  /// Whether the isolate is pinned to the current OS thread.
  ///
  /// Equivalent to `Dart_GetCurrentThreadOwnsIsolate` Dart VM C API.
  bool get isPinnedToCurrentThread {
    return IsolateExperimental._isPinnedToCurrentThread(controlPort);
  }

  @pragma("vm:external-name", "Isolate_runEventLoopSync_")
  external static void _runEventLoopSync(SendPort controlPort);

  /// Run event loop for the target isolate synchronously on the current thread.
  ///
  /// This function will block until it acquires exclusive access to the
  /// target isolate. Isolate can only be entered for synchronous execution
  /// between turns of its event loop, when no other thread is
  /// executing code in the target isolate.
  ///
  /// This function will return once the isolate has no open keep-alive
  /// receive ports.
  ///
  /// The isolate will be marked as pinned to the current thread.
  ///
  /// Similar to `Dart_RunLoop` Dart VM C API, but unlike `Dart_RunLoop` this
  /// function executes isolate's event loop on the current thread instead
  /// of delegating it into the thread-pool.
  ///
  /// Throws an error if target isolate is pinned to another thread or already
  /// has an event loop running.
  void runEventLoopSync() {
    IsolateExperimental._runEventLoopSync(controlPort);
  }

  /// Event notify callback for the isolate.
  ///
  /// Provided callback will be called once for every new event which isolate
  /// needs to react to. Pending events can be then later be drained
  /// by calling [Isolate.handleEvent].
  ///
  /// Provided [callback] must be deeply immutable and will be called
  /// on an arbitrary thread and not necessarily within any isolate. See
  /// [NativeCallable.isolateGroupBound].
  ///
  /// IMPORTANT: [Isolate.handleEvent] *MUST NOT* be called from the
  /// `callback` as this will cause a dead-locks of the Dart execution
  /// environment.
  ///
  /// Similar to `Dart_SetMessageNotifyCallback` Dart VM C API.
  void set onEvent(void Function(Isolate) callback) {
    throw UnsupportedError("Isolate.onEvent");
  }

  /// Handle at most one pending event for the isolate.
  ///
  /// This function does nothing if there are no pending events.
  ///
  /// This function will block until it acquires exclusive access to the
  /// target isolate. Isolate can only be entered for synchronous execution
  /// between turns of its event loop, when no other thread is
  /// executing code in the target isolate.
  ///
  /// Similar to `Dart_HandleMessage` Dart VM C API.
  void handleEvent() {
    throw UnsupportedError("Isolate.handleEvent");
  }
}
