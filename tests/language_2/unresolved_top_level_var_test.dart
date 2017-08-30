// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Test that an unresolved identifier at the top level causes a compile-time
// error.

var a = b; /*@compile-error=unspecified*/

main() {
  print(a);
}