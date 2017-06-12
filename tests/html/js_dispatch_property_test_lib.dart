// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

@JS()
library js_dispatch_property_test_lib;

import 'package:js/js.dart';

@JS()
external A create();

@JS()
@anonymous
class A {
  external String foo(String x);
}
