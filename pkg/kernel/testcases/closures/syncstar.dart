// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
//
// This tests that the wrapper function around converted closures in the VM
// doesn't break when the context parameter is captured (since async
// transformations introduces an additional closure here).

range(int high) {
  iter(int low) sync* {
    while (high-- > low) yield high;
  }

  return iter;
}

main() {
  var sum = 0;
  for (var x in range(10)(2)) sum += x;

  if (sum != 44) {
    throw new Exception("Incorrect output.");
  }
}
