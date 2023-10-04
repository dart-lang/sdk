// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// SharedOptions=--enable-experiment=inline-class

// Regression check for https://dartbug.com/53610

extension type const E(Null _) {}

void main() {
  E e = const E(null); // Failed here.
  assert(e._ == null);
}