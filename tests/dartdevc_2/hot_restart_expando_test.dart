// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:_runtime' as dart;

import 'package:expect/expect.dart';
import 'package:js/js.dart';

final e = Expando<int>();

@JS()
external void eval(String s);

@JS()
external Object get singleton;

void main() {
  eval('''
    if (!self.singleton) {
      self.singleton = {};
    }
  ''');
  var o = singleton;
  Expect.equals(null, e[o]);
  e[o] = 1;

  dart.hotRestart();
  Expect.equals(null, e[o]);
}
