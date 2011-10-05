// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

class A {
  A() { }
}

class B {
  B() { }
  bool operator ==(Object other) {
    return this === other;
  }
}

class Main {
  static void main() {
    int _marker_0 = 1 + 1;
    int _marker_1 = 1 - 1;
    int _marker_2 = 1 * 1;
    double _marker_3 = 1 / 1;
    int _marker_4 = 1 % 1;

    bool _marker_5 = 1 > 1;
    bool _marker_6 = 1 < 1;
    bool _marker_7 = 1 >= 1;
    bool _marker_8 = 1 <= 1;

    bool _marker_9 = 1 == 1;
    bool _marker_10 = 1 != 1;

    bool _marker_11 = true == false;
    bool _marker_12 = true != false;

    double _marker_13 = 1.0 ~/ 2.0;

    int _marker_14 = 1 | 1;
    int _marker_15 = 1 & 1;
    int _marker_16 = 1 << 1;
    int _marker_17 = 1 >> 1;

    bool _marker_18 = true || false;
    bool _marker_19 = true && false;

    A a = new A();
    B b = new B();
    String str = "foo";
    int i = 0;

    bool _marker_20 = i == 0;
    bool _marker_21 = i != 0;
    bool _marker_22 = str == "a";
    bool _marker_23 = str != "a";
    bool _marker_24 = a == b;
    bool _marker_25 = a != b;
    bool _marker_26 = b == a;
    bool _marker_27 = b != a;
    bool _marker_28 = a == null;
    bool _marker_29 = a != null;
    bool _marker_30 = null == a;
    bool _marker_31 = null != a;
    bool _marker_32 = b == null;
    bool _marker_33 = b != null;
    bool _marker_34 = null == b;
    bool _marker_35 = null != b;
    bool _marker_36 = i === 0;
    bool _marker_37 = i !== 0;
    bool _marker_38 = str === "a";
    bool _marker_39 = str !== "a";
    bool _marker_40 = a === b;
    bool _marker_41 = a !== b;
    bool _marker_42 = b === a;
    bool _marker_43 = b !== a;
    bool _marker_44 = a === null;
    bool _marker_45 = a !== null;
    bool _marker_46 = null === a;
    bool _marker_47 = null !== a;
    bool _marker_48 = b === null;
    bool _marker_49 = b !== null;
    bool _marker_50 = null === b;
    bool _marker_51 = null !== b;
    bool _marker_52 = str === null;
    bool _marker_53 = str !== null;
    bool _marker_54 = null === str;
    bool _marker_55 = null !== str;
    bool _marker_56 = null == null;
    bool _marker_57 = null === null;
    bool _marker_58 = false == null;
    bool _marker_59 = false === null;
    bool _marker_60 = str == null;
    bool _marker_61 = str != null;
    bool _marker_62 = null == str;
    bool _marker_63 = null != str;
  }
}
