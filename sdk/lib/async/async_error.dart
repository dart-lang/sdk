// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of dart.async;

/// An error and a stack trace.
///
/// Used when an error and stack trace need to be handled as a single
/// value, for example when returned by [Zone.errorCallback].
class AsyncError implements Error {
  final Object error;
  final StackTrace stackTrace;

  AsyncError(Object error, StackTrace? stackTrace)
      : error = checkNotNullable(error, "error"),
        stackTrace = stackTrace ?? defaultStackTrace(error);

  /// A default stack trace for an error.
  ///
  /// If [error] is an [Error] and it has an [Error.stackTrace],
  /// that stack trace is returned.
  /// If not, the [StackTrace.empty] default stack trace is returned.
  static StackTrace defaultStackTrace(Object error) {
    if (error is Error) {
      var stackTrace = error.stackTrace;
      if (stackTrace != null) return stackTrace;
    }
    return StackTrace.empty;
  }

  String toString() => '$error';
}

// Helper function used by stream method implementations.
_invokeErrorHandler(
    Function errorHandler, Object error, StackTrace stackTrace) {
  var handler = errorHandler; // Rename to avoid promotion.
  if (handler is ZoneBinaryCallback<dynamic, Never, Never>) {
    // Dynamic invocation because we don't know the actual type of the
    // first argument or the error object, but we should successfully call
    // the handler if they match up.
    return errorHandler(error, stackTrace);
  } else {
    return errorHandler(error);
  }
}
