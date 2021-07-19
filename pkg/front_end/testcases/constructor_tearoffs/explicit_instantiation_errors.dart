// Copyright (c) 2021, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

X id<X>(X x) => x;

void method<X, Y>() {}

X boundedMethod<X extends num>(X x) => x;

test() {
  var a = id; // ok
  var b = a<int>; // ok
  var c = id<int>; // ok
  var d = id<int, String>; // error - too many args
  var e = method<int>; // error - too few args
  var f = 0<int>; // error - non-function type operand
  var g = main<int>; // error - non-generic function type operand
  var h = boundedMethod<String>; // error - invalid bound
}

var a = id; // ok
var b = a<int>; // ok
var c = id<int>; // ok
var d = id<int, String>; // error - too many args
var e = method<int>; // error - too few args
var f = 0<int>; // error - non-function type operand
var g = main<int>; // error - non-generic function type operand
var h = boundedMethod<String>; // error - invalid bound

main() {}