// Copyright (c) 2024, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

@pragma('dart2js:never-inline')
bool foo() {
  return gI++ > 10;
}

int gI = 0;

abstract class Base {}

class Group<T> extends Base {
  @pragma('dart2js:prefer-inline')
  void check(Object? o) => o as List<T>;
}

class Other extends Base {}

void loop(List<num> receivers, Base driven) {
  for (final receiver in receivers) {
    if (driven is Group && foo()) {
      // This is a version of the http://dartbug.com/54329 without a `null`
      // check. The inlined check `e as List<T>` was hoisted above the loop. At
      // that position, the type expression `List<T>` is invalid and throws an
      // error in the rti library.
      driven.check(receivers);
    }
  }
}

main() {
  gI = 100;
  loop(<num>[1], Group<num>());
  loop(<int>[2, 3], Group<int>());
  loop([], Other());
}
