// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of dart.async;

/**
 * Error result of an asynchronous computation.
 */
class AsyncError {
  /** The actual error thrown by the computation. */
  final error;
  /** Stack trace corresponding to the error, if available. */
  final Object stackTrace;
  /** Asynchronous error leading to this error, if error handling fails. */
  final AsyncError cause;

  // TODO(lrn): When possible, combine into one constructor with both optional
  // positional and named arguments.
  AsyncError(this.error, [this.stackTrace]): cause = null;
  AsyncError.withCause(this.error, this.stackTrace, this.cause);

  void _writeOn(StringSink buffer) {
    buffer.write("'");
    String message;
    try {
      message = error.toString();
    } catch (e) {
      message = Error.safeToString(error);
    }
    buffer.write(message);
    buffer.write("'\n");
    if (stackTrace != null) {
      buffer.write("Stack trace:\n");
      buffer.writeln(stackTrace.toString());
    }
  }

  String toString() {
    StringBuffer buffer = new StringBuffer();
    buffer.write("AsyncError: ");
    _writeOn(buffer);
    AsyncError cause = this.cause;
    while (cause != null) {
      buffer.write("Caused by: ");
      cause._writeOn(buffer);
      cause = cause.cause;
    }
    return buffer.toString();
  }

  throwDelayed() {
    reportError() {
      print("Uncaught Error: $error");
      if (stackTrace != null) {
        print("Stack Trace:\n$stackTrace\n");
      }
    }

    try {
      Timer.run(() {
        reportError();
        // TODO(floitsch): we potentially want to call the global error handler
        // directly so that we can pass the stack trace.
        throw error;
      });
    } catch (e) {
      // Unfortunately there is not much more we can do...
      reportError();
    }
  }
}

