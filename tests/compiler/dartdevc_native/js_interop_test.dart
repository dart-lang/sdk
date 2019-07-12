// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

@JS()
library js_interop_test;

import 'package:expect/expect.dart';
import 'package:js/js.dart';
import 'dart:_foreign_helper' as helper show JS;
import 'dart:_runtime' as dart;

@JS()
class Console {
  @JS()
  external void log(arg);
}

@JS('console')
external Console get console;

@JS('console.log')
external void log(String s);

void dartLog(String s) => log(s);

@JS('foo')
external set _foo(Function f);

@JS('foo')
external void foo(String s);

void main() {
  Function(String) jsFunc = helper.JS('', '(x) => {}');
  Expect.equals(dart.assertInterop(jsFunc), jsFunc);

  Expect.equals(dart.assertInterop(log), log);
  Expect.equals(dart.assertInterop(console.log), console.log);
  Expect.throws(() => dart.assertInterop(dartLog));

  Expect.isNull(foo);
  _foo = jsFunc;
  Expect.isNotNull(foo);
  Expect.equals(dart.assertInterop(foo), foo);

  // TODO(vsm): We should inject an assert here and fail on this assignment.
  _foo = dartLog;
  Expect.throws(() => dart.assertInterop(foo));
}
