This library provides the ability to parse, inspect, and manipulate stack traces
produced by the underlying Dart implementation. It also provides functions to
produce string representations of stack traces in a more readable format than
the native [StackTrace] implementation.

`Trace`s can be parsed from native [StackTrace]s using `Trace.from`, or captured
using `Trace.current`. Native [StackTrace]s can also be directly converted to
human-readable strings using `Trace.format`.

[StackTrace]: http://api.dartlang.org/docs/releases/latest/dart_core/StackTrace.html

Here's an example native stack trace from debugging this library:

    #0      Object.noSuchMethod (dart:core-patch:1884:25)
    #1      Trace.terse.<anonymous closure> (file:///usr/local/google-old/home/goog/dart/dart/pkg/stack_trace/lib/src/trace.dart:47:21)
    #2      IterableMixinWorkaround.reduce (dart:collection:29:29)
    #3      List.reduce (dart:core-patch:1247:42)
    #4      Trace.terse (file:///usr/local/google-old/home/goog/dart/dart/pkg/stack_trace/lib/src/trace.dart:40:35)
    #5      format (file:///usr/local/google-old/home/goog/dart/dart/pkg/stack_trace/lib/stack_trace.dart:24:28)
    #6      main.<anonymous closure> (file:///usr/local/google-old/home/goog/dart/dart/test.dart:21:29)
    #7      _CatchErrorFuture._sendError (dart:async:525:24)
    #8      _FutureImpl._setErrorWithoutAsyncTrace (dart:async:393:26)
    #9      _FutureImpl._setError (dart:async:378:31)
    #10     _ThenFuture._sendValue (dart:async:490:16)
    #11     _FutureImpl._handleValue.<anonymous closure> (dart:async:349:28)
    #12     Timer.run.<anonymous closure> (dart:async:2402:21)
    #13     Timer.Timer.<anonymous closure> (dart:async-patch:15:15)

and its human-readable representation:

    dart:core-patch                             Object.noSuchMethod
    pkg/stack_trace/lib/src/trace.dart 47:21    Trace.terse.<fn>
    dart:collection                             IterableMixinWorkaround.reduce
    dart:core-patch                             List.reduce
    pkg/stack_trace/lib/src/trace.dart 40:35    Trace.terse
    pkg/stack_trace/lib/stack_trace.dart 24:28  format
    test.dart 21:29                             main.<fn>
    dart:async                                  _CatchErrorFuture._sendError
    dart:async                                  _FutureImpl._setErrorWithoutAsyncTrace
    dart:async                                  _FutureImpl._setError
    dart:async                                  _ThenFuture._sendValue
    dart:async                                  _FutureImpl._handleValue.<fn>
    dart:async                                  Timer.run.<fn>
    dart:async-patch                            Timer.Timer.<fn>

You can further clean up the stack trace using `Trace.terse`. This folds
together multiple stack frames from the Dart core libraries, so that only the
core library method that was directly called from user code is visible. For
example:

    dart:core                                   Object.noSuchMethod
    pkg/stack_trace/lib/src/trace.dart 47:21    Trace.terse.<fn>
    dart:core                                   List.reduce
    pkg/stack_trace/lib/src/trace.dart 40:35    Trace.terse
    pkg/stack_trace/lib/stack_trace.dart 24:28  format
    test.dart 21:29                             main.<fn>
    dart:async                                  Timer.Timer.<fn>
