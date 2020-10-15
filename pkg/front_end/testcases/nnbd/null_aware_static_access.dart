// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

class C {
  static int get staticMember => 0;
  static void set staticMember(int value) {}
  static int? get staticMember2 => 0;
  static void set staticMember2(int? value) {}
  static void staticMethod() {}

  static List<int> get property => [0];
  static Map<int, int?> get property2 => {};
}

void main() {
  C?.staticMember;
  C?.staticMember;
  C?.staticMember = 42;
  C?.staticMethod();
  C?.staticMember.isEven;
  C?.staticMember.toString();
  C?.property[0];
  C?.property[0] = 0;
  C?.property2[0] ??= 0;
  C?.staticMember2 ??= 42;
  C?.staticMember += 2;
  C?.staticMember++;
  --C?.staticMember;
}
