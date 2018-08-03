// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

@JS()
library js_typed_interop_window_property_test;

import 'dart:html';

import 'package:js/js.dart';
import 'package:expect/expect.dart';

// This is a regression test for https://github.com/dart-lang/sdk/issues/24817

_injectJs() {
  document.body.append(new ScriptElement()
    ..type = 'text/javascript'
    ..innerHtml = r"""
  "use strict";

  window.foo = [function() { return 42; }];
""");
}

@JS("window.foo")
external List<Function> get foo;

main() {
  _injectJs();

  Expect.equals(foo[0](), 42);
}
