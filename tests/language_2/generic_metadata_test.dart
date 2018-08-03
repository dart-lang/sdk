// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Check that annotations cannot use type arguments, but can be raw.

class C<T> {
  const C();
}

@C() //# 01: ok
@C<dynamic>() //# 02: compile-time error
@C<int>() //# 03: compile-time error
main() {}
