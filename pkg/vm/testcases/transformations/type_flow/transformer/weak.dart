// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

int used1() => 1;
String used2() => 2.toString();

int unused() => 42;

class A {
  int x = used1();
  Function y = used2;
  String toString() => "x: $x, y: $y";
}

class B {
  static String getAccessor() => 'B';
  B() {
    print(B.getAccessor());
    register(Lib.weakRef2(C.getAccessor));
  }
  C getC() => C();
}

class C {
  static String getAccessor() => 'C';
  C() {
    print(C.getAccessor());
  }
}

void register(String Function()? getAccessor) {
  if (getAccessor != null) {
    print(getAccessor());
  }
}

@pragma('weak-tearoff-reference')
Function? weakRef1(Function? x) => x;

class Lib {
  @pragma('weak-tearoff-reference')
  static T Function()? weakRef2<T>(T Function()? x) => x;
}

main(List<String> args) {
  print(weakRef1(used1));
  print(weakRef1(used2));
  print(weakRef1(unused));
  print(A());
  print(B());
}
