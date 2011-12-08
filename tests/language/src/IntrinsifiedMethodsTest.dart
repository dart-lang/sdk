// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
// Dart test program for testing the instanceof operation.

num foo(int n) {
  var x;
  for(var i = 0; i <= n; ++i)
    x = Math.sqrt(i);
  return x;
}

void main() {
  var m = foo(40000);
  print(m);
}
