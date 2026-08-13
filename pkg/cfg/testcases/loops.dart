// Copyright (c) 2025, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

void nested(int i) {
  for (var i = 0; i < 10; ++i) {
    while (i < 5) {
      print(++i);
    }
  }
  print(i);
  while (i < 10) {
    for (var j = 0; j < 3; ++j) {
      i += j;
    }
  }
  print(i);
}

void chainedHeaders(int i) {
  do {
    do {
      i -= 17;
    } while (i >= 0);
  } while (i % 2 == 0);
}

void irreducible(int i) {
  switch (i) {
    L1:
    case 1:
      i += 1;
      continue L2;
    L2:
    case 2:
      i += 2;
      if (i > 10) {
        break;
      }
      continue L1;
  }
}

int var63 = 28;
int var68 = 44;

void withTryBlock() {
  var n = 43;
  while (--n > 0) {
    try {
      var63++;
      // Terminate block without reaching a loop backedge,
      // so try body won't be included into the loop body
      // through explicit predecessors of the backedge.
      throw 'bye';
    } on StackOverflowError {
      rethrow;
    } catch (_) {
      // Load from 'var63' is considered loop invariant if
      // loop body doesn't include try block body.
      var68 = var63;
    }
  }
}

void main() {}
