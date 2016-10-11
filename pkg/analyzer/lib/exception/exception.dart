// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library analyzer.exception.exception;

/**
 * An exception that occurred during the analysis of one or more sources.
 */
class AnalysisException implements Exception {
  /**
   * The message that explains why the exception occurred.
   */
  final String message;

  /**
   * The exception that caused this exception, or `null` if this exception was
   * not caused by another exception.
   */
  final CaughtException cause;

  /**
   * Initialize a newly created exception to have the given [message] and
   * [cause].
   */
  AnalysisException([this.message = 'Exception', this.cause = null]);

  String toString() {
    StringBuffer buffer = new StringBuffer();
    buffer.write("AnalysisException: ");
    buffer.writeln(message);
    if (cause != null) {
      buffer.write('Caused by ');
      cause._writeOn(buffer);
    }
    return buffer.toString();
  }
}

/**
 * An exception that was caught and has an associated stack trace.
 */
class CaughtException implements Exception {
  /**
   * The exception that was caught.
   */
  final Object exception;

  /**
   * The stack trace associated with the exception.
   */
  StackTrace stackTrace;

  /**
   * Initialize a newly created caught exception to have the given [exception]
   * and [stackTrace].
   */
  CaughtException(this.exception, stackTrace) {
    if (stackTrace == null) {
      try {
        throw this;
      } catch (_, st) {
        stackTrace = st;
      }
    }
    this.stackTrace = stackTrace;
  }

  @override
  String toString() {
    StringBuffer buffer = new StringBuffer();
    _writeOn(buffer);
    return buffer.toString();
  }

  /**
   * Write a textual representation of the caught exception and its associated
   * stack trace.
   */
  void _writeOn(StringBuffer buffer) {
    if (exception is AnalysisException) {
      AnalysisException analysisException = exception;
      buffer.writeln(analysisException.message);
      if (stackTrace != null) {
        buffer.writeln(stackTrace.toString());
      }
      CaughtException cause = analysisException.cause;
      if (cause != null) {
        buffer.write('Caused by ');
        cause._writeOn(buffer);
      }
    } else {
      buffer.writeln(exception.toString());
      if (stackTrace != null) {
        buffer.writeln(stackTrace.toString());
      }
    }
  }
}
