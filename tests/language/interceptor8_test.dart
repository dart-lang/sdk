// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Regression test for dart2js whose codegen used to not consider a double
// could be instantiated when doing int / int.

var a = [5, 2];

main() {
  print(a[0] / a[1]);
}
