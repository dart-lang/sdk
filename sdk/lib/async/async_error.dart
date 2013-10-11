// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of dart.async;

final Expando _stackTraceExpando = new Expando("asynchronous error");

void _attachStackTrace(o, st) {
  if (o == null || o is bool || o is num || o is String) return;
  _stackTraceExpando[o] = st;
}

_invokeErrorHandler(Function errorHandler,
                    Object error, StackTrace stackTrace) {
  if (errorHandler is ZoneBinaryCallback) {
    return errorHandler(error, stackTrace);
  } else {
    return errorHandler(error);
  }
}

Function _registerErrorHandler(Function errorHandler, Zone zone) {
  if (errorHandler is ZoneBinaryCallback) {
    return zone.registerBinaryCallback(errorHandler);
  } else {
    return zone.registerUnaryCallback(errorHandler);
  }
}

/**
 * *This is an experimental API.*
 *
 * Get the [StackTrace] attached to [o].
 *
 * If object [o] was thrown and caught in a dart:async method, a [StackTrace]
 * object was attached to it. Use [getAttachedStackTrace] to get that object.
 *
 * Returns [null] if no [StackTrace] was attached.
 */
getAttachedStackTrace(o) {
  if (o == null || o is bool || o is num || o is String) return null;
  return _stackTraceExpando[o];
}

class _AsyncError implements Error {
  final error;
  final StackTrace stackTrace;

  _AsyncError(this.error, this.stackTrace);
}

class _UncaughtAsyncError extends _AsyncError {
  _UncaughtAsyncError(error, StackTrace stackTrace)
      : super(error, _getBestStackTrace(error, stackTrace)) {
    // Clear the attached stack trace.
    _attachStackTrace(error, null);
  }

  static StackTrace _getBestStackTrace(error, StackTrace stackTrace) {
    if (stackTrace != null) return stackTrace;
    var trace = getAttachedStackTrace(error);
    if (trace != null) return trace;
    if (error is Error) {
      Error e = error;
      return e.stackTrace;
    }
    return null;
  }

  String toString() {
    String result = "Uncaught Error: ${error}";

    if (stackTrace != null) {
      result += "\nStack Trace:\n$stackTrace";
    }
    return result;
  }
}
