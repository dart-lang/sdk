// Copyright (c) 2016, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE.md file.

main() {
  "Should redirect to LinkedHashMap constructor.";
  new Map<Symbol, dynamic>(); // This is a patched constructor whose
  // implementation contains the redirection.
}
