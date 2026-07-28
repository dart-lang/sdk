// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

main() {
  late final int i;
  i = 1; // Simple assignment calls the setter
  print(i);

  late final int j;
  // Destructuring assignment sets the backing store directly
  (j, _) = (2, "Hello");
  print(j);
}
