// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

class AAA {
  AAA() { }
  num AAAx_01;
  num AAAx_02;
  num AAAx_03;
  num AAAx_04;
  num AAAx_05;
  num AAAx_06;
  num AAAx_07;

  num AAAz_01;
  num AAAz_02;
  num AAAz_03;
  num AAAz_04;

  num AAAw_01;
  num AAAu_01;

  foo() {
    int a = 0;
    AAAw_01++;
    AAAu_01 += a * 123;
  }
}

class BBB extends AAA {
  BBB() : super() { }
  num get AAAz_01() { }
  num get AAAz_03() { }
  set AAAz_02(x) { }
  set AAAz_04(x) { }
}

class AA {
  AA() { }
  AAA aaa_;
}

class A {
  A() { }
  AA aa_;
  num Ay_01;
  num Ay_02;
  num Ay_03;
  num Ay_04;
  num Ay_05;
  num Ay_06;
}

class Main {

  static void main(num _marker_5, num _marker_6, num _marker_7, num _marker_8) {
    num _marker_0, _marker_1, _marker_2, _marker_3, _marker_4;
    num _marker_9, _marker__10, _marker__11, _marker__12;

    // Ensure that += is not generated as shim
    _marker_1 += _marker_0 + 1;

    // Ensure that -= is not generated as shim
    _marker_2 -= _marker_0 + 1;

    // Ensure that *= is not generated as shim
    _marker_3 *= _marker_0 + 1;

    // Ensure that /= is not generated as shim
    _marker_4 /= _marker_0 + 1;

    // Ensure that += is not generated as shim
    _marker_5 += _marker_0 + 1;

    // Ensure that -= is not generated as shim
    _marker_6 -= _marker_0 + 1;

    // Ensure that *= is not generated as shim
    _marker_7 *= _marker_0 + 1;

    // Ensure that /= is not generated as shim
    _marker_8 /= _marker_0 + 1;

    A _a_ = new A();

    // Should be optimized - simple field case.
    _a_.Ay_01++;
    _a_.Ay_02--;

     // all 'inline-able' operators
    int tmp = 123;
    _a_.Ay_03 += 2 * tmp * -123;
    _a_.Ay_04 -= 2 * tmp * -123;
    _a_.Ay_05 *= 2 * tmp * -123;
    _a_.Ay_06 /= 2 * tmp * -123;

    // All 'inline-able' operators with long path expressions.
    _a_.aa_.aaa_.AAAx_01 +=  2 * tmp / -1;
    _a_.aa_.aaa_.AAAx_02 -=  2 * tmp / -1;
    _a_.aa_.aaa_.AAAx_03 *=  2 * tmp / -1;
    _a_.aa_.aaa_.AAAx_04 /=  2 * tmp / -1;

    // add method to double check we are inlining correctly.
    _a_.aa_.aaa_.AAAx_05 +=  call(_a_.aa_.aaa_.AAAx_05) * tmp / -1;

    // Negative test cases.

    // _AAAz_01 must call shim (derived class has an a getter with same name as parent field).
    _a_.aa_.aaa_.AAAz_01++;

    // _AAAz_02 must call shim (derived class has an a setter with same name as parent field).
    _a_.aa_.aaa_.AAAz_02++;

    // _AAAz_03 must call shim (derived class has an a getter with same name as parent field).
    _a_.aa_.aaa_.AAAz_03 +=  22 * tmp / -1;

    // _AAAz_04 must call shim (derived class has an a getter with same name as parent field).
    _a_.aa_.aaa_.AAAz_04 +=  222 * tmp / -1;

    // Cannot be inlined % and ~
    _a_.aa_.aaa_.AAAx_06 %=  2 * tmp / -1;
    _a_.aa_.aaa_.AAAx_07 ~/=  2 * tmp / -1;

    _marker_9 |= _marker_0 & 1;

    _marker__10 &= _marker_0 & 1;

    _marker__11 ^= _marker_0 & 1;

    var _var_marker;
    _marker__12 |= _var_marker & 1;

    _var_marker |= _marker__12 & 1;
  }

  static double call(x) { return x; }
}

main() {
  Main.main(0, 0, 0, 0);
}
