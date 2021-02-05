// Copyright (c) 2020, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

@JS()
library test;

import 'dart:async';
import 'dart:_interceptors';
import 'dart:js' as js;
import 'package:expect/expect.dart';
import 'package:js/js.dart';

const String JS_CODE = """
function A() {
  this.x = 1;
}
self.foo = new A();
""";

@JS('A')
@anonymous
class Foo {}

@JS('foo')
external dynamic get foo;

main() {
  js.context.callMethod('eval', [JS_CODE]);
  Expect.isTrue(foo is FutureOr<Foo>);
  Expect.isTrue(foo is JSObject);
}
