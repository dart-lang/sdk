// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// This test verifies that AOT compiler is correctly handling method extractors
// when resolving targets of method invocations.

import "package:expect/expect.dart";

abstract class MyQueue<E> {}

class MyListQueue<E> implements MyQueue<E> {
  String toString() => 'good';
}

class NextRound {
  runNextRound() {
    // During the 2nd iteration of precompilation loop (Precompiler::Iterate)
    // we're going to discover a call to get:toString() which is only resolved
    // to Object.get:toString at this time, as MyListQueue.get:toString method
    // extractor is not created yet. Verify that compiler doesn't use that
    // target.
    MyQueue q = new MyListQueue();
    dynamic x = q.toString;
    Expect.equals("good", x.call());
  }
}

class NextRound2 {
  runNextRound() {}
}

getNextRound(i) => i > 5 ? new NextRound() : new NextRound2();

void main() {
  // During the 1st iteration of precompilation loop (Precompiler::Iterate)
  // we need to create method extractor for Object.toString.
  var x = new Object().toString;
  x.call();
  // Trigger the next round via new dynamic selector.
  dynamic y = getNextRound(17);
  y.runNextRound();
}
