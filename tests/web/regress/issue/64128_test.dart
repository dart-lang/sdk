// Copyright (c) 2026, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Test for https://dartbug.com/64128
//
// The default value 'null' for the wider optional parameter type was missing
// from the global inference graph.

import 'package:expect/expect.dart';

const fiveSeconds = Duration(seconds: 5);
const tenSeconds = Duration(seconds: 10);

int seen = -1;

@pragma('dart2js:never-inline')
int sink(Duration timeout) => seen = timeout.inMicroseconds;

class Plain {
  Object subscribe({Duration timeout = fiveSeconds}) => sink(timeout);
}

class Widened implements Plain {
  @override
  Object subscribe({Duration? timeout}) => sink(timeout ?? fiveSeconds);
}

@pragma('dart2js:never-inline')
void test(String name, Plain p) {
  Expect.equals(5_000_000, p.subscribe());
  Expect.equals(5_000_000, p.subscribe(timeout: fiveSeconds));
}

void main() {
  // Ensure 'timeout' in 'sink' and hence 'seen' is not inferred constant.
  sink(Duration(seconds: 0));

  test('Plain', Plain());
  test('Widened', Widened());

  // Ensure 'seen' is used so it is not removed entirely.
  Expect.equals(5_000_000, seen);
}
