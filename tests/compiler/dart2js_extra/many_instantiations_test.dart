// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Test generic instantiation with many type arguments.

import 'package:expect/expect.dart';

f1<T1>(T1 t1) => '$t1';
f2<T1, T2>(T1 t1, T2 t2) => '$t1$t2';
f3<T1, T2, T3>(T1 t1, T2 t2, T3 t3) => '$t1$t2$t3';
f4<T1, T2, T3, T4>(T1 t1, T2 t2, T3 t3, T4 t4) => '$t1$t2$t3$t4';
f5<T1, T2, T3, T4, T5>(T1 t1, T2 t2, T3 t3, T4 t4, T5 t5) => '$t1$t2$t3$t4$t5';
f6<T1, T2, T3, T4, T5, T6>(T1 t1, T2 t2, T3 t3, T4 t4, T5 t5, T6 t6) =>
    '$t1$t2$t3$t4$t5$t6';
f7<T1, T2, T3, T4, T5, T6, T7>(
        T1 t1, T2 t2, T3 t3, T4 t4, T5 t5, T6 t6, T7 t7) =>
    '$t1$t2$t3$t4$t5$t6$t7';
f8<T1, T2, T3, T4, T5, T6, T7, T8>(
        T1 t1, T2 t2, T3 t3, T4 t4, T5 t5, T6 t6, T7 t7, T8 t8) =>
    '$t1$t2$t3$t4$t5$t6$t7$t8';
f9<T1, T2, T3, T4, T5, T6, T7, T8, T9>(
        T1 t1, T2 t2, T3 t3, T4 t4, T5 t5, T6 t6, T7 t7, T8 t8, T9 t9) =>
    '$t1$t2$t3$t4$t5$t6$t7$t8$t9';
f10<T1, T2, T3, T4, T5, T6, T7, T8, T9, T10>(T1 t1, T2 t2, T3 t3, T4 t4, T5 t5,
        T6 t6, T7 t7, T8 t8, T9 t9, T10 t10) =>
    '$t1$t2$t3$t4$t5$t6$t7$t8$t9$t10';
f11<T1, T2, T3, T4, T5, T6, T7, T8, T9, T10, T11>(T1 t1, T2 t2, T3 t3, T4 t4,
        T5 t5, T6 t6, T7 t7, T8 t8, T9 t9, T10 t10, T11 t11) =>
    '$t1$t2$t3$t4$t5$t6$t7$t8$t9$t10$t11';
f12<T1, T2, T3, T4, T5, T6, T7, T8, T9, T10, T11, T12>(T1 t1, T2 t2, T3 t3,
        T4 t4, T5 t5, T6 t6, T7 t7, T8 t8, T9 t9, T10 t10, T11 t11, T12 t12) =>
    '$t1$t2$t3$t4$t5$t6$t7$t8$t9$t10$t11$t12';
f13<T1, T2, T3, T4, T5, T6, T7, T8, T9, T10, T11, T12, T13>(
        T1 t1,
        T2 t2,
        T3 t3,
        T4 t4,
        T5 t5,
        T6 t6,
        T7 t7,
        T8 t8,
        T9 t9,
        T10 t10,
        T11 t11,
        T12 t12,
        T13 t13) =>
    '$t1$t2$t3$t4$t5$t6$t7$t8$t9$t10$t11$t12$t13';
f14<T1, T2, T3, T4, T5, T6, T7, T8, T9, T10, T11, T12, T13, T14>(
        T1 t1,
        T2 t2,
        T3 t3,
        T4 t4,
        T5 t5,
        T6 t6,
        T7 t7,
        T8 t8,
        T9 t9,
        T10 t10,
        T11 t11,
        T12 t12,
        T13 t13,
        T14 t14) =>
    '$t1$t2$t3$t4$t5$t6$t7$t8$t9$t10$t11$t12$t13$t14';
f15<T1, T2, T3, T4, T5, T6, T7, T8, T9, T10, T11, T12, T13, T14, T15>(
        T1 t1,
        T2 t2,
        T3 t3,
        T4 t4,
        T5 t5,
        T6 t6,
        T7 t7,
        T8 t8,
        T9 t9,
        T10 t10,
        T11 t11,
        T12 t12,
        T13 t13,
        T14 t14,
        T15 t15) =>
    '$t1$t2$t3$t4$t5$t6$t7$t8$t9$t10$t11$t12$t13$t14$t15';
f16<T1, T2, T3, T4, T5, T6, T7, T8, T9, T10, T11, T12, T13, T14, T15, T16>(
        T1 t1,
        T2 t2,
        T3 t3,
        T4 t4,
        T5 t5,
        T6 t6,
        T7 t7,
        T8 t8,
        T9 t9,
        T10 t10,
        T11 t11,
        T12 t12,
        T13 t13,
        T14 t14,
        T15 t15,
        T16 t16) =>
    '$t1$t2$t3$t4$t5$t6$t7$t8$t9$t10$t11$t12$t13$t14$t15$t16';
f17<T1, T2, T3, T4, T5, T6, T7, T8, T9, T10, T11, T12, T13, T14, T15, T16, T17>(
        T1 t1,
        T2 t2,
        T3 t3,
        T4 t4,
        T5 t5,
        T6 t6,
        T7 t7,
        T8 t8,
        T9 t9,
        T10 t10,
        T11 t11,
        T12 t12,
        T13 t13,
        T14 t14,
        T15 t15,
        T16 t16,
        T17 t17) =>
    '$t1$t2$t3$t4$t5$t6$t7$t8$t9$t10$t11$t12$t13$t14$t15$t16$t17';
f18<T1, T2, T3, T4, T5, T6, T7, T8, T9, T10, T11, T12, T13, T14, T15, T16, T17,
            T18>(
        T1 t1,
        T2 t2,
        T3 t3,
        T4 t4,
        T5 t5,
        T6 t6,
        T7 t7,
        T8 t8,
        T9 t9,
        T10 t10,
        T11 t11,
        T12 t12,
        T13 t13,
        T14 t14,
        T15 t15,
        T16 t16,
        T17 t17,
        T18 t18) =>
    '$t1$t2$t3$t4$t5$t6$t7$t8$t9$t10$t11$t12$t13$t14$t15$t16$t17$t18';
f19<T1, T2, T3, T4, T5, T6, T7, T8, T9, T10, T11, T12, T13, T14, T15, T16, T17,
            T18, T19>(
        T1 t1,
        T2 t2,
        T3 t3,
        T4 t4,
        T5 t5,
        T6 t6,
        T7 t7,
        T8 t8,
        T9 t9,
        T10 t10,
        T11 t11,
        T12 t12,
        T13 t13,
        T14 t14,
        T15 t15,
        T16 t16,
        T17 t17,
        T18 t18,
        T19 t19) =>
    '$t1$t2$t3$t4$t5$t6$t7$t8$t9$t10$t11$t12$t13$t14$t15$t16$t17$t18$t19';
f20<T1, T2, T3, T4, T5, T6, T7, T8, T9, T10, T11, T12, T13, T14, T15, T16, T17,
            T18, T19, T20>(
        T1 t1,
        T2 t2,
        T3 t3,
        T4 t4,
        T5 t5,
        T6 t6,
        T7 t7,
        T8 t8,
        T9 t9,
        T10 t10,
        T11 t11,
        T12 t12,
        T13 t13,
        T14 t14,
        T15 t15,
        T16 t16,
        T17 t17,
        T18 t18,
        T19 t19,
        T20 t20) =>
    '$t1$t2$t3$t4$t5$t6$t7$t8$t9$t10$t11$t12$t13$t14$t15$t16$t17$t18$t19$t20';
f21<T1, T2, T3, T4, T5, T6, T7, T8, T9, T10, T11, T12, T13, T14, T15, T16, T17,
            T18, T19, T20, T21>(
        T1 t1,
        T2 t2,
        T3 t3,
        T4 t4,
        T5 t5,
        T6 t6,
        T7 t7,
        T8 t8,
        T9 t9,
        T10 t10,
        T11 t11,
        T12 t12,
        T13 t13,
        T14 t14,
        T15 t15,
        T16 t16,
        T17 t17,
        T18 t18,
        T19 t19,
        T20 t20,
        T21 t21) =>
    '$t1$t2$t3$t4$t5$t6$t7$t8$t9$t10$t11$t12$t13$t14$t15$t16$t17$t18$t19$t20$t21';

m1(Function(int) f) => f(1);
m2(Function(int, int) f) => f(1, 2);
m3(Function(int, int, int) f) => f(1, 2, 3);
m4(Function(int, int, int, int) f) => f(1, 2, 3, 4);
m5(Function(int, int, int, int, int) f) => f(1, 2, 3, 4, 5);
m6(Function(int, int, int, int, int, int) f) => f(1, 2, 3, 4, 5, 6);
m7(Function(int, int, int, int, int, int, int) f) => f(1, 2, 3, 4, 5, 6, 7);
m8(Function(int, int, int, int, int, int, int, int) f) =>
    f(1, 2, 3, 4, 5, 6, 7, 8);
m9(Function(int, int, int, int, int, int, int, int, int) f) =>
    f(1, 2, 3, 4, 5, 6, 7, 8, 9);
m10(Function(int, int, int, int, int, int, int, int, int, int) f) =>
    f(1, 2, 3, 4, 5, 6, 7, 8, 9, 10);
m11(Function(int, int, int, int, int, int, int, int, int, int, int) f) =>
    f(1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11);
m12(Function(int, int, int, int, int, int, int, int, int, int, int, int) f) =>
    f(1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12);
m13(
        Function(
                int, int, int, int, int, int, int, int, int, int, int, int, int)
            f) =>
    f(1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13);
m14(
        Function(int, int, int, int, int, int, int, int, int, int, int, int,
                int, int)
            f) =>
    f(1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14);
m15(
        Function(int, int, int, int, int, int, int, int, int, int, int, int,
                int, int, int)
            f) =>
    f(1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15);
m16(
        Function(int, int, int, int, int, int, int, int, int, int, int, int,
                int, int, int, int)
            f) =>
    f(1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16);
m17(
        Function(int, int, int, int, int, int, int, int, int, int, int, int,
                int, int, int, int, int)
            f) =>
    f(1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17);
m18(
        Function(int, int, int, int, int, int, int, int, int, int, int, int,
                int, int, int, int, int, int)
            f) =>
    f(1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18);
m19(
        Function(int, int, int, int, int, int, int, int, int, int, int, int,
                int, int, int, int, int, int, int)
            f) =>
    f(1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19);
m20(
        Function(int, int, int, int, int, int, int, int, int, int, int, int,
                int, int, int, int, int, int, int, int)
            f) =>
    f(1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20);
m21(
        Function(int, int, int, int, int, int, int, int, int, int, int, int,
                int, int, int, int, int, int, int, int, int)
            f) =>
    f(1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20,
        21);

main() {
  Expect.equals('1', m1(f1));
  Expect.equals('12', m2(f2));
  Expect.equals('123', m3(f3));
  Expect.equals('1234', m4(f4));
  Expect.equals('12345', m5(f5));
  Expect.equals('123456', m6(f6));
  Expect.equals('1234567', m7(f7));
  Expect.equals('12345678', m8(f8));
  Expect.equals('123456789', m9(f9));
  Expect.equals('12345678910', m10(f10));
  Expect.equals('1234567891011', m11(f11));
  Expect.equals('123456789101112', m12(f12));
  Expect.equals('12345678910111213', m13(f13));
  Expect.equals('1234567891011121314', m14(f14));
  Expect.equals('123456789101112131415', m15(f15));
  Expect.equals('12345678910111213141516', m16(f16));
  Expect.equals('1234567891011121314151617', m17(f17));
  Expect.equals('123456789101112131415161718', m18(f18));
  Expect.equals('12345678910111213141516171819', m19(f19));
  Expect.equals('1234567891011121314151617181920', m20(f20));
  Expect.equals('123456789101112131415161718192021', m21(f21)); //# 01: ok
}
