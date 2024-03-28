// Copyright (c) 2022, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
// Test that the full stacktrace in an error object matches the stacktrace
// handed to the catch clause.

class C {
  // operator*(o) is missing to trigger a noSuchMethodError when a C object
  // is used in the multiplication below.
}

bar(c) => c * 4;
foo(c) => bar(c);

main() {
  foo(new C());
}
