// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Tests interactions between getters and setters where there is a conflict.

// Conflicting class declarations.

class C0 {
  int get m1 => 0;
  void set m2(int x) {}
  int operator [](int index) => 0;
}

extension E0 on C0 {
  void set m1(int x) {}
  int get m2 => 0;
  void operator []=(int index, int value) {}
}

void test0() {
  C0 c0 = C0();
  c0.m1;
  c0.m1 = 0;
  // ^^
  // [analyzer] COMPILE_TIME_ERROR.ASSIGNMENT_TO_FINAL_NO_SETTER
  // [cfe] The setter 'm1' isn't defined for the class 'C0'.
  E0(c0).m1 = 0;
  E0(c0).m1;
  //     ^^
  // [analyzer] COMPILE_TIME_ERROR.UNDEFINED_EXTENSION_GETTER
  // [cfe] Getter not found: 'm1'.

  c0.m1 += 0;
  // ^^
  // [analyzer] COMPILE_TIME_ERROR.ASSIGNMENT_TO_FINAL_NO_SETTER
  // [cfe] The setter 'm1' isn't defined for the class 'C0'.

  c0.m1++;
  // ^^
  // [analyzer] COMPILE_TIME_ERROR.ASSIGNMENT_TO_FINAL_NO_SETTER
  // [cfe] The setter 'm1' isn't defined for the class 'C0'.

  c0.m2 = 0;
  c0.m2;
  // ^^
  // [analyzer] COMPILE_TIME_ERROR.UNDEFINED_GETTER
  // [cfe] The getter 'm2' isn't defined for the class 'C0'.
  c0.m2 += 0;
  // ^^
  // [analyzer] COMPILE_TIME_ERROR.UNDEFINED_GETTER
  // [cfe] The getter 'm2' isn't defined for the class 'C0'.
  c0.m2++;
  // ^^
  // [analyzer] COMPILE_TIME_ERROR.UNDEFINED_GETTER
  // [cfe] The getter 'm2' isn't defined for the class 'C0'.

  E0(c0).m2;

  c0[0];
  c0[0] = 0;
  //^^^
  // [analyzer] COMPILE_TIME_ERROR.UNDEFINED_OPERATOR
  // [cfe] The operator '[]=' isn't defined for the class 'C0'.
  E0(c0)[0];
  //    ^^^
  // [analyzer] COMPILE_TIME_ERROR.UNDEFINED_EXTENSION_OPERATOR
  // [cfe] Getter not found: '[]'.
  E0(c0)[0] = 0;

  c0[0] += 0;
  //^^^
  // [analyzer] COMPILE_TIME_ERROR.UNDEFINED_OPERATOR
  // [cfe] The operator '[]=' isn't defined for the class 'C0'.
  c0[0]++;
  //^^^
  // [analyzer] COMPILE_TIME_ERROR.UNDEFINED_OPERATOR
  // [cfe] The operator '[]=' isn't defined for the class 'C0'.

  E0(c0)[0] += 0;
  //    ^^^
  // [analyzer] COMPILE_TIME_ERROR.UNDEFINED_EXTENSION_OPERATOR
  // [cfe] The operator '[]' isn't defined for the class 'C0'.
  E0(c0)[0]++;
  //    ^^^
  // [analyzer] COMPILE_TIME_ERROR.UNDEFINED_EXTENSION_OPERATOR
  // [cfe] The operator '[]' isn't defined for the class 'C0'.
}

// Conflicting extensions.

class C1<T> {}

extension E1A<T> on C1<T> {
  int get m1 => 0;
  void set m2(int x) {}
  int operator [](int index) => 0;
}

extension E1B on C1<Object?> {
  void set m1(int x) {}
  int get m2 => 0;
  void operator []=(int index, int value) {}
}

void test1() {
  C1<int> c1a = C1(); // E1A is more specific.
  c1a.m1;

  c1a.m1 = 0;
  //  ^^
  // [analyzer] COMPILE_TIME_ERROR.ASSIGNMENT_TO_FINAL_NO_SETTER
  // [cfe] The setter 'm1' isn't defined for the class 'C1<int>'.

  c1a.m2;
  //  ^^
  // [analyzer] COMPILE_TIME_ERROR.UNDEFINED_GETTER
  // [cfe] The getter 'm2' isn't defined for the class 'C1<int>'.

  c1a.m2 = 0;

  c1a[0] = 0;
  // ^^^
  // [analyzer] COMPILE_TIME_ERROR.UNDEFINED_OPERATOR
  // [cfe] The operator '[]=' isn't defined for the class 'C1<int>'.

  c1a[0] += 0;
  // ^^^
  // [analyzer] COMPILE_TIME_ERROR.UNDEFINED_OPERATOR
  // [cfe] The operator '[]=' isn't defined for the class 'C1<int>'.

  c1a[0]++;
  // ^^^
  // [analyzer] COMPILE_TIME_ERROR.UNDEFINED_OPERATOR
  // [cfe] The operator '[]=' isn't defined for the class 'C1<int>'.

  c1a[0];

  C1<Object?> c1b = C1<Object?>(); // Neither extension is more specific.

  c1b.m1;
  //  ^^
  // [analyzer] COMPILE_TIME_ERROR.AMBIGUOUS_EXTENSION_MEMBER_ACCESS
  // [cfe] The property 'm1' is defined in multiple extensions for 'C1<Object?>' and neither is more specific.

  c1b.m1 = 0;
  //  ^^
  // [analyzer] COMPILE_TIME_ERROR.AMBIGUOUS_EXTENSION_MEMBER_ACCESS
  // [cfe] The property 'm1' is defined in multiple extensions for 'C1<Object?>' and neither is more specific.

  c1b.m1 += 0;
  //  ^^
  // [analyzer] COMPILE_TIME_ERROR.AMBIGUOUS_EXTENSION_MEMBER_ACCESS
  // [cfe] The property 'm1' is defined in multiple extensions for 'C1<Object?>' and neither is more specific.

  c1b.m1++;
  //  ^^
  // [analyzer] COMPILE_TIME_ERROR.AMBIGUOUS_EXTENSION_MEMBER_ACCESS
  // [cfe] The property 'm1' is defined in multiple extensions for 'C1<Object?>' and neither is more specific.

  c1b.m2;
  //  ^^
  // [analyzer] COMPILE_TIME_ERROR.AMBIGUOUS_EXTENSION_MEMBER_ACCESS
  // [cfe] The property 'm2' is defined in multiple extensions for 'C1<Object?>' and neither is more specific.

  c1b[0];
//^^^
// [analyzer] COMPILE_TIME_ERROR.AMBIGUOUS_EXTENSION_MEMBER_ACCESS
//   ^
// [cfe] The operator '[]' is defined in multiple extensions for 'C1<Object?>' and neither is more specific.

  c1b[0] = 0;
//^^^
// [analyzer] COMPILE_TIME_ERROR.AMBIGUOUS_EXTENSION_MEMBER_ACCESS
//   ^
// [cfe] The operator '[]=' is defined in multiple extensions for 'C1<Object?>' and neither is more specific.

  c1b[0] += 0;
//^^^
// [analyzer] COMPILE_TIME_ERROR.AMBIGUOUS_EXTENSION_MEMBER_ACCESS
//   ^
// [cfe] The operator '[]' is defined in multiple extensions for 'C1<Object?>' and neither is more specific.
//   ^
// [cfe] The operator '[]=' is defined in multiple extensions for 'C1<Object?>' and neither is more specific.

  c1b[0]++;
//^^^
// [analyzer] COMPILE_TIME_ERROR.AMBIGUOUS_EXTENSION_MEMBER_ACCESS
//   ^
// [cfe] The operator '[]' is defined in multiple extensions for 'C1<Object?>' and neither is more specific.
//   ^
// [cfe] The operator '[]=' is defined in multiple extensions for 'C1<Object?>' and neither is more specific.

  C1<Object> c1c = C1<Object>(); // E1A is more specific.

  c1c.m1 = 0;
  //  ^^
  // [analyzer] COMPILE_TIME_ERROR.ASSIGNMENT_TO_FINAL_NO_SETTER
  // [cfe] The setter 'm1' isn't defined for the class 'C1<Object>'.

  c1c.m2;
  //  ^^
  // [analyzer] COMPILE_TIME_ERROR.UNDEFINED_GETTER
  // [cfe] The getter 'm2' isn't defined for the class 'C1<Object>'.
}

// Getter on the extension itself.
class C2 {
  int get m1 => 0;
  void set m2(int x) {}
  int get mc => 0;
  void operator []=(int index, int value) {}
}

extension E2 on C2 {
  void set m1(int x) {}
  int get m2 => 0;
  String get me => "";
  int operator [](int index) => 0;

  void test2() {
    // Using `this.member` means using the `on` type.

    this.m1;
    this.m1 = 0;
    //   ^^
    // [analyzer] COMPILE_TIME_ERROR.ASSIGNMENT_TO_FINAL_NO_SETTER
    // [cfe] The setter 'm1' isn't defined for the class 'C2'.

    this.m2 = 0;
    this.m2;
    //   ^^
    // [analyzer] COMPILE_TIME_ERROR.UNDEFINED_GETTER
    // [cfe] The getter 'm2' isn't defined for the class 'C2'.

    this[0] = 0;
    this[0];
    //  ^^^
    // [analyzer] COMPILE_TIME_ERROR.UNDEFINED_OPERATOR
    // [cfe] The operator '[]' isn't defined for the class 'C2'.

    this[0] += 0;
    //  ^^^
    // [analyzer] COMPILE_TIME_ERROR.UNDEFINED_OPERATOR
    // [cfe] The operator '[]' isn't defined for the class 'C2'.

    this[0]++;
    //  ^^^
    // [analyzer] COMPILE_TIME_ERROR.UNDEFINED_OPERATOR
    // [cfe] The operator '[]' isn't defined for the class 'C2'.

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
