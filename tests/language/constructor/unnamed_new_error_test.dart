// Copyright (c) 2021, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.



import "package:expect/expect.dart";

// Tests that `Classname.new` is allowed and works
// only as an alias for the unnamed constructor.
// It cannot be used to declare any other member.
// It's not allowed as a reference if there is no unnamed constructor.

// Not allowed without class prefix as constructor.
class C1 {
  const new();
  //    ^^^
  // [cfe] unspecified
  // [analyzer] unspecified
}

class C2 {
  factory new() => C2._();
  //      ^^^
  // [cfe] unspecified
  // [analyzer] unspecified
  C2._();
}

// Not allowed as normal member.
class C3 {
  int new() => 1;
  //  ^^^
  // [cfe] unspecified
  // [analyzer] unspecified
}

class C4 {
  int get new => 1;
  //      ^^^
  // [cfe] unspecified
  // [analyzer] unspecified

  void set new(int value) {}
  //       ^^^
  // [cfe] unspecified
  // [analyzer] unspecified
}

class C5 {
  int new = 1;
  //  ^^^
  // [cfe] unspecified
  // [analyzer] unspecified
}

// Not allowed as static member.
class C6 {
  static void new() {}
  //          ^^^
  // [cfe] unspecified
  // [analyzer] unspecified
}

class C7 {
  static int get new => 42;
  //             ^^^
  // [cfe] unspecified
  // [analyzer] unspecified

  static void set new(int x) {}
  //              ^^^
  // [cfe] unspecified
  // [analyzer] unspecified
}

class C8 {
  static int new = 1;
  //         ^^^
  // [cfe] unspecified
  // [analyzer] unspecified
}

// Not allowed as reference if there is no unnamed constructor.

// Class with no unnamed constructor.
class NoUnnamed<T> {
  NoUnnamed.named();

  NoUnnamed.genRedir() : this.new();
  //                          ^^^
  // [cfe] unspecified
  // [analyzer] unspecified

  factory NoUnnamed.facRedir() = NoUnnamed.new;
  //                                       ^^^
  // [cfe] unspecified
  // [analyzer] unspecified

  factory NoUnnamed.facRedir2() = NoUnnamed<T>.new;
  //                                           ^^^
  // [cfe] unspecified
  // [analyzer] unspecified
}

class SubNoUnnamed extends NoUnnamed<int> {
  SubNoUnnamed() : super.new();
  //                     ^^^
  // [cfe] unspecified
  // [analyzer] unspecified
}

void main() {
  NoUnnamed.new();
  //        ^^^
  // [cfe] unspecified
  // [analyzer] unspecified

  NoUnnamed<int>.new();
  //             ^^^
  // [cfe] unspecified
  // [analyzer] unspecified
}
