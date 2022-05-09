// Copyright (c) 2022, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

abstract class I {
  String get member1;
  String get procedure;
  void set setter(String value);
  void set fieldSetter(String value);
  void set setterVsGetter(num value);
  double get getterVsSetter;
}

class A implements I {
  // Check for unsorted names of members.
  static String member5 = "member5";
  static String member4 = "member4";
  static String member3 = "member3";
  static String member1 = "member1"; // Error.
  static String member2 = "member2";

  static void procedure() {} // Error.
  
  static void set setter(String value) {} // Error.
  
  static String fieldSetter = "fieldSetter"; // Error.

  static num get setterVsGetter => 0; // Error.

  static void set getterVsSetter(double value) {} // Error.

  dynamic noSuchMethod(Invocation i) => "foo";
}

main() {}
