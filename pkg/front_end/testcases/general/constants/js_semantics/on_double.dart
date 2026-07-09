// Copyright (c) 2021, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

const dynamic a = 1.0;
const dynamic b = 1.5;

const dynamic c0 = a >> 1;
const dynamic c1 = b >> 1;
const dynamic c2 = a >>> 1;
const dynamic c3 = b >>> 1;

const dynamic d0 = 1 >> a;
const dynamic d1 = 1 >> b;
const dynamic d2 = 1 >>> a;
const dynamic d3 = 1 >>> b;

class Class {
  final int a;

  const Class.doubleShift(i1, i2) : a = (i1 >> i2);
  const Class.tripleShift(i1, i2) : a = (i1 >>> i2);
}

main() {
  const Class c1 = Class.doubleShift(a, 1);
  const Class c2 = Class.doubleShift(b, 1);
  const Class c3 = Class.tripleShift(a, 1);
  const Class c4 = Class.tripleShift(b, 1);

  const Class d1 = Class.doubleShift(1, a);
  const Class d2 = Class.doubleShift(1, b);
  const Class d3 = Class.tripleShift(1, a);
  const Class d4 = Class.tripleShift(1, b);

  const Class e1 = Class.doubleShift(1.0, 1);
  const Class e2 = Class.doubleShift(1.5, 1);
  const Class e3 = Class.tripleShift(1.0, 1);
  const Class e4 = Class.tripleShift(1.5, 1);
}
