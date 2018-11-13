// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// VMOptions=--optimization-filter=triggerBug --no-background-compilation --enable-inlining-annotations --optimization-counter-threshold=2

const String NeverInline = 'NeverInline';

@NeverInline
dynamic triggerGC() {
  var a = [];
  for (int i = 0; i < 100; ++i) {
    a.add([]);
  }
  return a;
}

@NeverInline
void fillLowerStackWithReturnAddresses() {
  recursive(20);
}

@NeverInline
dynamic recursive(dynamic n) {
  if (n > 0) {
    recursive(n - 1);
  }
  return 0x0deadbef;
}

class Box {
  @NeverInline
  Box get value => global;
}

Box global;

main() {
  bool isTrue = true;
  bool hasProblem = true;

  @NeverInline
  void triggerBug(Box box) {
    triggerGC();

    Box element = box.value;
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
