// Copyright (c) 2026, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Tests that horizontal inference doesn't defer a function literal used as the
// index of a `super` index assignment. The index is analyzed before the
// assigned value, so it doesn't see promotions made by the value, regardless
// of whether the value of the assignment is used.
//
// See https://github.com/dart-lang/sdk/issues/64510.

import 'package:expect/expect.dart';
import 'package:expect/static_type_helper.dart';

class A {
  Object? lastIndex;
  Object? lastValue;

  void operator []=(Object? i, Object? v) {
    lastIndex = i;
    lastValue = v;
  }
}

class B extends A {
  void statementContext(int? x) {
    super[() {
          x.expectStaticType<Exactly<int?>>();
        }] =
        x!;
  }

  void forUpdaterContext(int? x) {
    for (
      var i = 0;
      i < 1;
      i++,
      super[() {
            x.expectStaticType<Exactly<int?>>();
          }] =
          x!
    ) {}
  }

  int valueContext(int? x) {
    var y =
        super[() {
              x.expectStaticType<Exactly<int?>>();
            }] =
            x!;
    return y.expectStaticType<Exactly<int>>();
  }
}

main() {
  var b = B();

  b.statementContext(1);
  Expect.equals(1, b.lastValue);
  (b.lastIndex as void Function())();

  b.forUpdaterContext(2);
  Expect.equals(2, b.lastValue);
  (b.lastIndex as void Function())();

  Expect.equals(3, b.valueContext(3));
  Expect.equals(3, b.lastValue);
  (b.lastIndex as void Function())();
}
