// Copyright (c) 2021, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:_interceptors';

import 'package:expect/expect.dart';
import 'package:js/js.dart';

@JS()
class JSClass {}

@JS()
external void eval(String code);

void main() {
  eval(r'''
      function JSClass() {}
      ''');
  Expect.type<LegacyJavaScriptObject>(JSClass());
  Expect.type<List<LegacyJavaScriptObject>>(<JSClass>[]);
}
