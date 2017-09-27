// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library queue.single.test;

import "package:expect/expect.dart";
import 'dart:collection' show Queue;

main() {
  Queue<int> queue1 = new Queue<int>();
  queue1.add(42);
  Queue queue2 = new Queue();
  queue2..add(11)..add(12)..add(13);
  Queue queue3 = new Queue();

  Expect.equals(42, queue1.single);
  Expect.throws(() => queue2.single, (e) => e is StateError);
  Expect.throws(() => queue3.single, (e) => e is StateError);
}
