// Copyright (c) 2025, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// dart2wasmOptions=--enable-deferred-loading

import 'dart:js_interop';

import 'package:async_helper/async_helper.dart';
import 'package:expect/expect.dart';

import 'deferred_loading_js_callback_helper.dart' deferred as D;

main() async {
  asyncStart();
  await D.loadLibrary();
  Expect.equals(D.closureCalled, 0);
  D.deferredMain();
  Expect.equals(D.closureCalled, 1);
  D.func!.callAsFunction();
  Expect.equals(D.closureCalled, 2);
  final jsClosure = D.clos!.toJS;
  jsClosure.callAsFunction();
  Expect.equals(D.closureCalled, 3);
  asyncEnd();
}
