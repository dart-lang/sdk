// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// The >>> operator is not supported in Dart

main() {
  var foo = -10
    >>> 1 //# 01: syntax error
      ;
  foo >>>= 1; //# 02: syntax error
}
