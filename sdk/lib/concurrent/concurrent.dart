// Copyright (c) 2024, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/// Classes that help implementing synchronized, concurrently-safe code.
///
/// {@category Core}
/// {@nodoc}
library dart.concurrent;

/// A *mutex* synchronization primitive.
///
/// Mutex can be used to synchronize access to a native resource shared between
/// multiple threads.
///
/// Mutex objects are owned by an isolate which created them.
abstract interface class Mutex {
  factory Mutex() => Mutex._();

  external factory Mutex._();

  /// Acquire exclusive ownership of this mutex.
  ///
  /// If this mutex is already acquired then an attempt to acquire it
  /// blocks the current thread until the mutex is released by the
  /// current owner.
  ///
  /// **Warning**: attempting to hold a mutex across asynchronous suspension
  /// points will lead to undefined behavior and potentially crashes.
  external void _lock();

  /// Release exclusive ownership of this mutex.
  ///
  /// It is an error to release ownership of the mutex if it was not
  /// previously acquired.
  external void _unlock();

  /// Run the given synchronous `action` under a mutex.
  ///
  /// This function takes exclusive ownership of the mutex, executes `action`
  /// and then releases the mutex. It returns the value returned by `action`.
  ///
  /// **Warning**: you can't combine `runLocked` with an asynchronous code.
  R runLocked<R>(R Function() action);
}

/// A *condition variable* synchronization primitive.
///
/// Condition variable can be used to synchronously wait for a condition to
/// occur.
///
/// [ConditionVariable] objects are owned by an isolate which created them.
abstract interface class ConditionVariable {
  factory ConditionVariable() => ConditionVariable._();

  external factory ConditionVariable._();

  /// Block and wait until another thread calls [notify].
  ///
  /// `mutex` must be a [Mutex] object exclusively held by the current thread.
  /// It will be released and the thread will block until another thread
  /// calls [notify].
  external void wait(Mutex mutex);

  /// Wake up at least one thread waiting on this condition variable.
  external void notify();
}
