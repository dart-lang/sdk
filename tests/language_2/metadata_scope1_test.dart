// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Test that a type variable is not in scope for metadata declared on the type
// declaration.

@deprecated
typedef Foo
<deprecated> // //# 01: ok
    ();

main() {
  Foo f = null;
}
