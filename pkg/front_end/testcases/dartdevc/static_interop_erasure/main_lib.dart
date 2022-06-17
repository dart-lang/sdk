// Copyright (c) 2021, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

@JS()
library static_interop;

import 'package:js/js.dart';

@JS()
external void eval(String code);

@JS('JSClass')
@staticInterop
class StaticJSClass {
  external StaticJSClass();
  factory StaticJSClass.factory() {
    return StaticJSClass();
  }
}

void setUp() {
  eval('''function JSClass() {}''');
}
