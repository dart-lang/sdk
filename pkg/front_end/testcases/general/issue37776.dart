// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// This test checks that the bug reported at http://dartbug.com/37776 is fixed.

class X {
  const X.foo();
}

class X {
  const X.foo();
}

void main() {
  const X.foo();
}
