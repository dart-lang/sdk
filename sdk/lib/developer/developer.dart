// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/// ## Status: Unstable
///
/// The dart:developer library is unstable and its API might change slightly
/// as a result of developer feedback. This library is platform dependent and
/// therefore it has implementations for both dart2js and the Dart VM. Both are
/// under development and may not support all operations yet.
///
library dart.developer;

import 'dart:convert';

part 'profiler.dart';

/// If [when] is true, stop the program as if a breakpoint where hit at the
/// following statement. Returns the value of [when]. Some debuggers may
/// display [msg].
/// NOTE: When invoked, the isolate will not return until a debugger
/// continues execution. When running in the Dart VM the behaviour is the same
/// regardless of whether or not a debugger is connected. When compiled to
/// JavaScript, this uses the "debugger" statement, and behaves exactly as
/// that does.
external bool debugger({bool when: true, String msg});

/// Send a reference to [object] to any attached debuggers so they may open an
/// inspector on the object. Returns the argument.
external inspect(object);
