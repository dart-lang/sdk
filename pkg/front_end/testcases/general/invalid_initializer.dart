// Copyright (c) 2025, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

class Super {
  Super.named();
}

class Sub extends Super {
  Sub();
}

main() {
  new Sub(); // This should crash.
}
