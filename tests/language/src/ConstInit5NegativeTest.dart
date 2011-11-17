// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
// Check for proper types used in compile time constant expressions

final A = 1;
final B = "Hello";
final C = A + B; // error: sub-expressions of binary + must be numeric

int main() {
  try {
    // Some Dart implementations may not check C until it is about to be executed
    print(C);
  } catch (Exception e) {
    // should be a compilation error, not a catchable exception
  }
}
