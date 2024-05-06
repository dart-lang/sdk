// Copyright (c) 2024, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

class DupSet<T> {
  @pragma('dart2js:prefer-inline')
  void add(T e) {}

  @pragma('dart2js:never-inline')
  bool contains(Object? e) {
    return gI++ > 10; // always true.
  }
}

int gI = 0;

class Logic {}

class Logic1 extends Logic {}

void loop(List<Logic> receivers, DupSet<Logic>? drivenSignals) {
  for (final receiver in receivers) {
    if (drivenSignals != null && !drivenSignals.contains(receiver)) {
      // In http://dartbug.com/54329 the inlined parametric covariant check `e
      // as T` from `add` was hoisted out of the loop, above the `null` check.
      drivenSignals.add(receiver);
    }
  }
}

main() {
  gI = 100;
  final ds = DupSet<Logic>();

  loop([Logic()], ds);
  loop([Logic()], null);
  loop([Logic1()], DupSet<Logic1>());
}
