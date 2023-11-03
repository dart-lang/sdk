// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

int x = int.parse('2');
int y = int.parse('3');

void use(a, b, c) {
  print(a);
  print(b);
  print(c);

  // These calls should be devirtualized.
  print(a ~/ 2);
  print(b ~/ 2);
  print(c ~/ 2);
}

main() {
  use(x + y, x - y, x * y);
}
