// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

void printBugsSwitch(int n) => switch (n) {
      0 => print('no bugs'),
      1 => print('one bug'),
      _ => print('$n bugs'),
    };

void printBugsConditional(int n) => n == 0
    ? print('no bugs')
    : n == 1
        ? print('one bug')
        : print('$n bugs');

main() {
  printBugsSwitch(0);
  printBugsSwitch(1);
  printBugsSwitch(2);

  printBugsConditional(0);
  printBugsConditional(1);
  printBugsConditional(2);
}
