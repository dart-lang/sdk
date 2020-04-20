// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/// Interact with developer tools such as the debugger and inspector.
///
/// This library is platform dependent and has separate implementations for
/// both web and the Dart VM. A specific platform may not support all
/// operations.
///
/// To use this library in your code:
///
///     import 'dart:developer';
///
/// {@category Core}
library dart.developer;

import 'dart:async';
import 'dart:convert';
import 'dart:isolate' show Isolate, RawReceivePort, SendPort;

part 'extension.dart';
part 'profiler.dart';
part 'service.dart';
part 'timeline.dart';

/// If [when] is true, stop the program as if a breakpoint were hit at the
/// following statement.
///
/// Returns the value of [when]. Some debuggers may display [message].
///
/// NOTE: When invoked, the isolate will not return until a debugger
/// continues execution. When running in the Dart VM, the behaviour is the same
/// regardless of whether or not a debugger is connected. When compiled to
/// JavaScript, this uses the "debugger" statement, and behaves exactly as
/// that does.
external bool debugger({bool when = true, String? message});

/// Send a reference to [object] to any attached debuggers.
///
/// Debuggers may open an inspector on the object. Returns the argument.
external Object? inspect(Object? object);

/// Emit a log event.
///
/// This function was designed to map closely to the logging information
/// collected by `package:logging`.
///
/// - [message] is the log message
/// - [time] (optional) is the timestamp
/// - [sequenceNumber] (optional) is a monotonically increasing sequence number
/// - [level] (optional) is the severity level (a value between 0 and 2000); see
///   the `package:logging` `Level` class for an overview of the possible values
/// - [name] (optional) is the name of the source of the log message
/// - [zone] (optional) the zone where the log was emitted
/// - [error] (optional) an error object associated with this log event
/// - [stackTrace] (optional) a stack trace associated with this log event
external void log(
  String message, {
  DateTime? time,
  int? sequenceNumber,
  int level = 0,
  String name = '',
  Zone? zone,
  Object? error,
  StackTrace? stackTrace,
});
