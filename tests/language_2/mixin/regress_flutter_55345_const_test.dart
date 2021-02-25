// Copyright (c) 2020, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Verifies that references to deduplicated mixins are properly updated
// in types which are only accessible through constants.
// Regression test for https://github.com/flutter/flutter/issues/55345.

class Diagnosticable {}

class SomeClass with Diagnosticable {}

class State<T> with Diagnosticable {
  const State();
}

class StateA extends State {
  const StateA();
}

class StateB extends State<int> {
  const StateB();
}

const c1 = StateA();
const c2 = StateB();

main() {
  print(const [
    {
      (c1 ?? c2): [
        [c1 ?? c2]
      ]
    },
    'abc'
  ]);
  // No compile time or runtime errors.
}
