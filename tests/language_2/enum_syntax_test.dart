// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Basic syntax test for enumeration types

enum Color { red, orange, yellow, green }

// Additional comma at end of list is ok.
enum Veggies {
  carrot,
  bean,
  broccolo,
}

// Need at least one enumeration identifier.
enum Nada {} // //# 01: compile-time error

// Duplicate entries are a compile-time error
enum ComeAgain { ahau, knust, zipfel, knust, gupf } // //# 02: compile-time error

// Enum entries must not collide with implicitly defined members.
enum ComeAgain { ahau, knust, zipfel, index } //# 03: compile-time error

enum ComeAgain { ahau, knust, zipfel, values } //# 04: compile-time error

enum ComeAgain { ahau, knust, zipfel, toString } //# 05: compile-time error

// Enum entry must not collide with enum type name.
enum ComeAgain { ahau, knust, zipfel, ComeAgain } //# 06: compile-time error

// Missing comma.
enum Numbers { one, two, three four, five } // //# 07: compile-time error

// Missing enum type name.
enum { eins, zwei, drei } // //# 08: compile-time error

// Duplicate name in library scope.
topLevelFunction() => null;
enum topLevelFunction { bla, blah } // //# 09: compile-time error

class C {}
enum C { bla, blah } // //# 10: compile-time error

var zzTop;
enum zzTop { Billy, Dusty, Frank } // //# 11: compile-time error

// Enum type cannot be super type or interface type.
class Rainbow extends Color {} // //# 20: compile-time error
class Rainbow implements Color {} // //# 21: compile-time error
class Rainbow extends List with Color {} // //# 22: compile-time error

main() {
  Nada x; //# 01: continued
  var x = ComeAgain.zipfel; // //# 02: continued
  var x = ComeAgain.zipfel; // //# 03: continued
  var x = ComeAgain.zipfel; // //# 04: continued
  var x = ComeAgain.zipfel; // //# 05: continued
  var x = ComeAgain.zipfel; // //# 06: continued
  var x = Numbers.four; // //# 07: continued
  var x = topLevelFunction.bla; // //# 09: continued
  var x = C.bla; // //# 10: continued
  var x = zzTop.Frank; // //# 11: continued

  var x = new Rainbow(); // //# 20: continued
  var x = new Rainbow(); // //# 21: continued
  var x = new Rainbow(); // //# 22: continued

  // It is a compile-time error to explicitly instantiate an enum instance.
  var x = new Color(); // //# 30: compile-time error
}
