// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Regression test for issue 20074. Check that a parameter is not declared
// in the same scope as its function declaration.

doit() {
  error(error) {
    print(error);
  }
  error('foobar');
}

main() {
  doit();
}