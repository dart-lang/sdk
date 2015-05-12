// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


// Codegen dependency order test
const UNINITIALIZED = const _Uninitialized();
class _Uninitialized { const _Uninitialized(); }

main() {
  // Number literals in call expressions.
  print(1.toString());
  print(1.0.toString());
  print(1.1.toString());
}
