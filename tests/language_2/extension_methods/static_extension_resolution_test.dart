// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import "package:expect/expect.dart";

// Tests the resolution of multiple applicable extensions.

String lastSetterValue;

class SuperTarget {}

class Target<T> extends SuperTarget {
  String targetMethod() => "targetMethod";
  String get targetGetter => "targetGetter";
  void set targetSetter(String argument) {
    lastSetterValue = "targetSetter: $argument";
  }
}

class SubTarget<T> extends Target<T> {
  String subTargetMethod() => "subTargetMethod";
  String get subTargetGetter => "subTargetGetter";
  void set subTargetSetter(String argument) {
    lastSetterValue = "subTargetSetter: $argument";
  }
}

extension E1<T> on SubTarget<T> {
  static String name = "SubTarget<T>";

  String e1() => "$name.e1";

  String targetMethod() => "$name.targetMethod";
  String get targetGetter => "$name.targetGetter";
  void set targetSetter(String value) {
    lastSetterValue = "$name.targetSetter: $value";
  }

  String subTargetMethod() => "$name.subTargetMethod";
  String get subTargetGetter => "$name.subTargetGetter";
  void set subTargetSetter(String value) {
    lastSetterValue = "$name.subTargetSetter: $value";
  }

  List<T> get typedList => <T>[];
}

extension E2 on SubTarget<Object> {
  static String name = "SubTarget<Object>";

  String e1() => "$name.e1";
  String e2() => "$name.e2";

  String targetMethod() => "$name.targetMethod";
  String get targetGetter => "$name.targetGetter";
  void set targetSetter(String value) {
    lastSetterValue = "$name.targetSetter: $value";
  }

  String subTargetMethod() => "$name.subTargetMethod";
  String get subTargetGetter => "$name.subTargetGetter";
  void set subTargetSetter(String value) {
    lastSetterValue = "$name.subTargetSetter: $value";
  }
}

extension E3<T> on Target<T> {
  static String name = "Target<T>";

  String e1() => "$name.e1";
  String e2() => "$name.e2";
  String e3() => "$name.e3";

  String targetMethod() => "$name.targetMethod";
  String get targetGetter => "$name.targetGetter";
  void set targetSetter(String value) {
    lastSetterValue = "$name.targetSetter: $value";
  }

  String subTargetMethod() => "$name.subTargetMethod";
  String get subTargetGetter => "$name.subTargetGetter";
  void set subTargetSetter(String value) {
    lastSetterValue = "$name.subTargetSetter: $value";
  }

  List<T> get typedList => <T>[];
}

extension E4 on Target<Object> {
  static String name = "Target<Object>";

  String e1() => "$name.e1";
  String e2() => "$name.e2";
  String e3() => "$name.e3";
  String e4() => "$name.e4";

  String targetMethod() => "$name.targetMethod";
  String get targetGetter => "$name.targetGetter";
  void set targetSetter(String value) {
    lastSetterValue = "$name.targetSetter: $value";
  }

  String subTargetMethod() => "$name.subTargetMethod";
  String get subTargetGetter => "$name.subTargetGetter";
  void set subTargetSetter(String value) {
    lastSetterValue = "$name.subTargetSetter: $value";
  }
}

extension E5<T> on T {
  static String name = "T";

  String e1() => "$name.e1";
  String e2() => "$name.e2";
  String e3() => "$name.e3";
  String e4() => "$name.e4";
  String e5() => "$name.e5";

  String targetMethod() => "$name.targetMethod";
  String get targetGetter => "$name.targetGetter";
  void set targetSetter(String value) {
    lastSetterValue = "$name.targetSetter: $value";
  }

  String subTargetMethod() => "$name.subTargetMethod";
  String get subTargetGetter => "$name.subTargetGetter";
  void set subTargetSetter(String value) {
    lastSetterValue = "$name.subTargetSetter: $value";
  }

  List<T> get typedList => <T>[];
}

extension E6 on Object {
  static String name = "Object";

  String e1() => "$name.e1";
  String e2() => "$name.e2";
  String e3() => "$name.e3";
  String e4() => "$name.e4";
  String e5() => "$name.e5";
  String e6() => "$name.e6";

  String targetMethod() => "$name.targetMethod";
  String get targetGetter => "$name.targetGetter";
  void set targetSetter(String value) {
    lastSetterValue = "$name.targetSetter: $value";
  }

  String subTargetMethod() => "$name.subTargetMethod";
  String get subTargetGetter => "$name.subTargetGetter";
  void set subTargetSetter(String value) {
    lastSetterValue = "$name.subTargetSetter: $value";
  }
}

main() {
  SubTarget<num> s1 = SubTarget<int>();
  Target<num> t1 = SubTarget<int>();
  SuperTarget o1 = SubTarget<int>();
  Target<int> ti1 = SubTarget<int>();
  ;
  SubTarget<int> si1 = SubTarget<int>();
  ;

  // Interface methods take precedence.

  Expect.equals("targetGetter", s1.targetGetter);
  Expect.equals("targetMethod", s1.targetMethod());
  s1.targetSetter = "1";
  Expect.equals("targetSetter: 1", lastSetterValue);

  Expect.equals("subTargetGetter", s1.subTargetGetter);
  Expect.equals("subTargetMethod", s1.subTargetMethod());
  s1.subTargetSetter = "2";
  Expect.equals("subTargetSetter: 2", lastSetterValue);

  Expect.equals("targetGetter", t1.targetGetter);
  Expect.equals("targetMethod", t1.targetMethod());
  t1.targetSetter = "3";
  Expect.equals("targetSetter: 3", lastSetterValue);

  // Methods not on the instance resolve to extension methods.

  Expect.equals("Target<T>.subTargetGetter", t1.subTargetGetter);
  Expect.equals("Target<T>.subTargetMethod", t1.subTargetMethod());
  t1.subTargetSetter = "4";
  Expect.equals("Target<T>.subTargetSetter: 4", lastSetterValue);

  Expect.type<List<int>>(ti1.typedList);
  Expect.type<List<int>>(si1.typedList);
  Expect.type<List<SuperTarget>>(o1.typedList);

  // Extension methods can be called directly using override syntax.

  Expect.equals("SubTarget<T>.targetGetter", E1<num>(si1).targetGetter);
  Expect.equals("SubTarget<T>.targetMethod", E1<num>(si1).targetMethod());
  E1<num>(si1).targetSetter = "5";
  Expect.equals("SubTarget<T>.targetSetter: 5", lastSetterValue);

  Expect.equals("SubTarget<T>.subTargetGetter", E1<num>(si1).subTargetGetter);
  Expect.equals("SubTarget<T>.subTargetMethod", E1<num>(si1).subTargetMethod());
  E1<num>(si1).subTargetSetter = "6";
  Expect.equals("SubTarget<T>.subTargetSetter: 6", lastSetterValue);

  Expect.type<List<num>>(E1<num>(si1).typedList);

  // Applicable methods.
  Expect.equals("SubTarget<T>.e1", s1.e1());
  Expect.equals("T.e2", s1.e2());
  Expect.equals("T.e3", s1.e3());
  Expect.equals("T.e4", s1.e4());
  Expect.equals("T.e5", s1.e5());
  Expect.equals("Object.e6", s1.e6());

  Expect.equals("Target<T>.e1", t1.e1());
  Expect.equals("Target<T>.e2", t1.e2());
  Expect.equals("Target<T>.e3", t1.e3());
  Expect.equals("T.e4", t1.e4());
  Expect.equals("T.e5", t1.e5());
  Expect.equals("Object.e6", t1.e6());

  Expect.equals("T.e1", o1.e1());
  Expect.equals("T.e2", o1.e2());
  Expect.equals("T.e3", o1.e3());
  Expect.equals("T.e4", o1.e4());
  Expect.equals("T.e5", o1.e5());
  Expect.equals("Object.e6", o1.e6());
}
