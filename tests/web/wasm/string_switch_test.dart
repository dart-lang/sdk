// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:js_util';
import 'dart:js_interop';

import 'package:expect/expect.dart';

@JS()
external void eval(String code);

void main() {
  eval(r'''
        globalThis.jsString = "hi";
    ''');

  String jsString = getProperty(globalThis, "jsString");

  switch (jsString) {
    case "hi":
      break;
    default:
      Expect.fail("Unexpected JS String: $jsString");
  }
}
