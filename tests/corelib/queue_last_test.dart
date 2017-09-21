// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library queue.last.test;

import "package:expect/expect.dart";
import 'dart:collection' show Queue;

main() {
  Queue<int> queue1 = new Queue<int>();
  queue1..add(11)..add(12)..add(13);
  Queue queue2 = new Queue();

  Expect.equals(13, queue1.last);
  Expect.throws(() => queue2.last, (e) => e is StateError);
}
