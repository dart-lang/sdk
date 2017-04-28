// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/*@testedFeatures=inference*/
library test;

/*error:IMPORT_INTERNAL_LIBRARY*/ import 'dart:_foreign_helper' show JS;

main() {
  String x = /*error:INVALID_ASSIGNMENT*/ JS('int', '42');
  var /*@type=String*/ y = JS('String', '"hello"');
  y = "world";
  y = /*error:INVALID_ASSIGNMENT*/ 42;
}
