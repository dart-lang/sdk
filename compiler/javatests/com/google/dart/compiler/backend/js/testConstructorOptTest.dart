// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

class AAA {
  int a;
  int b = 567;
  AAA(this.a) : this.c = 123 { }
  int c;
  int d;
}

class BBB {
  int a;
  int b = 567;
  int c;
  BBB(this.a) { }
}

class CCC extends BBB {
  int d;
  CCC(this.d) : super(this.d) { }
}

class DDD {
  int x;
  int z;
  DDD(this.x, [this.z = 123]);
}

main() {
  AAA _a_marker = new AAA(123);
  BBB _b_marker = new BBB(999);
}
