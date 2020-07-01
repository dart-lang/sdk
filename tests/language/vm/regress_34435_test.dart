// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// VMOptions=--optimization-filter=triggerBug --no-background-compilation --optimization-counter-threshold=2

@pragma('vm:never-inline')
dynamic triggerGC() {
  var a = [];
  for (int i = 0; i < 100; ++i) {
    a.add([]);
  }
  return a;
}

@pragma('vm:never-inline')
void fillLowerStackWithReturnAddresses() {
  recursive(20);
}

@pragma('vm:never-inline')
dynamic recursive(dynamic n) {
  if (n > 0) {
    recursive(n - 1);
  }
  return 0x0deadbef;
}

class Box {
  @pragma('vm:never-inline')
  Box? get value => global;
}

Box? global;

main() {
  bool isTrue = true;
  bool hasProblem = true;

  @pragma('vm:never-inline')
  void triggerBug(Box box) {
    triggerGC();

    Box? element = box.value;
    if (isTrue) {
      hasProblem = true;
      return;
    }
    try {
      Map map = {};
    } finally {}
  }

  final st = new Box();
  for (int i = 0; i < 1000; ++i) {
    fillLowerStackWithReturnAddresses();
    triggerBug(st);
  }
}
