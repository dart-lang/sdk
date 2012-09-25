// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

main() {
  var list = [];
  list.insertRange(-1, 0);
  Expect.listEquals([], list);
  list.insertRange(0, 0);
  Expect.listEquals([], list);
  list.insertRange(0, 0, 2);
  Expect.listEquals([], list);
  list.insertRange(0, 0, initialValue: 2);
  Expect.listEquals([], list);

  expectIOORE(() { [1, 2].insertRange(-1, 1); });
  expectIOORE(() { [1, 2].insertRange(3, 1); });
  expectIAE(() { [1, 2].insertRange(0, -1); });

  list = []; list.insertRange(0, 3);
  Expect.listEquals([null, null, null], list);

  list = []; list.insertRange(0, 3, initialValue: 1);
  Expect.listEquals([1, 1, 1], list);

  list = [1, 1]; list.insertRange(1, 1, initialValue: 2);
  Expect.listEquals([1, 2, 1], list);

  list = [1, 1]; list.insertRange(2, 2, initialValue: 9);
  Expect.listEquals([1, 1, 9, 9], list);

  list = [1, 1]; list.insertRange(2, 1);
  Expect.listEquals([1, 1, null], list);

  list = [1, 1]; list.insertRange(0, 3, 3);
  Expect.listEquals([3, 3, 3, 1, 1], list);
}

void expectIOORE(Function f) {
  Expect.throws(f, (e) => e is IndexOutOfRangeException);
}

void expectIAE(Function f) {
  Expect.throws(f, (e) => e is ArgumentError);
}
