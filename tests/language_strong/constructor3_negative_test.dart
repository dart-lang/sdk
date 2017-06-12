// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Check that there's no crash when constructor called with wrong
// number of args.

class Klass {
  Klass(var v) {}
}

main() {
  var k = new Klass();
  var l = new Klass(1, 2);
}
