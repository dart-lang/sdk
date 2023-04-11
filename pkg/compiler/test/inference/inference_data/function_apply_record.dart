// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

main() {
  directUnusedTest();
  recordUnusedTest();
  directCalledTest();
  directAppliedTest();
  recordCalledTest();
  recordAppliedTest();
}

int Function(int, [int]) _recordUnused(int a) =>
    (int b, [int c = 17]) => a + b + c;
int Function(int, [int]) _recordCalled(int a) =>
    (int b, [int c = 17]) => a + b + c;
int Function(int, [int]) _recordApplied(int a) =>
    /*apply*/ (int b, [int c = 17]) => a + b + c;
int Function(int, [int]) _directUnused(int a) =>
    (int b, [int c = 17]) => a + b + c;
int Function(int, [int]) _directCalled(int a) =>
    (int b, [int c = 17]) => a + b + c;
int Function(int, [int]) _directApplied(int a) =>
    /*apply*/ (int b, [int c = 17]) => a + b + c;

directUnusedTest() {
  return _directUnused(10);
}

recordUnusedTest() {
  final rec = (_recordUnused(10), 4);
  return rec.$1;
}

directCalledTest() {
  return _directCalled(10)(20);
}

directAppliedTest() {
  return Function.apply(_directApplied(10), [20]);
}

recordCalledTest() {
  final rec = (4, _recordCalled(10));
  return (rec.$2)(20);
}

recordAppliedTest() {
  final rec = (_recordApplied(10), 4);
  return Function.apply(rec.$1, [20]);
}
