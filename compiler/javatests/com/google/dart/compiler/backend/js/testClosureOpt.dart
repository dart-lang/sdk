// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

class A {
    A(this.x);

    int x;

    testMethod(int arg1) {
        int s1 = 1;
        {
            int s2 = 2;
            {
                int s3 = 3;
                {
                    int s4 = 4;

                    var _fn_0 = int () => 0; // hoisted

                    var _fn_1 = int (p1) => p1; // hoisted

                    var _fn_2 = int (p1, p2) => p1 + p2; // hoisted

                    var _fn_3 = int (p1, p2, p3) => p1 + p2 + p3; // hoisted

                    var _fn_4 = int (p1, p2, p3, p4) => p1 + p2 + p3 + p4; // hoisted


                    var _fn_5 = int () => s1; // bind 1-0

                    var _fn_6 = int () => s1 + s2; // bind 2-0

                    var _fn_7 = int () => s1 + s2 + s3; // bind 3-0

                    var _fn_8 = int () => s1 + s2 + s3 + s4; // bind


                    var _fn_9 = int (p1) => p1 + s1; // bind 1-1

                    var _fn_A = int (p1, p2) => p1 + p2 + s1 + s2; // bind 2-2

                    var _fn_B = int (p1, p2, p3) => p1 + p2 + p3 + s1 + s2 + s3; // bind 3-3

                    // bind
                    var _fn_C = int (p1, p2, p3, p4) => p1 + p2 + p3 + p4 + s1 + s2 + s3 + s4;


                    // cannot inline - named args
                    var _fn_D = int (p1, [n1 = 20]) => p1 + s1 + n1;

                    var _fn_E = int (p1) => p1 + s1 + this.x;

                    var _fn_F = int (p1) => p1 + s1 + arg1;
                }
            }
        }
    }
}

class Main {
  static void main() {
    A a = new A(1);
    a.testMethod(1);
  }
}
