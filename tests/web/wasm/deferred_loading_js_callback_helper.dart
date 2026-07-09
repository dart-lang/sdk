// Copyright (c) 2025, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:js_interop';

int closureCalled = 0;
JSFunction? func;
void Function()? clos;

void deferredMain() {
  void closure() {
    closureCalled++;
  }

  final jsClosure = closure.toJS;
  jsClosure.callAsFunction();
  clos = closure;
  func = jsClosure;
}
