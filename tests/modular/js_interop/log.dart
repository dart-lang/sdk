// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/// Calls to [console.log] and to [log] from other modules don't work if the
/// js-interop annotations are not preserved. However, calls via [log2] and
/// [log3] do work because the annotation is available when compiling this
/// module.
@JS()
library log;

import 'package:js/js.dart';

@JS()
class Console {
  @JS()
  external void log(arg);
}

@JS('console')
external Console get console;

@JS('console.log')
external void log(String s);

void log2(String s) => log(s);
void log3(String s) => console.log(s);
