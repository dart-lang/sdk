// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// @dart = 2.7

/// Regression for #24135: inference was not tracking `[]??=` correctly.
library dart2js_2.if_null3_test;

import "package:expect/expect.dart";

void main() {
  var map;
  (((map ??= {})['key1'] ??= {})['key2'] ??= {})['key3'] = 'value';
  Expect.equals('{key1: {key2: {key3: value}}}', '$map');
}
