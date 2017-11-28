// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
//
// Tests that a "const factory" with body produces a compile-time error.

class ConstFactoryWithBody {
  const factory ConstFactoryWithBody.one() { } //# 01: syntax error
}

main() {
  const ConstFactoryWithBody.one(); //# 01: continued
}
