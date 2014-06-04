// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// VMOptions=--warn_on_javascript_compatibility --no_warning_as_error --optimization_counter_threshold=5

import "package:expect/expect.dart";

f(x, y) {
  // Unoptimized code.
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

  if (x > 10) {
    // Optimized code.
    x is double;  /// 30: ok
    if (x is double) { }  /// 31: ok
    try { x as double; } on CastError catch (e) { }  /// 32: ok
    try { var z = x as double; } on CastError catch (e) { }  /// 33: ok
    y is int;  /// 34: ok
    if (y is int) { }  /// 35: ok
    try { y as int; } on CastError catch (e) { }  /// 36: ok
    try { var z = y as int; } on CastError catch (e) { }  /// 37: ok

    "${1.0}";  /// 40: ok
    var z = "${1.0}";  /// 41: ok
    (1.0).toString();  /// 42: ok
    var z = (1.0).toString();  /// 43: ok
    "$y";  /// 44: ok
    var z = "$y";  /// 45: ok
    y.toString();  /// 46: ok
    var z = y.toString();  /// 47: ok

    var a = "yz";
    var b = "xyz";
    b = b.substring(1);
    if (identical(a, b)) { }  /// 48: ok
  }
}

g(x, y) => f(x, y);  // Test inlining calls.
h(x, y) => g(x, y);

main() {
  for (var i = 0; i < 20; i++) {
    h(i, i* 1.0);
  }
}

