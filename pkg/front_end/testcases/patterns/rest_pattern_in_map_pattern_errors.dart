// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

test(dynamic x) {
  if (x case {..., 1: 1, ...}) { // Error.
    return 0;
  }
  if (x case {..., 1: 1, ..., 2: 2, ...}) { // Error.
    return 1;
  }
  if (x case {1: 1, ..., 2: 2}) { // Error.
    return 2;
  }
}

main() {}
