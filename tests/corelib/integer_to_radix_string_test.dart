// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

main() {
  // Just make sure that we use lower-case characters.
  Expect.equals("abcd", (0xabcd).toRadixString(16));
} 