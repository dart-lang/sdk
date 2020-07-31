// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Introduces a context with double as type.
void notDouble([double value = 0.0]) {
  if (value != 0.0) throw "unreachable";
}

main() {
  notDouble(
    // Large decimal numbers which are not representable as doubles.
    9007199254740993, //     2^53+2^0      //# 001: compile-time error
    18014398509481983, //    2^54-2^0      //# 002: compile-time error
    18014398509481985, //    2^54+2^0      //# 003: compile-time error
    18014398509481986, //    2^54+2^1      //# 004: compile-time error
    4611686018427387903, //  2^62-2^0      //# 005: compile-time error
    4611686018427387902, //  2^62-2^1      //# 006: compile-time error
    4611686018427387900, //  2^62-2^2      //# 007: compile-time error
    4611686018427387896, //  2^62-2^3      //# 008: compile-time error
    4611686018427387888, //  2^62-2^4      //# 009: compile-time error
    4611686018427387872, //  2^62-2^5      //# 010: compile-time error
    4611686018427387840, //  2^62-2^6      //# 011: compile-time error
    4611686018427387776, //  2^62-2^7      //# 012: compile-time error
    4611686018427387648, //  2^62-2^8      //# 013: compile-time error
    4611686018427387905, //  2^62+2^0      //# 014: compile-time error
    4611686018427387906, //  2^62+2^1      //# 015: compile-time error
    4611686018427387908, //  2^62+2^2      //# 016: compile-time error
    4611686018427387912, //  2^62+2^3      //# 017: compile-time error
    4611686018427387920, //  2^62+2^4      //# 018: compile-time error
    4611686018427387936, //  2^62+2^5      //# 019: compile-time error
    4611686018427387968, //  2^62+2^6      //# 020: compile-time error
    4611686018427388032, //  2^62+2^7      //# 021: compile-time error
    4611686018427388160, //  2^62+2^8      //# 022: compile-time error
    4611686018427388416, //  2^62+2^9      //# 023: compile-time error
    9223372036854775807, //  2^63-2^0      //# 024: compile-time error
    9223372036854775806, //  2^63-2^1      //# 025: compile-time error
    9223372036854775804, //  2^63-2^2      //# 026: compile-time error
    9223372036854775800, //  2^63-2^3      //# 027: compile-time error
    9223372036854775792, //  2^63-2^4      //# 028: compile-time error
    9223372036854775776, //  2^63-2^5      //# 029: compile-time error
    9223372036854775744, //  2^63-2^6      //# 030: compile-time error
    9223372036854775680, //  2^63-2^7      //# 031: compile-time error
    9223372036854775552, //  2^63-2^8      //# 032: compile-time error
    9223372036854775296, //  2^63-2^9      //# 033: compile-time error
    9223372036854775809, //  2^63+2^0      //# 034: compile-time error
    9223372036854775810, //  2^63+2^1      //# 035: compile-time error
    9223372036854775812, //  2^63+2^2      //# 036: compile-time error
    9223372036854775816, //  2^63+2^3      //# 037: compile-time error
    9223372036854775824, //  2^63+2^4      //# 038: compile-time error
    9223372036854775840, //  2^63+2^5      //# 039: compile-time error
    9223372036854775872, //  2^63+2^6      //# 040: compile-time error
    9223372036854775936, //  2^63+2^7      //# 041: compile-time error
    9223372036854776064, //  2^63+2^8      //# 042: compile-time error
    9223372036854776320, //  2^63+2^9      //# 043: compile-time error
    9223372036854776832, //  2^63+2^10     //# 044: compile-time error
    18446744073709551615, // 2^64-2^0      //# 045: compile-time error
    18446744073709551614, // 2^64-2^1      //# 046: compile-time error
    18446744073709551612, // 2^64-2^2      //# 047: compile-time error
    18446744073709551608, // 2^64-2^3      //# 048: compile-time error
    18446744073709551600, // 2^64-2^4      //# 049: compile-time error
    18446744073709551584, // 2^64-2^5      //# 050: compile-time error
    18446744073709551552, // 2^64-2^6      //# 051: compile-time error
    18446744073709551488, // 2^64-2^7      //# 052: compile-time error
    18446744073709551360, // 2^64-2^8      //# 053: compile-time error
    18446744073709551104, // 2^64-2^9      //# 054: compile-time error
    18446744073709550592, // 2^64-2^10     //# 055: compile-time error
    18446744073709551617, // 2^64+2^0      //# 056: compile-time error
    18446744073709551618, // 2^64+2^1      //# 057: compile-time error
    18446744073709551620, // 2^64+2^2      //# 058: compile-time error
    18446744073709551624, // 2^64+2^3      //# 059: compile-time error
    18446744073709551632, // 2^64+2^4      //# 060: compile-time error
    18446744073709551648, // 2^64+2^5      //# 061: compile-time error
    18446744073709551680, // 2^64+2^6      //# 062: compile-time error
    18446744073709551744, // 2^64+2^7      //# 063: compile-time error
    18446744073709551872, // 2^64+2^8      //# 064: compile-time error
    18446744073709552128, // 2^64+2^9      //# 065: compile-time error
    18446744073709552640, // 2^64+2^10     //# 066: compile-time error
    18446744073709553664, // 2^64+2^11     //# 067: compile-time error
    179769313486231570814527423731704356798070567525844996598917476803157260780028538760589558632766878171540458953514382464234321326889464182768467546703537516986049910576551282076245490090389328944075868508455133942304583236903222948165808559332123348274797826204144723168738177180919299881250404026184124858367, // maxValue - 1 //# 068 : compile-time error
    179769313486231570814527423731704356798070567525844996598917476803157260780028538760589558632766878171540458953514382464234321326889464182768467546703537516986049910576551282076245490090389328944075868508455133942304583236903222948165808559332123348274797826204144723168738177180919299881250404026184124858369, // maxValue + 1 //# 069 : compile-time error
    359538626972463141629054847463408713596141135051689993197834953606314521560057077521179117265533756343080917907028764928468642653778928365536935093407075033972099821153102564152490980180778657888151737016910267884609166473806445896331617118664246696549595652408289446337476354361838599762500808052368249716734, // maxValue * 2 //# 070P : compile-time error

    // Negative numbers too.
    -9007199254740993, //     -(2^53+2^0)  //# 071: compile-time error
    -18014398509481983, //    -(2^54-2^0)  //# 072: compile-time error
    -18014398509481985, //    -(2^54+2^0)  //# 073: compile-time error
    -18014398509481986, //    -(2^54+2^1)  //# 074: compile-time error
    -4611686018427387903, //  -(2^62-2^0)  //# 075: compile-time error
    -4611686018427387902, //  -(2^62-2^1)  //# 076: compile-time error
    -4611686018427387900, //  -(2^62-2^2)  //# 077: compile-time error
    -4611686018427387896, //  -(2^62-2^3)  //# 078: compile-time error
    -4611686018427387888, //  -(2^62-2^4)  //# 079: compile-time error
    -4611686018427387872, //  -(2^62-2^5)  //# 080: compile-time error
    -4611686018427387840, //  -(2^62-2^6)  //# 081: compile-time error
    -4611686018427387776, //  -(2^62-2^7)  //# 082: compile-time error
    -4611686018427387648, //  -(2^62-2^8)  //# 083: compile-time error
    -4611686018427387905, //  -(2^62+2^0)  //# 084: compile-time error
    -4611686018427387906, //  -(2^62+2^1)  //# 085: compile-time error
    -4611686018427387908, //  -(2^62+2^2)  //# 086: compile-time error
    -4611686018427387912, //  -(2^62+2^3)  //# 087: compile-time error
    -4611686018427387920, //  -(2^62+2^4)  //# 088: compile-time error
    -4611686018427387936, //  -(2^62+2^5)  //# 089: compile-time error
    -4611686018427387968, //  -(2^62+2^6)  //# 090: compile-time error
    -4611686018427388032, //  -(2^62+2^7)  //# 091: compile-time error
    -4611686018427388160, //  -(2^62+2^8)  //# 092: compile-time error
    -4611686018427388416, //  -(2^62+2^9)  //# 093: compile-time error
    -9223372036854775807, //  -(2^63-2^0)  //# 094: compile-time error
    -9223372036854775806, //  -(2^63-2^1)  //# 095: compile-time error
    -9223372036854775804, //  -(2^63-2^2)  //# 096: compile-time error
    -9223372036854775800, //  -(2^63-2^3)  //# 097: compile-time error
    -9223372036854775792, //  -(2^63-2^4)  //# 098: compile-time error
    -9223372036854775776, //  -(2^63-2^5)  //# 099: compile-time error
    -9223372036854775744, //  -(2^63-2^6)  //# 100: compile-time error
    -9223372036854775680, //  -(2^63-2^7)  //# 101: compile-time error
    -9223372036854775552, //  -(2^63-2^8)  //# 102: compile-time error
    -9223372036854775296, //  -(2^63-2^9)  //# 103: compile-time error
    -9223372036854775809, //  -(2^63+2^0)  //# 104: compile-time error
    -9223372036854775810, //  -(2^63+2^1)  //# 105: compile-time error
    -9223372036854775812, //  -(2^63+2^2)  //# 106: compile-time error
    -9223372036854775816, //  -(2^63+2^3)  //# 107: compile-time error
    -9223372036854775824, //  -(2^63+2^4)  //# 108: compile-time error
    -9223372036854775840, //  -(2^63+2^5)  //# 109: compile-time error
    -9223372036854775872, //  -(2^63+2^6)  //# 110: compile-time error
    -9223372036854775936, //  -(2^63+2^7)  //# 111: compile-time error
    -9223372036854776064, //  -(2^63+2^8)  //# 112: compile-time error
    -9223372036854776320, //  -(2^63+2^9)  //# 113: compile-time error
    -9223372036854776832, //  -(2^63+2^10) //# 114: compile-time error
    -18446744073709551615, // -(2^64-2^0)  //# 115: compile-time error
    -18446744073709551614, // -(2^64-2^1)  //# 116: compile-time error
    -18446744073709551612, // -(2^64-2^2)  //# 117: compile-time error
    -18446744073709551608, // -(2^64-2^3)  //# 118: compile-time error
    -18446744073709551600, // -(2^64-2^4)  //# 119: compile-time error
    -18446744073709551584, // -(2^64-2^5)  //# 120: compile-time error
    -18446744073709551552, // -(2^64-2^6)  //# 121: compile-time error
    -18446744073709551488, // -(2^64-2^7)  //# 122: compile-time error
    -18446744073709551360, // -(2^64-2^8)  //# 123: compile-time error
    -18446744073709551104, // -(2^64-2^9)  //# 124: compile-time error
    -18446744073709550592, // -(2^64-2^10) //# 125: compile-time error
    -18446744073709551617, // -(2^64+2^0)  //# 126: compile-time error
    -18446744073709551618, // -(2^64+2^1)  //# 127: compile-time error
    -18446744073709551620, // -(2^64+2^2)  //# 128: compile-time error
    -18446744073709551624, // -(2^64+2^3)  //# 129: compile-time error
    -18446744073709551632, // -(2^64+2^4)  //# 130: compile-time error
    -18446744073709551648, // -(2^64+2^5)  //# 131: compile-time error
    -18446744073709551680, // -(2^64+2^6)  //# 132: compile-time error
    -18446744073709551744, // -(2^64+2^7)  //# 133: compile-time error
    -18446744073709551872, // -(2^64+2^8)  //# 134: compile-time error
    -18446744073709552128, // -(2^64+2^9)  //# 135: compile-time error
    -18446744073709552640, // -(2^64+2^10) //# 136: compile-time error
    -18446744073709553664, // -(2^64+2^11) //# 137: compile-time error
    -179769313486231570814527423731704356798070567525844996598917476803157260780028538760589558632766878171540458953514382464234321326889464182768467546703537516986049910576551282076245490090389328944075868508455133942304583236903222948165808559332123348274797826204144723168738177180919299881250404026184124858367, // -(maxValue - 1) //# 138 : compile-time error
    -179769313486231570814527423731704356798070567525844996598917476803157260780028538760589558632766878171540458953514382464234321326889464182768467546703537516986049910576551282076245490090389328944075868508455133942304583236903222948165808559332123348274797826204144723168738177180919299881250404026184124858369, // -(maxValue + 1) //# 139 : compile-time error
    -359538626972463141629054847463408713596141135051689993197834953606314521560057077521179117265533756343080917907028764928468642653778928365536935093407075033972099821153102564152490980180778657888151737016910267884609166473806445896331617118664246696549595652408289446337476354361838599762500808052368249716734, // -(maxValue * 2) //# 140B : compile-time error

    // Same numbers as hexadecimal literals.
    0x20000000000001, //    2^53+2^0      //# 141: compile-time error
    0x3fffffffffffff, //    2^54-2^0      //# 142: compile-time error
    0x40000000000001, //    2^54+2^0      //# 143: compile-time error
    0x40000000000002, //    2^54+2^1      //# 144: compile-time error
    0x3fffffffffffffff, //  2^62-2^0      //# 145: compile-time error
    0x3ffffffffffffffe, //  2^62-2^1      //# 146: compile-time error
    0x3ffffffffffffffc, //  2^62-2^2      //# 147: compile-time error
    0x3ffffffffffffff8, //  2^62-2^3      //# 148: compile-time error
    0x3ffffffffffffff0, //  2^62-2^4      //# 149: compile-time error
    0x3fffffffffffffe0, //  2^62-2^5      //# 150: compile-time error
    0x3fffffffffffffc0, //  2^62-2^6      //# 151: compile-time error
    0x3fffffffffffff80, //  2^62-2^7      //# 152: compile-time error
    0x3fffffffffffff00, //  2^62-2^8      //# 153: compile-time error
    0x4000000000000001, //  2^62+2^0      //# 154: compile-time error
    0x4000000000000002, //  2^62+2^1      //# 155: compile-time error
    0x4000000000000004, //  2^62+2^2      //# 156: compile-time error
    0x4000000000000008, //  2^62+2^3      //# 157: compile-time error
    0x4000000000000010, //  2^62+2^4      //# 158: compile-time error
    0x4000000000000020, //  2^62+2^5      //# 159: compile-time error
    0x4000000000000040, //  2^62+2^6      //# 160: compile-time error
    0x4000000000000080, //  2^62+2^7      //# 161: compile-time error
    0x4000000000000100, //  2^62+2^8      //# 162: compile-time error
    0x4000000000000200, //  2^62+2^9      //# 163: compile-time error
    0x7fffffffffffffff, //  2^63-2^0      //# 164: compile-time error
    0x7ffffffffffffffe, //  2^63-2^1      //# 165: compile-time error
    0x7ffffffffffffffc, //  2^63-2^2      //# 166: compile-time error
    0x7ffffffffffffff8, //  2^63-2^3      //# 167: compile-time error
    0x7ffffffffffffff0, //  2^63-2^4      //# 168: compile-time error
    0x7fffffffffffffe0, //  2^63-2^5      //# 169: compile-time error
    0x7fffffffffffffc0, //  2^63-2^6      //# 170: compile-time error
    0x7fffffffffffff80, //  2^63-2^7      //# 171: compile-time error
    0x7fffffffffffff00, //  2^63-2^8      //# 172: compile-time error
    0x7ffffffffffffe00, //  2^63-2^9      //# 173: compile-time error
    0x8000000000000001, //  2^63+2^0      //# 174: compile-time error
    0x8000000000000002, //  2^63+2^1      //# 175: compile-time error
    0x8000000000000004, //  2^63+2^2      //# 176: compile-time error
    0x8000000000000008, //  2^63+2^3      //# 177: compile-time error
    0x8000000000000010, //  2^63+2^4      //# 178: compile-time error
    0x8000000000000020, //  2^63+2^5      //# 179: compile-time error
    0x8000000000000040, //  2^63+2^6      //# 180: compile-time error
    0x8000000000000080, //  2^63+2^7      //# 181: compile-time error
    0x8000000000000100, //  2^63+2^8      //# 182: compile-time error
    0x8000000000000200, //  2^63+2^9      //# 183: compile-time error
    0x8000000000000400, //  2^63+2^10     //# 184: compile-time error
    0xffffffffffffffff, //  2^64-2^0      //# 185: compile-time error
    0xfffffffffffffffe, //  2^64-2^1      //# 186: compile-time error
    0xfffffffffffffffc, //  2^64-2^2      //# 187: compile-time error
    0xfffffffffffffff8, //  2^64-2^3      //# 188: compile-time error
    0xfffffffffffffff0, //  2^64-2^4      //# 189: compile-time error
    0xffffffffffffffe0, //  2^64-2^5      //# 190: compile-time error
    0xffffffffffffffc0, //  2^64-2^6      //# 191: compile-time error
    0xffffffffffffff80, //  2^64-2^7      //# 192: compile-time error
    0xffffffffffffff00, //  2^64-2^8      //# 193: compile-time error
    0xfffffffffffffe00, //  2^64-2^9      //# 194: compile-time error
    0xfffffffffffffc00, //  2^64-2^10     //# 195: compile-time error
    0x10000000000000001, // 2^64+2^0      //# 196: compile-time error
    0x10000000000000002, // 2^64+2^1      //# 197: compile-time error
    0x10000000000000004, // 2^64+2^2      //# 198: compile-time error
    0x10000000000000008, // 2^64+2^3      //# 199: compile-time error
    0x10000000000000010, // 2^64+2^4      //# 200: compile-time error
    0x10000000000000020, // 2^64+2^5      //# 201: compile-time error
    0x10000000000000040, // 2^64+2^6      //# 202: compile-time error
    0x10000000000000080, // 2^64+2^7      //# 203: compile-time error
    0x10000000000000100, // 2^64+2^8      //# 204: compile-time error
    0x10000000000000200, // 2^64+2^9      //# 205: compile-time error
    0x10000000000000400, // 2^64+2^10     //# 206: compile-time error
    0x10000000000000800, // 2^64+2^11     //# 207: compile-time error
    0xfffffffffffff7ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff, // maxValue - 1 //# 208 : compile-time error
    0xfffffffffffff800000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000001, // maxValue + 1 //# 209 : compile-time error
    0x1fffffffffffff000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000001, // maxValue * 2 //# 210V : compile-time error

    -0x20000000000001, //    -(2^53+2^0)      //# 211: compile-time error
    -0x3fffffffffffff, //    -(2^54-2^0)      //# 212: compile-time error
    -0x40000000000001, //    -(2^54+2^0)      //# 213: compile-time error
    -0x40000000000002, //    -(2^54+2^1)      //# 214: compile-time error
    -0x3fffffffffffffff, //  -(2^62-2^0)      //# 215: compile-time error
    -0x3ffffffffffffffe, //  -(2^62-2^1)      //# 216: compile-time error
    -0x3ffffffffffffffc, //  -(2^62-2^2)      //# 217: compile-time error
    -0x3ffffffffffffff8, //  -(2^62-2^3)      //# 218: compile-time error
    -0x3ffffffffffffff0, //  -(2^62-2^4)      //# 219: compile-time error
    -0x3fffffffffffffe0, //  -(2^62-2^5)      //# 220: compile-time error
    -0x3fffffffffffffc0, //  -(2^62-2^6)      //# 221: compile-time error
    -0x3fffffffffffff80, //  -(2^62-2^7)      //# 222: compile-time error
    -0x3fffffffffffff00, //  -(2^62-2^8)      //# 223: compile-time error
    -0x4000000000000001, //  -(2^62+2^0)      //# 224: compile-time error
    -0x4000000000000002, //  -(2^62+2^1)      //# 225: compile-time error
    -0x4000000000000004, //  -(2^62+2^2)      //# 226: compile-time error
    -0x4000000000000008, //  -(2^62+2^3)      //# 227: compile-time error
    -0x4000000000000010, //  -(2^62+2^4)      //# 228: compile-time error
    -0x4000000000000020, //  -(2^62+2^5)      //# 229: compile-time error
    -0x4000000000000040, //  -(2^62+2^6)      //# 230: compile-time error
    -0x4000000000000080, //  -(2^62+2^7)      //# 231: compile-time error
    -0x4000000000000100, //  -(2^62+2^8)      //# 232: compile-time error
    -0x4000000000000200, //  -(2^62+2^9)      //# 233: compile-time error
    -0x7fffffffffffffff, //  -(2^63-2^0)      //# 234: compile-time error
    -0x7ffffffffffffffe, //  -(2^63-2^1)      //# 235: compile-time error
    -0x7ffffffffffffffc, //  -(2^63-2^2)      //# 236: compile-time error
    -0x7ffffffffffffff8, //  -(2^63-2^3)      //# 237: compile-time error
    -0x7ffffffffffffff0, //  -(2^63-2^4)      //# 238: compile-time error
    -0x7fffffffffffffe0, //  -(2^63-2^5)      //# 239: compile-time error
    -0x7fffffffffffffc0, //  -(2^63-2^6)      //# 240: compile-time error
    -0x7fffffffffffff80, //  -(2^63-2^7)      //# 241: compile-time error
    -0x7fffffffffffff00, //  -(2^63-2^8)      //# 242: compile-time error
    -0x7ffffffffffffe00, //  -(2^63-2^9)      //# 243: compile-time error
    -0x8000000000000001, //  -(2^63+2^0)      //# 244: compile-time error
    -0x8000000000000002, //  -(2^63+2^1)      //# 245: compile-time error
    -0x8000000000000004, //  -(2^63+2^2)      //# 246: compile-time error
    -0x8000000000000008, //  -(2^63+2^3)      //# 247: compile-time error
    -0x8000000000000010, //  -(2^63+2^4)      //# 248: compile-time error
    -0x8000000000000020, //  -(2^63+2^5)      //# 249: compile-time error
    -0x8000000000000040, //  -(2^63+2^6)      //# 250: compile-time error
    -0x8000000000000080, //  -(2^63+2^7)      //# 251: compile-time error
    -0x8000000000000100, //  -(2^63+2^8)      //# 252: compile-time error
    -0x8000000000000200, //  -(2^63+2^9)      //# 253: compile-time error
    -0x8000000000000400, //  -(2^63+2^10)     //# 254: compile-time error
    -0xffffffffffffffff, //  -(2^64-2^0)      //# 255: compile-time error
    -0xfffffffffffffffe, //  -(2^64-2^1)      //# 256: compile-time error
    -0xfffffffffffffffc, //  -(2^64-2^2)      //# 257: compile-time error
    -0xfffffffffffffff8, //  -(2^64-2^3)      //# 258: compile-time error
    -0xfffffffffffffff0, //  -(2^64-2^4)      //# 259: compile-time error
    -0xffffffffffffffe0, //  -(2^64-2^5)      //# 260: compile-time error
    -0xffffffffffffffc0, //  -(2^64-2^6)      //# 261: compile-time error
    -0xffffffffffffff80, //  -(2^64-2^7)      //# 262: compile-time error
    -0xffffffffffffff00, //  -(2^64-2^8)      //# 263: compile-time error
    -0xfffffffffffffe00, //  -(2^64-2^9)      //# 264: compile-time error
    -0xfffffffffffffc00, //  -(2^64-2^10)     //# 265: compile-time error
    -0x10000000000000001, // -(2^64+2^0)      //# 266: compile-time error
    -0x10000000000000002, // -(2^64+2^1)      //# 267: compile-time error
    -0x10000000000000004, // -(2^64+2^2)      //# 268: compile-time error
    -0x10000000000000008, // -(2^64+2^3)      //# 269: compile-time error
    -0x10000000000000010, // -(2^64+2^4)      //# 270: compile-time error
    -0x10000000000000020, // -(2^64+2^5)      //# 271: compile-time error
    -0x10000000000000040, // -(2^64+2^6)      //# 272: compile-time error
    -0x10000000000000080, // -(2^64+2^7)      //# 273: compile-time error
    -0x10000000000000100, // -(2^64+2^8)      //# 274: compile-time error
    -0x10000000000000200, // -(2^64+2^9)      //# 275: compile-time error
    -0x10000000000000400, // -(2^64+2^10)     //# 276: compile-time error
    -0x10000000000000800, // -(2^64+2^11)     //# 277: compile-time error
    -0xfffffffffffff7ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff, // -(maxValue - 1) //# 278 : compile-time error
    -0xfffffffffffff800000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000001, // -(maxValue + 1) //# 279 : compile-time error
    -0x1fffffffffffff000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000001, // -(maxValue * 2) //# 280 : compile-time error
  );
}
