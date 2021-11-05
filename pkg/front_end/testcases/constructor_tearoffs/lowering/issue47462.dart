// Copyright (c) 2021, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

typedef MyList<T extends num> = List<T>;

main() {
  const c1 = MyList<num>.filled;
  const c2 = MyList<num>.filled;
  const c3 = (MyList.filled)<num>;

  const c4 = identical(c1, c2);
  const c5 = identical(c1, c3);

  expect(true, c4);
  expect(false, c5);

  expect(true, identical(c1, c2));
  expect(false, identical(c1, c3));

  var v1 = MyList<num>.filled;
  var v2 = MyList<num>.filled;
  var v3 = (MyList.filled)<num>;

  var v4 = identical(v1, v2);
  var v5 = identical(v1, v3);

  expect(true, v4);
  expect(false, v5);

  expect(true, identical(v1, v2));
  expect(false, identical(v1, v3));
}

expect(expected, actual) {
  if (expected != actual) throw 'Expected $expected, actual $actual';
}
