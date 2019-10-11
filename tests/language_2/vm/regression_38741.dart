// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// VMOptions=--deterministic

// Found by DartFuzzing: would fail during deopt:
// https://github.com/dart-lang/sdk/issues/38741

import 'dart:async';
import 'dart:cli';
import 'dart:collection';
import 'dart:convert';
import 'dart:core';
import 'dart:io';
import 'dart:isolate';
import 'dart:math';
import 'dart:typed_data';

Int64List var0 = new Int64List(13);
Uint32List var1 = Uint32List.fromList(Uint8List.fromList(new Uint64List(32)));
Int8List var2 = Int8List.fromList(new Int16List(28));
Uint8List var3 = new Uint8List(5);
Uint8ClampedList var4 =
    Uint8ClampedList.fromList(Int64List.fromList(new Int32List(36)));
Int16List var5 = Int16List.fromList(
    Int16List.fromList(Uint32List.fromList(new Int16List(32))));
Uint16List var6 = new Uint16List(37);
Int32List var7 = Int32List.fromList(new Int32List(43));
Uint32List var8 = new Uint32List(44);
Int64List var9 = new Int64List(33);
Uint64List var10 = new Uint64List(31);
Int32x4List var11 = new Int32x4List(32);
Int32x4 var12 = new Int32x4(0, 26, 34, 31);
bool var13 = false;
Duration var14 = new Duration();
int var15 = 25;
num var16 = 2147483648;
String var17 = '5';
List<bool> var18 = [false, true];
List<int> var19 = new Uint32List(39);
List<String> var20 = [
  'r8J )',
  '18eL',
  '5y22Ro',
  '!nEb\u2665',
  '\u{1f600}\u{1f600}Si\u{1f600}'
];
Set<bool> var21 = {true, true};
Set<int> var22 = {-1, 35, if (false) 9223372032559808513};
Set<String> var23 = {
  '4 \u{1f600}4',
  'nrza',
  'dgn\u{1f600}#',
  '\u{1f600}R6',
  'F6iC',
  'yo'
};
Map<bool, bool> var24 = {true: true, true: false};
Map<bool, int> var25 = {
  false: -64,
  false: 5,
  true: -9223372032559808512,
  false: 7,
  true: 0,
  false: -23
};
Map<bool, String> var26 = {
  false: ' ',
  false: 'wHj\u{1f600}N',
  false: '\u{1f600}\u266571',
  true: ''
};
Map<int, bool> var27 = {-32: false};
Map<int, int> var28 = {4294967297: -21, 32: 12, -29: -1, -4294967295: -22};
Map<int, String> var29 = {
  -18: '#\u{1f600}',
  -98: 'zjhMg',
  -6: '',
  37: '#n3@G\u{1f600}\u2665',
  -98: 'R',
  -81: ''
};
Map<String, bool> var30 = {'xEcSB&': true, 'ja\u{1f600}': false};
Map<String, int> var31 = {
  '4&': -23,
  'Qab\u{1f600}T-': -5,
  'h&A': 25,
  '\u{1f600}': -84,
  'MUrYpPs': 47,
  '': 19
};
Map<String, String> var32 = {'5- Lt': ''};

Map<int, bool> foo0(Map<String, String> par1) {
  if ((!(var27[(var13 ? (false ? var15 : var10[-40]) : var15)]))) {
    print((((var24[var24[var13]] ^ true) &
            ((!(false)) ? (SecurityContext.alpnSupported) : var18[(var15--)]))
        ? var20
        : [
            ((!(false)) ? var20[var6[(var15++)]] : var20[(var15 & -2147483648)])
          ]));
  }
  return {
    (var30[('qy\u{1f600})&' ?? var20[var15])] ? (Int32x4.zyyz as int) : -43):
        ((!(var13)) | (!((!(true))))),
    (-(((var15++) ^
            var4[(((!(true)) ^ var13) ? var1[(Int32x4.wwxz as int)] : 16)]))):
        var18[(Int32x4.xzxw as int)]
  };
}

Uint8List foo1() {
  {
    Int32x4List loc0 = new Int32x4List(15);
    var24 = {
      ((var17).isEmpty):
          ((var13 ? new Duration() : new Duration()) > new Duration()),
      true: ((!((((~(-51))).isEven)))
          ? ((true ? true : var13) ? var27[(Float32x4.wwyw as int)] : true)
          : var13),
      ((var18[(~(var28[var15]))]
              ? (var13 &
                  ((!(var13))
                      ? (var13 &&
                          ({
                            var13: false,
                            (!((!((((true ? new Duration() : var14) >=
                                        new Duration())
                                    ? (var13 ? var24[true] : true)
                                    : (var13 ? true : true)))))):
                                ([
                                      false,
                                      (!((!((!(var13)))))),
                                      var24[true],
                                      (!(false))
                                    ] ==
                                    ['', '\u26659Q', (var20[13] + var17)]),
                            var13:
                                ((!(true)) ? (!(var30[var26[false]])) : true),
                            (!((((var13 ? 1 : (7 << 19))).isInfinite))):
                                var30['\u2665'],
                            (((~(var15))).isNaN): true,
                            true: (!(((var30[var17] ? false : false) ^
                                var18[var3[(var24[var13]
                                    ? 23
                                    : var3[var31['zaqx\u{1f600}G']])]])))
                          }[var30[var17]]
                              ? true
                              : var27[-44]))
                      : (!(true))))
              : true) ??
          false): var13
    };
    return Uint8List.fromList(new Int8List(29));
  }
  return new Uint8List(27);
}

List<bool> foo2() {
  {
    int loc0 = 47;
    while (--loc0 > 0) {
      print(Uint64List.fromList(new Uint16List(15)));
      var28 = {
        (var15++): -76,
        var10[(~((ZLibOption.defaultMemLevel as int)))]: (true
            ? var25[((var0[var6[(-(49))]]).isInfinite)]
            : -9223372036854775808),
        ((var15--) ^ (2147483647 ~/ -84)):
            ((!(true)) ? -19 : (Int32x4.yyzy as int)),
        (Float32x4.zwwx as int): (var13
            ? (var13
                ? (Float32x4.xywz as int)
                : (loc0 ^ ((41 << loc0) | var7[33])))
            : (-((-(20)))))
      };
    }
  }
  var16 += ((((!(var30[(var17 +
                  var20[((true ? 44 : var9[35]) | (-((var15 >> (-(43))))))])]))
              ? (!(((var5[var7[(-(var15))]]).isOdd)))
              : (SecurityContext.alpnSupported))
          ? (var13 ? 43 : var15)
          : -42) ??
      (-(-11)));
  return [
    var13,
    (true
        ? var13
        : ((false & (!((!(((((var17).padRight(45, 'b'))).isNotEmpty)))))) ^
            false))
  ];
}

class X0 {
  Int32x4 fld0_0 = new Int32x4(18, 2, 40, 8);
  Duration fld0_1 = new Duration();

  Int32x4 foo0_0(Map<int, String> par1, Map<bool, bool> par2) {
    var30.forEach((loc0, loc1) {
      {
        int loc2 = 0;
        do {
          var9 = var0;
        } while (++loc2 < 6);
      }
      return new Int32x4(17, 26, 12, 16);
    });
    return (((true ??
                ((var26[false]).endsWith(var32[(var13
                    ? var20[
                        var4[(var10[(-45 & var10[var28[-26]])] >> (-8 ^ -31))]]
                    : var17)])))
            ? (var13 ? var12 : var11[-63])
            : (var12 + new Int32x4(25, 26, 45, 29))) ??
        new Int32x4(25, 49, 23, 29));
  }

  void run() {
    var2 = new Int8List(32);
    //print('8t');
  }
}

class X1 extends X0 {
  Uint32List fld1_0 = new Uint32List(33);
  Map<int, bool> fld1_1 = {-57: true, -77: false, -61: true};
  Uint8ClampedList fld1_2 =
      Uint8ClampedList.fromList([18, if (true) -44 else 9223372034707292159]);
  Map<String, int> fld1_3 = {
    'ktH\u{1f600}#P4': 23,
    'yG': -76,
    'M': 13,
    'wHx\u{1f600}U': 14,
    'z#ETVJ': 20
  };

  Map<int, bool> foo1_0(Set<bool> par1, Int32x4 par2, Uint32List par3) {
    throw var22;
  }

  void run() {
    super.run();
    /*
     * Multi-line
     * comment.
     */
    {
      int loc0 = 16;
      while (--loc0 > 0) {
        {
          int loc1 = 0;
          do {
            for (Int32x4 loc2 in new Int32x4List(27)) {
              var31 = fld1_3;
            }
            var7 = new Int32List(47);
          } while (++loc1 < 10);
        }
      }
    }
    {
      int loc0 = 0;
      do {
        {
          int loc1 = 19;
          while (--loc1 > 0) {
            /// Single-line documentation comment.
            var26 = var26;
            var3 = var3;
          }
        }
      } while (++loc0 < 31);
    }
  }
}

class X2 extends X1 {
  Set<String> fld2_0 = {'AfJC6W#'};
  bool fld2_1 = false;

  Set<int> foo2_0() {
    return var22;
  }

  void run() {
    super.run();
    {
      List<bool> loc0 = [false, false];
      var16 ??= var15;
      try {
        var8 = var1;
      } catch (exception, stackTrace) {
        var22 = (({
          4294967295,
          -80,
          -81,
          if (false) -28 else for (int loc1 = 0; loc1 < 14; loc1++) 35,
          -3,
          -76
        }).intersection({47, 4, -28}));
      }
    }
  }
}

class X3 extends X1 {
  List<bool> fld3_0 = [false, true, true, true];
  Set<String> fld3_1 = {'', ''};

  int foo3_0(int par1, Int32x4 par2) {
    var18[(-(var15))] ??= ((var24[false]
            ? var13
            : (true
                ? (true
                    ? (var29[par1] == new Uint16List(10))
                    : var24[(new Duration() < new Duration())])
                : (var24[false] ? false : false))) &
        ((('EDtFZ').isEmpty)
            ? (!((!(((true ? var24[var13] : (true ?? false)) ? var13 : true)))))
            : ((({-28: 'aOSI!'}).isNotEmpty) ? true : ((var29).isEmpty))));
    return (--var15);
  }

  void run() {
    super.run();
    try {
      {
        Map<String, String> loc0 = var32;
        var17 = ((var15).toStringAsFixed((-(var25[true]))));
        var11 = var11;
      }
    } catch (exception, stackTrace) {
      {
        int loc0 = 0;
        do {
          for (int loc1 = 0; loc1 < 11; loc1++) {
            {
              List<bool> loc2 =
                  ((true ? (false ? true : var13) : var27[(var15++)])
                      ? (([false, true, false, false] ?? [true, true, true]) ??
                          [true, false, false, true, true])
                      : var18);
              var11 = new Int32x4List(24);
            }
            var4 = Uint8ClampedList.fromList(new Uint64List(31));
          }
        } while (++loc0 < 13);
      }
    }
  }
}

main() {
  try {
    foo0((var13
        ? var32
        : {
            'ED5&ntR': '\u{1f600}\u{1f600}aYDY',
            '\u2665o B': '\u{1f600}a\u{1f600}V',
            'VK+': ''
          }));
  } on OutOfMemoryError {
    exit(254);
  } catch (e, st) {
    print('foo0 throws');
  }
  try {
    foo1();
  } on OutOfMemoryError {
    exit(254);
  } catch (e, st) {
    print('foo1 throws');
  }
  try {
    foo2();
  } on OutOfMemoryError {
    exit(254);
  } catch (e, st) {
    print('foo2 throws');
  }
  try {
    X0().foo0_0(
        (Map.from(
            ((var13 ^ var24[var24[((('jvxu' * 16)).endsWith('U24\u{1f600}F'))]])
                ? (Map.from({-87: '\u2665Z#\u{1f600}&J5'}))
                : {47: '0'}))),
        {false: false, true: true});
  } on OutOfMemoryError {
    exit(254);
  } catch (e, st) {
    print('X0().foo0_0() throws');
  }
  try {
    X1().foo1_0({false, false, false, true},
        (new Int32x4(44, 23, 21, 19) - var12), new Uint32List(10));
  } on OutOfMemoryError {
    exit(254);
  } catch (e, st) {
    print('X1().foo1_0() throws');
  }
  try {
    X2().foo2_0();
  } on OutOfMemoryError {
    exit(254);
  } catch (e, st) {
    print('X2().foo2_0() throws');
  }
  try {
    X3().foo3_0(
        ((var15 << 39) ??
            (var27[var3[(true
                    ? var15
                    : (~(var7[(var30[var20[var0[42]]] ? var15 : var15)])))]]
                ? (--var15)
                : var15)),
        var11[var31[var17]]);
  } on OutOfMemoryError {
    exit(254);
  } catch (e, st) {
    print('X3().foo3_0() throws');
  }
  try {
    X3().run();
  } on OutOfMemoryError {
    exit(254);
  } catch (e, st) {
    print('failed test');
    exit(1); // flag error!
  }
  try {} on OutOfMemoryError {
    exit(254);
  } catch (e, st) {
    print('print throws');
  }
}
