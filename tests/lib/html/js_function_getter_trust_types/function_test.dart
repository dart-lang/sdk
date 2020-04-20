// Copyright (c) 2020, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// SharedOptions=--trust-type-annotations
@JS()
library js_function_getter_trust_types_test;

import 'package:js/js.dart';
import 'package:expect/expect.dart';

import 'js_function_util.dart';

main() {
  injectJs();

  Expect.equals(foo.bar.add(4, 5), 9);
}
