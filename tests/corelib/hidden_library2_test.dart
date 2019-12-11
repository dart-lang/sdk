// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Test that the internal hidden library doesn't make problems with taking
// stack-traces.

main() {
  print(['x'].where((_) {
    // We actually don't really care for the successful case. We just want to
    // make sure that the test doesn't crash when it is negative.
    throw 'fisk'; // //# 01: runtime error
    return true;
  }).toList());
}
