// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Regression test for dart2js that used to not see a closure could be
// invoked through a getter access followed by an invocation.

var closure = (Object a) => a.toString();

get foo => closure;

main() {
  if (foo(42) != '42') {
    throw 'Test failed';
  }
}
