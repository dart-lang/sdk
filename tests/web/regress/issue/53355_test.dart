// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/// This would time out in compilation.
void main() {
  int s = 0;
  for (int i = 0; i < 3; i++) {
    if (test(i, 0)) s++;
    if (test(i, 1)) s++;
    if (test(i, 2)) s++;
    if (test(i, 3)) s++;
    if (test(i, 4)) s++;
    if (test(i, 5)) s++;
    if (test(i, 6)) s++;
    if (test(i, 7)) s++;
    if (test(i, 8)) s++;
    if (test(i, 9)) s++;
    if (test(i, 10)) s++;
    if (test(i, 11)) s++;
    if (test(i, 12)) s++;
    if (test(i, 13)) s++;
    if (test(i, 14)) s++;
    if (test(i, 15)) s++;
    if (test(i, 16)) s++;
    if (test(i, 17)) s++;
    if (test(i, 18)) s++;
    if (test(i, 19)) s++;
    if (test(i, 20)) s++;
    if (test(i, 21)) s++;
    if (test(i, 22)) s++;
    if (test(i, 24)) s++;
    if (test(i, 25)) s++;
    if (test(i, 26)) s++;
    if (test(i, 27)) s++;
    if (test(i, 28)) s++;
    if (test(i, 29)) s++;
    if (test(i, 30)) s++;
    if (test(i, 31)) s++;
    if (test(i, 32)) s++;
    if (test(i, 33)) s++;
    if (test(i, 34)) s++;
  }
  print(s);
}

@pragma('dart2js:never-inline')
bool test(int a, int b) => (a & b) != 0;
