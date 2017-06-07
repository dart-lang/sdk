// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:expect/minitest.dart';

/// Both kinds.
enum Music { country, western }

class BluesBrother {}

// This class does not override object equality
class _Jake extends BluesBrother {}

/// This class overrides object equality
class _Elwood extends BluesBrother {
  bool operator ==(Object other) {
    return (other is _Elwood);
  }
}

/// Mock BluesBrother
class _Norman extends BluesBrother {}

/// Hide nullability from the simple minded null analysis
T hideNull<T>(T x) => x;

/// Generate undefined at a type
T getUndefined<T>() => (new List(1))[0];

main() {
  group('Enum equality', () {
    // Test equality of two enums, various types, nullable
    test('Equal enum/enum (nullable)', () {
      Music e1 = hideNull(Music.country);
      Music e2 = hideNull(Music.western);
      dynamic d1 = hideNull(Music.country);
      dynamic d2 = hideNull(Music.western);
      Object o1 = hideNull(Music.country);
      Object o2 = hideNull(Music.western);
      expect(e1 == e1, true);
      expect(e1 == d1, true);
      expect(e1 == o1, true);
      expect(e1 == e2, false);
      expect(e1 == o2, false);
      expect(e1 == d2, false);
      expect(e1 == e2, false);
      expect(d1 == e1, true);
      expect(d1 == d1, true);
      expect(d1 == o1, true);
      expect(d1 == e2, false);
      expect(d1 == d2, false);
      expect(d1 == o2, false);
      expect(o1 == e1, true);
      expect(o1 == d1, true);
      expect(o1 == o1, true);
      expect(o1 == e2, false);
      expect(o1 == d2, false);
      expect(o1 == o2, false);
    });

    // Test equality of two enums, various types, non-nullable
    test('Equal enum/enum (non-null)', () {
      Music e1 = Music.country;
      Music e2 = Music.western;
      dynamic d1 = Music.country;
      dynamic d2 = Music.western;
      Object o1 = Music.country;
      Object o2 = Music.western;
      expect(e1 == e1, true);
      expect(e1 == d1, true);
      expect(e1 == o1, true);
      expect(e1 == e2, false);
      expect(e1 == o2, false);
      expect(e1 == d2, false);
      expect(e1 == e2, false);
      expect(d1 == e1, true);
      expect(d1 == d1, true);
      expect(d1 == o1, true);
      expect(d1 == e2, false);
      expect(d1 == d2, false);
      expect(d1 == o2, false);
      expect(o1 == e1, true);
      expect(o1 == d1, true);
      expect(o1 == o1, true);
      expect(o1 == e2, false);
      expect(o1 == d2, false);
      expect(o1 == o2, false);
    });

    // Test equality of enum and other types (static, nullable)
    test('Equal enum/other (static, nullable)', () {
      Music e1 = hideNull(Music.country);
      String s1 = hideNull("hello");
      String s2 = hideNull("");
      int i1 = hideNull(3);
      int i2 = hideNull(0);
      List l1 = hideNull(new List(3));
      BluesBrother b1 = hideNull(new _Norman());

      expect(e1 == s1, false);
      expect(e1 == s2, false);
      expect(e1 == i1, false);
      expect(e1 == i2, false);
      expect(e1 == l1, false);
      expect(e1 == b1, false);

      expect(s1 == e1, false);
      expect(s2 == e1, false);
      expect(i1 == e1, false);
      expect(i2 == e1, false);
      expect(l1 == e1, false);
      expect(b1 == e1, false);
    });

    // Test equality of enum and other types (static, non-null)
    test('Equal enum/other (static, non-null)', () {
      Music e1 = Music.country;
      String s1 = "hello";
      String s2 = "";
      int i1 = 3;
      int i2 = 0;
      List l1 = new List(3);
      BluesBrother b1 = new _Norman();

      expect(e1 == s1, false);
      expect(e1 == s2, false);
      expect(e1 == i1, false);
      expect(e1 == i2, false);
      expect(e1 == l1, false);
      expect(e1 == b1, false);

      expect(s1 == e1, false);
      expect(s2 == e1, false);
      expect(i1 == e1, false);
      expect(i2 == e1, false);
      expect(l1 == e1, false);
      expect(b1 == e1, false);
    });

    // Test equality of enum and other types (dynamic, nullable)
    test('Equal enum/other (dynamic, nullable)', () {
      Music e1 = hideNull(Music.country);
      dynamic d1 = hideNull(Music.country);
      dynamic s1 = hideNull("hello");
      dynamic s2 = hideNull("");
      dynamic i1 = hideNull(3);
      dynamic i2 = hideNull(0);
      dynamic l1 = hideNull(new List(3));
      dynamic b1 = hideNull(new _Norman());

      expect(e1 == s1, false);
      expect(e1 == s2, false);
      expect(e1 == i1, false);
      expect(e1 == i2, false);
      expect(e1 == l1, false);
      expect(e1 == b1, false);

      expect(s1 == e1, false);
      expect(s2 == e1, false);
      expect(i1 == e1, false);
      expect(i2 == e1, false);
      expect(l1 == e1, false);
      expect(b1 == e1, false);

      expect(d1 == s1, false);
      expect(d1 == s2, false);
      expect(d1 == i1, false);
      expect(d1 == i2, false);
      expect(d1 == l1, false);
      expect(d1 == b1, false);

      expect(s1 == d1, false);
      expect(s2 == d1, false);
      expect(i1 == d1, false);
      expect(i2 == d1, false);
      expect(l1 == d1, false);
      expect(b1 == d1, false);
    });

    // Test equality of enum and other types (dynamic, non-null)
    test('Equal enum/other (dynamic, non-null)', () {
      Music e1 = Music.country;
      dynamic d1 = Music.country;
      String s1 = "hello";
      String s2 = "";
      int i1 = 3;
      int i2 = 0;
      List l1 = new List(3);
      BluesBrother b1 = new _Norman();

      expect(e1 == s1, false);
      expect(e1 == s2, false);
      expect(e1 == i1, false);
      expect(e1 == i2, false);
      expect(e1 == l1, false);
      expect(e1 == b1, false);

      expect(s1 == e1, false);
      expect(s2 == e1, false);
      expect(i1 == e1, false);
      expect(i2 == e1, false);
      expect(l1 == e1, false);
      expect(b1 == e1, false);

      expect(d1 == s1, false);
      expect(d1 == s2, false);
      expect(d1 == i1, false);
      expect(d1 == i2, false);
      expect(d1 == l1, false);
      expect(d1 == b1, false);

      expect(s1 == d1, false);
      expect(s2 == d1, false);
      expect(i1 == d1, false);
      expect(i2 == d1, false);
      expect(l1 == d1, false);
      expect(b1 == d1, false);
    });
  });

  group('String equality', () {
    // Test equality of two strings, various types, nullable
    test('Equal string/string (nullable)', () {
      String e1 = hideNull("The");
      String e2 = hideNull("Band");
      dynamic d1 = hideNull("The");
      dynamic d2 = hideNull("Band");
      Object o1 = hideNull("The");
      Object o2 = hideNull("Band");
      expect(e1 == e1, true);
      expect(e1 == d1, true);
      expect(e1 == o1, true);
      expect(e1 == e2, false);
      expect(e1 == o2, false);
      expect(e1 == d2, false);
      expect(e1 == e2, false);
      expect(d1 == e1, true);
      expect(d1 == d1, true);
      expect(d1 == o1, true);
      expect(d1 == e2, false);
      expect(d1 == d2, false);
      expect(d1 == o2, false);
      expect(o1 == e1, true);
      expect(o1 == d1, true);
      expect(o1 == o1, true);
      expect(o1 == e2, false);
      expect(o1 == d2, false);
      expect(o1 == o2, false);
    });

    // Test equality of two strings, various types, non-nullable
    test('Equal string/string (non-null)', () {
      String e1 = "The";
      String e2 = "Band";
      dynamic d1 = "The";
      dynamic d2 = "Band";
      Object o1 = "The";
      Object o2 = "Band";
      expect(e1 == e1, true);
      expect(e1 == d1, true);
      expect(e1 == o1, true);
      expect(e1 == e2, false);
      expect(e1 == o2, false);
      expect(e1 == d2, false);
      expect(e1 == e2, false);
      expect(d1 == e1, true);
      expect(d1 == d1, true);
      expect(d1 == o1, true);
      expect(d1 == e2, false);
      expect(d1 == d2, false);
      expect(d1 == o2, false);
      expect(o1 == e1, true);
      expect(o1 == d1, true);
      expect(o1 == o1, true);
      expect(o1 == e2, false);
      expect(o1 == d2, false);
      expect(o1 == o2, false);
    });

    // Test equality of string and other types (static, nullable)
    test('Equal string/other (static, nullable)', () {
      String e1 = hideNull("The");
      String s1 = hideNull("hello");
      String s2 = hideNull("");
      int i1 = hideNull(3);
      int i2 = hideNull(0);
      List l1 = hideNull(new List(3));
      BluesBrother b1 = hideNull(new _Norman());

      expect(e1 == s1, false);
      expect(e1 == s2, false);
      expect(e1 == i1, false);
      expect(e1 == i2, false);
      expect(e1 == l1, false);
      expect(e1 == b1, false);

      expect(s1 == e1, false);
      expect(s2 == e1, false);
      expect(i1 == e1, false);
      expect(i2 == e1, false);
      expect(l1 == e1, false);
      expect(b1 == e1, false);
    });

    // Test equality of string and other types (static, non-null)
    test('Equal string/other (static, non-null)', () {
      String e1 = "The";
      String s1 = "hello";
      String s2 = "";
      int i1 = 3;
      int i2 = 0;
      List l1 = new List(3);
      BluesBrother b1 = new _Norman();

      expect(e1 == s1, false);
      expect(e1 == s2, false);
      expect(e1 == i1, false);
      expect(e1 == i2, false);
      expect(e1 == l1, false);
      expect(e1 == b1, false);

      expect(s1 == e1, false);
      expect(s2 == e1, false);
      expect(i1 == e1, false);
      expect(i2 == e1, false);
      expect(l1 == e1, false);
      expect(b1 == e1, false);
    });

    // Test equality of string and other types (dynamic, nullable)
    test('Equal string/other (dynamic, nullable)', () {
      String e1 = hideNull("The");
      dynamic d1 = hideNull("The");
      dynamic s1 = hideNull("hello");
      dynamic s2 = hideNull("");
      dynamic i1 = hideNull(3);
      dynamic i2 = hideNull(0);
      dynamic l1 = hideNull(new List(3));
      dynamic b1 = hideNull(new _Norman());

      expect(e1 == s1, false);
      expect(e1 == s2, false);
      expect(e1 == i1, false);
      expect(e1 == i2, false);
      expect(e1 == l1, false);
      expect(e1 == b1, false);

      expect(s1 == e1, false);
      expect(s2 == e1, false);
      expect(i1 == e1, false);
      expect(i2 == e1, false);
      expect(l1 == e1, false);
      expect(b1 == e1, false);

      expect(d1 == s1, false);
      expect(d1 == s2, false);
      expect(d1 == i1, false);
      expect(d1 == i2, false);
      expect(d1 == l1, false);
      expect(d1 == b1, false);

      expect(s1 == d1, false);
      expect(s2 == d1, false);
      expect(i1 == d1, false);
      expect(i2 == d1, false);
      expect(l1 == d1, false);
      expect(b1 == d1, false);
    });

    // Test equality of string and other types (dynamic, non-null)
    test('Equal string/other (dynamic, non-null)', () {
      String e1 = "The";
      dynamic d1 = "The";
      String s1 = "hello";
      String s2 = "";
      int i1 = 3;
      int i2 = 0;
      List l1 = new List(3);
      BluesBrother b1 = new _Norman();

      expect(e1 == s1, false);
      expect(e1 == s2, false);
      expect(e1 == i1, false);
      expect(e1 == i2, false);
      expect(e1 == l1, false);
      expect(e1 == b1, false);

      expect(s1 == e1, false);
      expect(s2 == e1, false);
      expect(i1 == e1, false);
      expect(i2 == e1, false);
      expect(l1 == e1, false);
      expect(b1 == e1, false);

      expect(d1 == s1, false);
      expect(d1 == s2, false);
      expect(d1 == i1, false);
      expect(d1 == i2, false);
      expect(d1 == l1, false);
      expect(d1 == b1, false);

      expect(s1 == d1, false);
      expect(s2 == d1, false);
      expect(i1 == d1, false);
      expect(i2 == d1, false);
      expect(l1 == d1, false);
      expect(b1 == d1, false);
    });
  });

  group('Boolean equality', () {
    // Test equality of two bools, various types, nullable
    test('Equal bool/bool (nullable)', () {
      bool e1 = hideNull(true);
      bool e2 = hideNull(false);
      dynamic d1 = hideNull(true);
      dynamic d2 = hideNull(false);
      Object o1 = hideNull(true);
      Object o2 = hideNull(false);
      expect(e1 == e1, true);
      expect(e1 == d1, true);
      expect(e1 == o1, true);
      expect(e1 == e2, false);
      expect(e1 == o2, false);
      expect(e1 == d2, false);
      expect(e1 == e2, false);
      expect(d1 == e1, true);
      expect(d1 == d1, true);
      expect(d1 == o1, true);
      expect(d1 == e2, false);
      expect(d1 == d2, false);
      expect(d1 == o2, false);
      expect(o1 == e1, true);
      expect(o1 == d1, true);
      expect(o1 == o1, true);
      expect(o1 == e2, false);
      expect(o1 == d2, false);
      expect(o1 == o2, false);
    });

    // Test equality of two bools, various types, non-nullable
    test('Equal bool/bool (non-null)', () {
      bool e1 = true;
      bool e2 = false;
      dynamic d1 = true;
      dynamic d2 = false;
      Object o1 = true;
      Object o2 = false;
      expect(e1 == e1, true);
      expect(e1 == d1, true);
      expect(e1 == o1, true);
      expect(e1 == e2, false);
      expect(e1 == o2, false);
      expect(e1 == d2, false);
      expect(e1 == e2, false);
      expect(d1 == e1, true);
      expect(d1 == d1, true);
      expect(d1 == o1, true);
      expect(d1 == e2, false);
      expect(d1 == d2, false);
      expect(d1 == o2, false);
      expect(o1 == e1, true);
      expect(o1 == d1, true);
      expect(o1 == o1, true);
      expect(o1 == e2, false);
      expect(o1 == d2, false);
      expect(o1 == o2, false);
    });

    // Test equality of bool and other types (static, nullable)
    test('Equal bool/other (static, nullable)', () {
      bool e1 = hideNull(true);
      String s1 = hideNull("hello");
      String s2 = hideNull("");
      int i1 = hideNull(3);
      int i2 = hideNull(0);
      List l1 = hideNull(new List(3));
      BluesBrother b1 = hideNull(new _Norman());

      expect(e1 == s1, false);
      expect(e1 == s2, false);
      expect(e1 == i1, false);
      expect(e1 == i2, false);
      expect(e1 == l1, false);
      expect(e1 == b1, false);

      expect(s1 == e1, false);
      expect(s2 == e1, false);
      expect(i1 == e1, false);
      expect(i2 == e1, false);
      expect(l1 == e1, false);
      expect(b1 == e1, false);
    });

    // Test equality of bool and other types (static, non-null)
    test('Equal bool/other (static, non-null)', () {
      bool e1 = true;
      String s1 = "hello";
      String s2 = "";
      int i1 = 3;
      int i2 = 0;
      List l1 = new List(3);
      BluesBrother b1 = new _Norman();

      expect(e1 == s1, false);
      expect(e1 == s2, false);
      expect(e1 == i1, false);
      expect(e1 == i2, false);
      expect(e1 == l1, false);
      expect(e1 == b1, false);

      expect(s1 == e1, false);
      expect(s2 == e1, false);
      expect(i1 == e1, false);
      expect(i2 == e1, false);
      expect(l1 == e1, false);
      expect(b1 == e1, false);
    });

    // Test equality of bool and other types (dynamic, nullable)
    test('Equal bool/other (dynamic, nullable)', () {
      bool e1 = hideNull(true);
      dynamic d1 = hideNull(true);
      dynamic s1 = hideNull("hello");
      dynamic s2 = hideNull("");
      dynamic i1 = hideNull(3);
      dynamic i2 = hideNull(0);
      dynamic l1 = hideNull(new List(3));
      dynamic b1 = hideNull(new _Norman());

      expect(e1 == s1, false);
      expect(e1 == s2, false);
      expect(e1 == i1, false);
      expect(e1 == i2, false);
      expect(e1 == l1, false);
      expect(e1 == b1, false);

      expect(s1 == e1, false);
      expect(s2 == e1, false);
      expect(i1 == e1, false);
      expect(i2 == e1, false);
      expect(l1 == e1, false);
      expect(b1 == e1, false);

      expect(d1 == s1, false);
      expect(d1 == s2, false);
      expect(d1 == i1, false);
      expect(d1 == i2, false);
      expect(d1 == l1, false);
      expect(d1 == b1, false);

      expect(s1 == d1, false);
      expect(s2 == d1, false);
      expect(i1 == d1, false);
      expect(i2 == d1, false);
      expect(l1 == d1, false);
      expect(b1 == d1, false);
    });

    // Test equality of bool and other types (dynamic, non-null)
    test('Equal bool/other (dynamic, non-null)', () {
      bool e1 = true;
      dynamic d1 = true;
      String s1 = "hello";
      String s2 = "";
      int i1 = 3;
      int i2 = 0;
      List l1 = new List(3);
      BluesBrother b1 = new _Norman();

      expect(e1 == s1, false);
      expect(e1 == s2, false);
      expect(e1 == i1, false);
      expect(e1 == i2, false);
      expect(e1 == l1, false);
      expect(e1 == b1, false);

      expect(s1 == e1, false);
      expect(s2 == e1, false);
      expect(i1 == e1, false);
      expect(i2 == e1, false);
      expect(l1 == e1, false);
      expect(b1 == e1, false);

      expect(d1 == s1, false);
      expect(d1 == s2, false);
      expect(d1 == i1, false);
      expect(d1 == i2, false);
      expect(d1 == l1, false);
      expect(d1 == b1, false);

      expect(s1 == d1, false);
      expect(s2 == d1, false);
      expect(i1 == d1, false);
      expect(i2 == d1, false);
      expect(l1 == d1, false);
      expect(b1 == d1, false);
    });
  });

  group('String equality', () {
    // Test equality of two strings, various types, nullable
    test('Equal string/string (nullable)', () {
      String e1 = hideNull("The");
      String e2 = hideNull("Band");
      dynamic d1 = hideNull("The");
      dynamic d2 = hideNull("Band");
      Object o1 = hideNull("The");
      Object o2 = hideNull("Band");
      expect(e1 == e1, true);
      expect(e1 == d1, true);
      expect(e1 == o1, true);
      expect(e1 == e2, false);
      expect(e1 == o2, false);
      expect(e1 == d2, false);
      expect(e1 == e2, false);
      expect(d1 == e1, true);
      expect(d1 == d1, true);
      expect(d1 == o1, true);
      expect(d1 == e2, false);
      expect(d1 == d2, false);
      expect(d1 == o2, false);
      expect(o1 == e1, true);
      expect(o1 == d1, true);
      expect(o1 == o1, true);
      expect(o1 == e2, false);
      expect(o1 == d2, false);
      expect(o1 == o2, false);
    });

    // Test equality of two strings, various types, non-nullable
    test('Equal string/string (non-null)', () {
      String e1 = "The";
      String e2 = "Band";
      dynamic d1 = "The";
      dynamic d2 = "Band";
      Object o1 = "The";
      Object o2 = "Band";
      expect(e1 == e1, true);
      expect(e1 == d1, true);
      expect(e1 == o1, true);
      expect(e1 == e2, false);
      expect(e1 == o2, false);
      expect(e1 == d2, false);
      expect(e1 == e2, false);
      expect(d1 == e1, true);
      expect(d1 == d1, true);
      expect(d1 == o1, true);
      expect(d1 == e2, false);
      expect(d1 == d2, false);
      expect(d1 == o2, false);
      expect(o1 == e1, true);
      expect(o1 == d1, true);
      expect(o1 == o1, true);
      expect(o1 == e2, false);
      expect(o1 == d2, false);
      expect(o1 == o2, false);
    });

    // Test equality of string and other types (static, nullable)
    test('Equal string/other (static, nullable)', () {
      String e1 = hideNull("The");
      String s1 = hideNull("hello");
      String s2 = hideNull("");
      int i1 = hideNull(3);
      int i2 = hideNull(0);
      List l1 = hideNull(new List(3));
      BluesBrother b1 = hideNull(new _Norman());

      expect(e1 == s1, false);
      expect(e1 == s2, false);
      expect(e1 == i1, false);
      expect(e1 == i2, false);
      expect(e1 == l1, false);
      expect(e1 == b1, false);

      expect(s1 == e1, false);
      expect(s2 == e1, false);
      expect(i1 == e1, false);
      expect(i2 == e1, false);
      expect(l1 == e1, false);
      expect(b1 == e1, false);
    });

    // Test equality of string and other types (static, non-null)
    test('Equal string/other (static, non-null)', () {
      String e1 = "The";
      String s1 = "hello";
      String s2 = "";
      int i1 = 3;
      int i2 = 0;
      List l1 = new List(3);
      BluesBrother b1 = new _Norman();

      expect(e1 == s1, false);
      expect(e1 == s2, false);
      expect(e1 == i1, false);
      expect(e1 == i2, false);
      expect(e1 == l1, false);
      expect(e1 == b1, false);

      expect(s1 == e1, false);
      expect(s2 == e1, false);
      expect(i1 == e1, false);
      expect(i2 == e1, false);
      expect(l1 == e1, false);
      expect(b1 == e1, false);
    });

    // Test equality of string and other types (dynamic, nullable)
    test('Equal string/other (dynamic, nullable)', () {
      String e1 = hideNull("The");
      dynamic d1 = hideNull("The");
      dynamic s1 = hideNull("hello");
      dynamic s2 = hideNull("");
      dynamic i1 = hideNull(3);
      dynamic i2 = hideNull(0);
      dynamic l1 = hideNull(new List(3));
      dynamic b1 = hideNull(new _Norman());

      expect(e1 == s1, false);
      expect(e1 == s2, false);
      expect(e1 == i1, false);
      expect(e1 == i2, false);
      expect(e1 == l1, false);
      expect(e1 == b1, false);

      expect(s1 == e1, false);
      expect(s2 == e1, false);
      expect(i1 == e1, false);
      expect(i2 == e1, false);
      expect(l1 == e1, false);
      expect(b1 == e1, false);

      expect(d1 == s1, false);
      expect(d1 == s2, false);
      expect(d1 == i1, false);
      expect(d1 == i2, false);
      expect(d1 == l1, false);
      expect(d1 == b1, false);

      expect(s1 == d1, false);
      expect(s2 == d1, false);
      expect(i1 == d1, false);
      expect(i2 == d1, false);
      expect(l1 == d1, false);
      expect(b1 == d1, false);
    });

    // Test equality of string and other types (dynamic, non-null)
    test('Equal string/other (dynamic, non-null)', () {
      String e1 = "The";
      dynamic d1 = "The";
      String s1 = "hello";
      String s2 = "";
      int i1 = 3;
      int i2 = 0;
      List l1 = new List(3);
      BluesBrother b1 = new _Norman();

      expect(e1 == s1, false);
      expect(e1 == s2, false);
      expect(e1 == i1, false);
      expect(e1 == i2, false);
      expect(e1 == l1, false);
      expect(e1 == b1, false);

      expect(s1 == e1, false);
      expect(s2 == e1, false);
      expect(i1 == e1, false);
      expect(i2 == e1, false);
      expect(l1 == e1, false);
      expect(b1 == e1, false);

      expect(d1 == s1, false);
      expect(d1 == s2, false);
      expect(d1 == i1, false);
      expect(d1 == i2, false);
      expect(d1 == l1, false);
      expect(d1 == b1, false);

      expect(s1 == d1, false);
      expect(s2 == d1, false);
      expect(i1 == d1, false);
      expect(i2 == d1, false);
      expect(l1 == d1, false);
      expect(b1 == d1, false);
    });
  });

  group('Number equality', () {
    // Test equality of two ints, various types, nullable
    test('Equal int/int (nullable)', () {
      int e1 = hideNull(11);
      int e2 = hideNull(12);
      dynamic d1 = hideNull(11);
      dynamic d2 = hideNull(12);
      Object o1 = hideNull(11);
      Object o2 = hideNull(12);
      expect(e1 == e1, true);
      expect(e1 == d1, true);
      expect(e1 == o1, true);
      expect(e1 == e2, false);
      expect(e1 == o2, false);
      expect(e1 == d2, false);
      expect(e1 == e2, false);
      expect(d1 == e1, true);
      expect(d1 == d1, true);
      expect(d1 == o1, true);
      expect(d1 == e2, false);
      expect(d1 == d2, false);
      expect(d1 == o2, false);
      expect(o1 == e1, true);
      expect(o1 == d1, true);
      expect(o1 == o1, true);
      expect(o1 == e2, false);
      expect(o1 == d2, false);
      expect(o1 == o2, false);
    });

    // Test equality of two ints, various types, non-nullable
    test('Equal int/int (non-null)', () {
      int e1 = 11;
      int e2 = 12;
      dynamic d1 = 11;
      dynamic d2 = 12;
      Object o1 = 11;
      Object o2 = 12;
      expect(e1 == e1, true);
      expect(e1 == d1, true);
      expect(e1 == o1, true);
      expect(e1 == e2, false);
      expect(e1 == o2, false);
      expect(e1 == d2, false);
      expect(e1 == e2, false);
      expect(d1 == e1, true);
      expect(d1 == d1, true);
      expect(d1 == o1, true);
      expect(d1 == e2, false);
      expect(d1 == d2, false);
      expect(d1 == o2, false);
      expect(o1 == e1, true);
      expect(o1 == d1, true);
      expect(o1 == o1, true);
      expect(o1 == e2, false);
      expect(o1 == d2, false);
      expect(o1 == o2, false);
    });

    // Test equality of int and other types (static, nullable)
    test('Equal int/other (static, nullable)', () {
      int e1 = hideNull(11);
      String s1 = hideNull("hello");
      String s2 = hideNull("");
      int i1 = hideNull(3);
      int i2 = hideNull(0);
      List l1 = hideNull(new List(3));
      BluesBrother b1 = hideNull(new _Norman());

      expect(e1 == s1, false);
      expect(e1 == s2, false);
      expect(e1 == i1, false);
      expect(e1 == i2, false);
      expect(e1 == l1, false);
      expect(e1 == b1, false);

      expect(s1 == e1, false);
      expect(s2 == e1, false);
      expect(i1 == e1, false);
      expect(i2 == e1, false);
      expect(l1 == e1, false);
      expect(b1 == e1, false);
    });

    // Test equality of int and other types (static, non-null)
    test('Equal int/other (static, non-null)', () {
      int e1 = 11;
      String s1 = "hello";
      String s2 = "";
      int i1 = 3;
      int i2 = 0;
      List l1 = new List(3);
      BluesBrother b1 = new _Norman();

      expect(e1 == s1, false);
      expect(e1 == s2, false);
      expect(e1 == i1, false);
      expect(e1 == i2, false);
      expect(e1 == l1, false);
      expect(e1 == b1, false);

      expect(s1 == e1, false);
      expect(s2 == e1, false);
      expect(i1 == e1, false);
      expect(i2 == e1, false);
      expect(l1 == e1, false);
      expect(b1 == e1, false);
    });

    // Test equality of int and other types (dynamic, nullable)
    test('Equal int/other (dynamic, nullable)', () {
      int e1 = hideNull(11);
      dynamic d1 = hideNull(11);
      dynamic s1 = hideNull("hello");
      dynamic s2 = hideNull("");
      dynamic i1 = hideNull(3);
      dynamic i2 = hideNull(0);
      dynamic l1 = hideNull(new List(3));
      dynamic b1 = hideNull(new _Norman());

      expect(e1 == s1, false);
      expect(e1 == s2, false);
      expect(e1 == i1, false);
      expect(e1 == i2, false);
      expect(e1 == l1, false);
      expect(e1 == b1, false);

      expect(s1 == e1, false);
      expect(s2 == e1, false);
      expect(i1 == e1, false);
      expect(i2 == e1, false);
      expect(l1 == e1, false);
      expect(b1 == e1, false);

      expect(d1 == s1, false);
      expect(d1 == s2, false);
      expect(d1 == i1, false);
      expect(d1 == i2, false);
      expect(d1 == l1, false);
      expect(d1 == b1, false);

      expect(s1 == d1, false);
      expect(s2 == d1, false);
      expect(i1 == d1, false);
      expect(i2 == d1, false);
      expect(l1 == d1, false);
      expect(b1 == d1, false);
    });

    // Test equality of int and other types (dynamic, non-null)
    test('Equal int/other (dynamic, non-null)', () {
      int e1 = 11;
      dynamic d1 = 11;
      String s1 = "hello";
      String s2 = "";
      int i1 = 3;
      int i2 = 0;
      List l1 = new List(3);
      BluesBrother b1 = new _Norman();

      expect(e1 == s1, false);
      expect(e1 == s2, false);
      expect(e1 == i1, false);
      expect(e1 == i2, false);
      expect(e1 == l1, false);
      expect(e1 == b1, false);

      expect(s1 == e1, false);
      expect(s2 == e1, false);
      expect(i1 == e1, false);
      expect(i2 == e1, false);
      expect(l1 == e1, false);
      expect(b1 == e1, false);

      expect(d1 == s1, false);
      expect(d1 == s2, false);
      expect(d1 == i1, false);
      expect(d1 == i2, false);
      expect(d1 == l1, false);
      expect(d1 == b1, false);

      expect(s1 == d1, false);
      expect(s2 == d1, false);
      expect(i1 == d1, false);
      expect(i2 == d1, false);
      expect(l1 == d1, false);
      expect(b1 == d1, false);
    });
  });

  group('Object equality', () {
    // Test equality of two objects, various types, nullable
    test('Equal object/object (nullable)', () {
      _Jake e1 = hideNull(new _Jake());
      _Elwood e2 = hideNull(new _Elwood());
      dynamic d1 = hideNull(e1);
      dynamic d2 = hideNull(new _Elwood());
      Object o1 = hideNull(e1);
      Object o2 = hideNull(new _Elwood());
      expect(e1 == e1, true);
      expect(e1 == d1, true);
      expect(e1 == o1, true);
      expect(e1 == e2, false);
      expect(e1 == o2, false);
      expect(e1 == d2, false);
      expect(e1 == e2, false);
      expect(d1 == e1, true);
      expect(d1 == d1, true);
      expect(d1 == o1, true);
      expect(d1 == e2, false);
      expect(d1 == d2, false);
      expect(d1 == o2, false);
      expect(o1 == e1, true);
      expect(o1 == d1, true);
      expect(o1 == o1, true);
      expect(o1 == e2, false);
      expect(o1 == d2, false);
      expect(o1 == o2, false);
    });

    // Test equality of two objects, various types, non-nullable
    test('Equal object/object (non-null)', () {
      _Jake e1 = new _Jake();
      _Elwood e2 = new _Elwood();
      dynamic d1 = e1;
      dynamic d2 = new _Elwood();
      Object o1 = e1;
      Object o2 = new _Elwood();
      expect(e1 == e1, true);
      expect(e1 == d1, true);
      expect(e1 == o1, true);
      expect(e1 == e2, false);
      expect(e1 == o2, false);
      expect(e1 == d2, false);
      expect(e1 == e2, false);
      expect(d1 == e1, true);
      expect(d1 == d1, true);
      expect(d1 == o1, true);
      expect(d1 == e2, false);
      expect(d1 == d2, false);
      expect(d1 == o2, false);
      expect(o1 == e1, true);
      expect(o1 == d1, true);
      expect(o1 == o1, true);
      expect(o1 == e2, false);
      expect(o1 == d2, false);
      expect(o1 == o2, false);
    });

    // Test equality of object and other types (static, nullable)
    test('Equal object/other (static, nullable)', () {
      _Jake e1 = hideNull(new _Jake());
      String s1 = hideNull("hello");
      String s2 = hideNull("");
      int i1 = hideNull(3);
      int i2 = hideNull(0);
      List l1 = hideNull(new List(3));
      BluesBrother b1 = hideNull(new _Norman());

      expect(e1 == s1, false);
      expect(e1 == s2, false);
      expect(e1 == i1, false);
      expect(e1 == i2, false);
      expect(e1 == l1, false);
      expect(e1 == b1, false);

      expect(s1 == e1, false);
      expect(s2 == e1, false);
      expect(i1 == e1, false);
      expect(i2 == e1, false);
      expect(l1 == e1, false);
      expect(b1 == e1, false);
    });

    // Test equality of object and other types (static, non-null)
    test('Equal object/other (static, non-null)', () {
      _Jake e1 = new _Jake();
      String s1 = "hello";
      String s2 = "";
      int i1 = 3;
      int i2 = 0;
      List l1 = new List(3);
      BluesBrother b1 = new _Norman();

      expect(e1 == s1, false);
      expect(e1 == s2, false);
      expect(e1 == i1, false);
      expect(e1 == i2, false);
      expect(e1 == l1, false);
      expect(e1 == b1, false);

      expect(s1 == e1, false);
      expect(s2 == e1, false);
      expect(i1 == e1, false);
      expect(i2 == e1, false);
      expect(l1 == e1, false);
      expect(b1 == e1, false);
    });

    // Test equality of object and other types (dynamic, nullable)
    test('Equal object/other (dynamic, nullable)', () {
      _Jake e1 = hideNull(new _Jake());
      dynamic d1 = hideNull(new _Jake());
      dynamic s1 = hideNull("hello");
      dynamic s2 = hideNull("");
      dynamic i1 = hideNull(3);
      dynamic i2 = hideNull(0);
      dynamic l1 = hideNull(new List(3));
      dynamic b1 = hideNull(new _Norman());

      expect(e1 == s1, false);
      expect(e1 == s2, false);
      expect(e1 == i1, false);
      expect(e1 == i2, false);
      expect(e1 == l1, false);
      expect(e1 == b1, false);

      expect(s1 == e1, false);
      expect(s2 == e1, false);
      expect(i1 == e1, false);
      expect(i2 == e1, false);
      expect(l1 == e1, false);
      expect(b1 == e1, false);

      expect(d1 == s1, false);
      expect(d1 == s2, false);
      expect(d1 == i1, false);
      expect(d1 == i2, false);
      expect(d1 == l1, false);
      expect(d1 == b1, false);

      expect(s1 == d1, false);
      expect(s2 == d1, false);
      expect(i1 == d1, false);
      expect(i2 == d1, false);
      expect(l1 == d1, false);
      expect(b1 == d1, false);
    });

    // Test equality of object and other types (dynamic, non-null)
    test('Equal object/other (dynamic, non-null)', () {
      _Jake e1 = new _Jake();
      dynamic d1 = new _Jake();
      String s1 = "hello";
      String s2 = "";
      int i1 = 3;
      int i2 = 0;
      List l1 = new List(3);
      BluesBrother b1 = new _Norman();

      expect(e1 == s1, false);
      expect(e1 == s2, false);
      expect(e1 == i1, false);
      expect(e1 == i2, false);
      expect(e1 == l1, false);
      expect(e1 == b1, false);

      expect(s1 == e1, false);
      expect(s2 == e1, false);
      expect(i1 == e1, false);
      expect(i2 == e1, false);
      expect(l1 == e1, false);
      expect(b1 == e1, false);

      expect(d1 == s1, false);
      expect(d1 == s2, false);
      expect(d1 == i1, false);
      expect(d1 == i2, false);
      expect(d1 == l1, false);
      expect(d1 == b1, false);

      expect(s1 == d1, false);
      expect(s2 == d1, false);
      expect(i1 == d1, false);
      expect(i2 == d1, false);
      expect(l1 == d1, false);
      expect(b1 == d1, false);
    });
  });

  // Test that null receiver with undefined argument is handled correctly
  group('Null/undefined equality', () {
    // Test equality of null object and other types
    test('Equal object/other (static, null)', () {
      BluesBrother n = hideNull(null);
      String u1 = getUndefined();
      int u2 = getUndefined();
      bool u3 = getUndefined();
      List u4 = getUndefined();

      expect(n == n, true);

      expect(n == u1, true);
      expect(n == u2, true);
      expect(n == u3, true);
      expect(n == u4, true);

      expect(u1 == n, true);
      expect(u2 == n, true);
      expect(u3 == n, true);
      expect(u4 == n, true);
    });

    // Test equality of null string and other types
    test('Equal String/other (static, null)', () {
      BluesBrother u1 = getUndefined();
      String n = hideNull(null);
      int u2 = getUndefined();
      bool u3 = getUndefined();
      List u4 = getUndefined();

      expect(n == n, true);

      expect(n == u1, true);
      expect(n == u2, true);
      expect(n == u3, true);
      expect(n == u4, true);

      expect(u1 == n, true);
      expect(u2 == n, true);
      expect(u3 == n, true);
      expect(u4 == n, true);
    });

    // Test equality of null int and other types
    test('Equal int/other (static, null)', () {
      BluesBrother u1 = getUndefined();
      String u2 = getUndefined();
      int n = hideNull(null);
      bool u3 = getUndefined();
      List u4 = getUndefined();

      expect(n == n, true);

      expect(n == u1, true);
      expect(n == u2, true);
      expect(n == u3, true);
      expect(n == u4, true);

      expect(u1 == n, true);
      expect(u2 == n, true);
      expect(u3 == n, true);
      expect(u4 == n, true);
    });

    // Test equality of null bool and other types
    test('Equal bool/other (static, null)', () {
      BluesBrother u1 = getUndefined();
      String u2 = getUndefined();
      int u3 = getUndefined();
      bool n = hideNull(null);
      List u4 = getUndefined();

      expect(n == n, true);

      expect(n == u1, true);
      expect(n == u2, true);
      expect(n == u3, true);
      expect(n == u4, true);

      expect(u1 == n, true);
      expect(u2 == n, true);
      expect(u3 == n, true);
      expect(u4 == n, true);
    });

    // Test equality of null List and other types
    test('Equal List/other (static, null)', () {
      BluesBrother u1 = getUndefined();
      String u2 = getUndefined();
      int u3 = getUndefined();
      bool u4 = getUndefined();
      List n = hideNull(null);

      expect(n == n, true);

      expect(n == u1, true);
      expect(n == u2, true);
      expect(n == u3, true);
      expect(n == u4, true);

      expect(u1 == n, true);
      expect(u2 == n, true);
      expect(u3 == n, true);
      expect(u4 == n, true);
    });
  });
}
