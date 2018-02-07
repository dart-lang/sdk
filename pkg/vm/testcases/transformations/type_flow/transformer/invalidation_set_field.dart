// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

class T1 {}

class T2 {}

class A {
  dynamic field1 = new T1();
  dynamic field2 = new T1();
}

// Methods of this class should have inferred type = T1.
class DeepCaller1 {
  barL1(A aa) => barL2(aa);
  barL2(A aa) => barL3(aa);
  barL3(A aa) => barL4(aa);
  barL4(A aa) => aa.field1;
}

// Methods of this class should have inferred type = T1 | T2.
class DeepCaller2 {
  barL1(A aa) => barL2(aa);
  barL2(A aa) => barL3(aa);
  barL3(A aa) => barL4(aa);
  barL4(A aa) => aa.field2;
}

use1(DeepCaller1 x, A aa) => x.barL1(aa);
use2(DeepCaller2 x, A aa) => x.barL1(aa);

Function unknown;

getDynamic() => unknown.call();

void setField2(A aa, dynamic value) {
  aa.field2 = value;
}

main(List<String> args) {
  new A();
  new T1();
  new T2();

  use1(new DeepCaller1(), getDynamic());
  use2(new DeepCaller2(), getDynamic());

  setField2(new A(), new T2());
}
