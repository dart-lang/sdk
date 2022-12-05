// Copyright (c) 2022, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

test() {
  (int, String) r = (0, "one");
  print(r.$00); // Error.
  print(r.$0x0); // Error.
  print(r.$01); // Error.
  print(r.$0x1); // Error.
}