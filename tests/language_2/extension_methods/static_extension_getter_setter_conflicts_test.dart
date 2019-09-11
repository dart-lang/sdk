// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// SharedOptions=--enable-experiment=extension-methods

// Tests interactions between getters and setters where there is a conflict.

// Conflicting class declarations.

class C0 {
  int get m1 => 0;
  void set m2(int x) {}
}

extension E0 on C0 {
  void set m1(int x) {}
  int get m2 => 0;
}

void test0() {
  C0 c0 = C0();
  c0.m1;
  c0.m1 = 0;
  // ^^^^^^
  // [analyzer] unspecified
  // [cfe] unspecified
  E0(c0).m1 = 0;
  E0(c0).m1;
  //     ^^
  // [analyzer] COMPILE_TIME_ERROR.UNDEFINED_EXTENSION_GETTER
  // [cfe] unspecified

  c0.m1 += 0;
  // ^^^^^^
  // [analyzer] unspecified
  // [cfe] unspecified

  c0.m2 = 0;
  c0.m2;
  // ^^
  // [analyzer] unspecified
  // [cfe] unspecified
  c0.m2 += 0;
  // ^^^^^^^
  // [analyzer] unspecified
  // [cfe] unspecified
  E0(c0).m2;
}

// Conflicting extensions.

class C1<T> {
}

extension E1A<T> on C1<T> {
  int get m1 => 0;
  void set m2(int x) {}
}

extension E1B on C1<Object> {
  void set m1(int x) {}
  int get m2 => 0;
}

void test1() {
  C1<int> c1a = C1<Null>(); // E1A is more specific.
  c1a.m1;

  c1a.m1 = 0;
  //  ^^
  // [analyzer] STATIC_WARNING.ASSIGNMENT_TO_FINAL_LOCAL
  // [cfe] unspecified

  c1a.m2;
  //  ^^
  // [analyzer] STATIC_TYPE_WARNING.UNDEFINED_GETTER
  // [cfe] unspecified

  c1a.m2 = 0;

  C1<Object> c1b = C1<Null>();  // Neither extension is more specific.

  c1b.m1;
  //  ^^
  // [analyzer] COMPILE_TIME_ERROR.AMBIGUOUS_EXTENSION_MEMBER_ACCESS
  // [cfe] unspecified

  c1b.m1 = 0;
  //  ^^
  // [analyzer] COMPILE_TIME_ERROR.AMBIGUOUS_EXTENSION_MEMBER_ACCESS
  // [cfe] unspecified

  c1b.m2;
  //  ^^
  // [analyzer] COMPILE_TIME_ERROR.AMBIGUOUS_EXTENSION_MEMBER_ACCESS
  // [cfe] unspecified

  c1b.m2 = 0;
  //  ^^
  // [analyzer] COMPILE_TIME_ERROR.AMBIGUOUS_EXTENSION_MEMBER_ACCESS
  // [cfe] unspecified
}

// Getter on the extension itself.
class C2 {
  int get m1 => 0;
  void set m2(int x) {}
  int get mc => 0;
}

extension E2 on C2 {
  void set m1(int x) {}
  int get m2 => 0;
  String get me => "";

  void test2() {
    // Using `this.member` means using the `on` type.

    this.m1;
    this.m1 = 0;
    //   ^^
    // [analyzer] STATIC_WARNING.ASSIGNMENT_TO_FINAL_NO_SETTER
    // [cfe] unspecified

    this.m2 = 0;
    this.m2;
    //   ^^
    // [analyzer] STATIC_TYPE_WARNING.UNDEFINED_GETTER
    // [cfe] unspecified

    // Check that `this.mc` refers to `C2.mc`.
    this.mc.toRadixString(16);
    // Check that `this.me` refers to `E2.me`.
    this.me.substring(0);
  }
}

main() {
  test0();
  test1();
  C2().test2();
}
