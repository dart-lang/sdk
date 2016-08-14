// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of dart.async;

_invokeErrorHandler(Function errorHandler,
                    Object error, StackTrace stackTrace) {
  if (errorHandler is ZoneBinaryCallback) {
    return errorHandler(error, stackTrace);
  } else {
    ZoneUnaryCallback unaryErrorHandler = errorHandler;
    return unaryErrorHandler(error);
  }
}

Function _registerErrorHandler/*<R>*/(Function errorHandler, Zone zone) {
  if (errorHandler is ZoneBinaryCallback) {
    return zone.registerBinaryCallback/*<R, dynamic, StackTrace>*/(
        errorHandler as dynamic/*=ZoneBinaryCallback<R, dynamic, StackTrace>*/);
  } else {
    return zone.registerUnaryCallback/*<R, dynamic>*/(
        errorHandler as dynamic/*=ZoneUnaryCallback<R, dynamic>*/);
  }
}

class _UncaughtAsyncError extends AsyncError {
  _UncaughtAsyncError(error, StackTrace stackTrace)
      : super(error, _getBestStackTrace(error, stackTrace));

  static StackTrace _getBestStackTrace(error, StackTrace stackTrace) {
    if (stackTrace != null) return stackTrace;
    if (error is Error) {
      return error.stackTrace;
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
