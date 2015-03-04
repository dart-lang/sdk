part of dart.async;
 _invokeErrorHandler(Function errorHandler, Object error, StackTrace stackTrace) {
  if (errorHandler is ZoneBinaryCallback) {
    return errorHandler(error, stackTrace);
    }
   else {
    return errorHandler(error);
    }
  }
 Function _registerErrorHandler(Function errorHandler, Zone zone) {
  if (errorHandler is ZoneBinaryCallback) {
    return zone.registerBinaryCallback(errorHandler);
    }
   else {
    return zone.registerUnaryCallback(DEVC$RT.cast(errorHandler, Function, __t0, "CastGeneral", """line 20, column 39 of dart:async/async_error.dart: """, errorHandler is __t0, false));
    }
  }
 class _UncaughtAsyncError extends AsyncError {_UncaughtAsyncError(error, StackTrace stackTrace) : super(error, _getBestStackTrace(error, stackTrace));
 static StackTrace _getBestStackTrace(error, StackTrace stackTrace) {
  if (stackTrace != null) return stackTrace;
   if (error is Error) {
    return DEVC$RT.cast(error.stackTrace, dynamic, StackTrace, "CastGeneral", """line 31, column 14 of dart:async/async_error.dart: """, error.stackTrace is StackTrace, true);
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
 typedef dynamic __t0(dynamic __u1);
