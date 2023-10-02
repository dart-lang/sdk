// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// SharedOptions=--enable-experiment=inline-class

// Test for issue https://github.com/dart-lang/sdk/issues/53607

// All kinds of named constructors, including a primary constructor,
// and getters "conflicting" with them.
extension type const Ext1.name0(int i) {
  Ext1.name1(this.i);
  Ext1.name2(int i): this.name0(i);
  factory Ext1.name3(int i) = Ext1.name0;
  factory Ext1.name4(int i) => Ext1.name0(i);

  const Ext1.name5(this.i);
  const Ext1.name6(int i): this.name0(i);
  const factory Ext1.name7(int i) = Ext1.name0;

  int get name0 => i;
  int get name1 => i;
  int get name2 => i;
  int get name3 => i;
  int get name4 => i;
  int get name5 => i;
  int get name6 => i;
  int get name7 => i;
}

class C {
  int get name3 => 0;
  set name4(int i) {}
  int name5() => 0;
}

// Other instance members with same name as constructors,
// both extension and interface members.
extension type const Ext2.name0(C _) implements C {
  Ext2.name1(): this.name0(C());
  Ext2.name2(): this.name0(C());
  Ext2.name3(): this.name0(C());
  Ext2.name4(): this.name0(C());
  Ext2.name5(): this.name0(C());

  int get name0 => 0;
  set name1(int i) {}
  int name2() => 0;
}


void main() {
  Ext1 e = Ext1.name0(0);
  var res = [
    e.name0,
    e.name1,
    e.name2,
    e.name3,
    e.name4,
    e.name5,
    e.name6,
    e.name7,
  ];
  if (res.length != 8) throw AssertionError("Sanity check failed");

  Ext2 c = Ext2.name0(C());
  var res2 = [
    c.name0,
    c.name1 = 0,
    c.name2(),
    c.name3,
    c.name4 = 0,
    c.name5(),
  ];
  if (res2.length != 6) throw AssertionError("Sanity check failed");
}
