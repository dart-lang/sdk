// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library hasNextIterator.test;

import "package:expect/expect.dart";
import 'dart:collection';

main() {
  var it = new HasNextIterator([].iterator);
  Expect.isFalse(it.hasNext);
  Expect.isFalse(it.hasNext);
  Expect.throwsStateError(() => it.next());
  Expect.isFalse(it.hasNext);

  it = new HasNextIterator([1].iterator);
  Expect.isTrue(it.hasNext);
  Expect.isTrue(it.hasNext);
  Expect.equals(1, it.next());
  Expect.isFalse(it.hasNext);
  Expect.isFalse(it.hasNext);
  Expect.throwsStateError(() => it.next());
  Expect.isFalse(it.hasNext);

  it = new HasNextIterator([1, 2].iterator);
  Expect.isTrue(it.hasNext);
  Expect.isTrue(it.hasNext);
  Expect.equals(1, it.next());
  Expect.isTrue(it.hasNext);
  Expect.isTrue(it.hasNext);
  Expect.equals(2, it.next());
  Expect.isFalse(it.hasNext);
  Expect.isFalse(it.hasNext);
  Expect.throwsStateError(() => it.next());
  Expect.isFalse(it.hasNext);
}
