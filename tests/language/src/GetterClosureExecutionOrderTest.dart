// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
//
// Test that a getter is evaluated after the arguments, when a getter is
// for invoking a method. See chapter 'Method Invocation' in specification.

var counter = 0;

get a() {
  Expect.equals(1, counter);
  counter++;
  return (c) { };
}

b() {
  Expect.equals(0, counter);
  counter++;
  return 1;
}

main() {
  a(b());
  Expect.equals(2, counter);
}
