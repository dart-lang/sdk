// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// VMOptions=--warn_on_javascript_compatibility --no_warning_as_error --optimization_counter_threshold=5

import "package:expect/expect.dart";

f(x, y) {
  // Unoptimized and optimized code.
  1 is double;  /// 00: ok
  if (1 is double) { x++; }  /// 01: ok
  try { 1 as double; } on CastError catch (e) { }  /// 02: ok
  try { var y = 1 as double; } on CastError catch (e) { }  /// 03: ok
  1.0 is int;  /// 04: ok
  if (1.0 is int) { x++; }  /// 05: ok
  try { 1.0 as int; } on CastError catch (e) { }  /// 06: ok
  try { var z = 1.0 as int; } on CastError catch (e) { }  /// 07: ok

  x is double;  /// 10: ok
  if (x is double) { }  /// 11: ok
  try { x as double; } on CastError catch (e) { }  /// 12: ok
  try { var z = x as double; } on CastError catch (e) { }  /// 13: ok
  y is int;  /// 14: ok
  if (y is int) { }  /// 15: ok
  try { y as int; } on CastError catch (e) { }  /// 16: ok
  try { var z = y as int; } on CastError catch (e) { }  /// 17: ok

  "${1.0}";  /// 20: ok
  var z = "${1.0}";  /// 21: ok
  (1.0).toString();  /// 22: ok
  var z = (1.0).toString();  /// 23: ok
  "$y";  /// 24: ok
  var z = "$y";  /// 25: ok
  y.toString();  /// 26: ok
  var z = y.toString();  /// 27: ok

  var a = "yz";
  var b = "xyz";
  b = b.substring(1);
  if (identical(a, b)) { }  /// 28: ok

  if (identical(x, y)) { }  /// 29: ok
  if (identical(y, x)) { }  /// 30: ok

  if (x > 10) {
    // Optimized code.
    x is double;  /// 40: ok
    if (x is double) { }  /// 41: ok
    try { x as double; } on CastError catch (e) { }  /// 42: ok
    try { var z = x as double; } on CastError catch (e) { }  /// 43: ok
    y is int;  /// 44: ok
    if (y is int) { }  /// 45: ok
    try { y as int; } on CastError catch (e) { }  /// 46: ok
    try { var z = y as int; } on CastError catch (e) { }  /// 47: ok

    "${1.0}";  /// 50: ok
    var z = "${1.0}";  /// 51: ok
    (1.0).toString();  /// 52: ok
    var z = (1.0).toString();  /// 53: ok
    "$y";  /// 54: ok
    var z = "$y";  /// 55: ok
    y.toString();  /// 56: ok
    var z = y.toString();  /// 57: ok

    var a = "yz";
    var b = "xyz";
    b = b.substring(1);
    if (identical(a, b)) { }  /// 58: ok

    if (identical(x, y)) { }  /// 59: ok
    if (identical(y, x)) { }  /// 60: ok
  }
}

g(x, y) => f(x, y);  // Test inlining calls.
h(x, y) => g(x, y);

main() {
  for (var i = 0; i < 20; i++) {
    h(i, i* 1.0);
  }
}

