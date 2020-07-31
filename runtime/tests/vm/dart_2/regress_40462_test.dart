// Copyright (c) 2020, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Regression test for https://github.com/dart-lang/sdk/issues/40462
// VMOptions=--deoptimize_every=140 --optimization_level=3 --use-slow-path --old_gen_heap_size=128

import 'dart:async';
import 'dart:cli';
import 'dart:collection';
import 'dart:convert';
import 'dart:core';
import 'dart:io';
import 'dart:isolate';
import 'dart:math';
import 'dart:typed_data';

Map<int, bool> var0 = {
  33: false,
  6: true,
  -9223372028264841217: true,
  -77: true,
  -6: false,
  2147483649: false
};
MapEntry<String, bool> var1 = MapEntry<String, bool>('&8\u{1f600}Z', true);
Map<int, bool> var2 = {18: true, 16: false, -30: false, -30: true, 41: false};
Endian var3 = (Endian.host);
ByteData var4 = ByteData(9);
Int8List var5 = Int8List(4);
Uint8List var6 = Uint8List.fromList(
    Uint8ClampedList.fromList(Int64List.fromList(Uint8List(45))));
Uint8ClampedList var7 = Uint8ClampedList(4);
Int16List var8 = Int16List.fromList([-11]);
Uint16List var9 = Uint16List.fromList(Uint16List.fromList(Uint8List(45)));
Int32List var10 = Int32List.fromList(Uint16List(14));
Uint32List var11 = Uint32List.fromList(Int64List.fromList([-8, -95]));
Int64List var12 = Int64List.fromList(Uint32List(3));
Uint64List var13 = Uint64List(2);
Int32x4List var14 = Int32x4List(2);
Int32x4 var15 = Int32x4.bool(false, true, true, true);
Deprecated var16 = Deprecated('G');
Provisional var17 = Provisional();
bool var18 = bool.fromEnvironment(' 9');
Duration var19 = new Duration();
Error var20 = Error();
AssertionError var21 = AssertionError(49);
TypeError var22 = TypeError();
CastError var23 = CastError();
NullThrownError var24 = new NullThrownError();
ArgumentError var25 = ArgumentError.value(27, '', 18);
RangeError var26 = RangeError.index(1, 42, '+m', 'JjY', 46);
IndexError var27 = IndexError(38, 29, 'R1Z', 'VnR7', 13);
FallThroughError var28 = new FallThroughError();
AbstractClassInstantiationError var29 = AbstractClassInstantiationError('Sq');
UnsupportedError var30 = UnsupportedError('(OXv');
UnimplementedError var31 = UnimplementedError('Dt)F@\u2665');
StateError var32 = StateError('y');
ConcurrentModificationError var33 = ConcurrentModificationError(18);
OutOfMemoryError var34 = OutOfMemoryError();
StackOverflowError var35 = StackOverflowError();
CyclicInitializationError var36 = CyclicInitializationError('0');
Exception var37 = new Exception(6);
FormatException var38 = FormatException('w8q', 36, 17);
IntegerDivisionByZeroException var39 = IntegerDivisionByZeroException();
int var40 = -97;
Null var41 = null;
num var42 = -64;
RegExp var43 = RegExp('Dr6eaNw');
String var44 = 'Zgm83P\u2665';
Runes var45 = Runes('RJ ');
RuneIterator var46 = RuneIterator.at('\u2665q', 17);
StringBuffer var47 = StringBuffer(40);
Symbol var48 = Symbol('sA8');
Expando<bool> var49 = Expando<bool>('1\u2665&');
Expando<int> var50 = Expando<int>('6lfPf+');
Expando<String> var51 = Expando<String>(')L9b7#');
List<bool> var52 = [false];
List<int> var53 = [
  49,
  -14,
  31,
  -80,
  ...[9223372034707292160, 44, 6, 3, -42]
];
List<String> var54 = [
  'X#',
  'DP',
  'A\u2665-s4mF',
  'l',
  '9',
  'W6\u{1f600}d\u{1f600}'
];
Set<bool> var55 = {false, false};
Set<int> var56 = {-2147483649};
Set<String> var57 = {
  '',
  'shf!r',
  '\u{1f600}XCBW6',
  '\u{1f600}',
  '1\u{1f600}7FS',
  'w@'
};
Map<bool, bool> var58 = {
  false: false,
  false: true,
  true: false,
  true: true,
  false: false,
  false: false
};
Map<bool, int> var59 = {true: -82, true: -23, false: 22};
Map<bool, String> var60 = {false: 'nC\u2665', true: '', true: '8+E2G'};
Map<int, bool> var61 = {22: false, -35: false, 38: false, 2: false};
Map<int, int> var62 = {38: 48, -3: 45, 47: -9223372032559808511, 2: -73};
Map<int, String> var63 = {
  ...{-47: 'Sizqs\u2665', -91: 'd'}
};
Map<String, bool> var64 = {
  '': false,
  '\u{1f600}\u2665UJe!': true,
  'o!n': false,
  'Jw\u{1f600}\u{1f600}L': true,
  'UL\u2665g-E': true,
  'g\u{1f600}Q@': false
};
Map<String, int> var65 = {
  'TnC2(o': -86,
  '': 17,
  '+!\u{1f600}54!6': -62,
  '': 42,
  'm': -54,
  'sk&EU\u{1f600}n': 23
};
Map<String, String> var66 = {'aTVZDv': '6x\u{1f600}w'};
MapEntry<bool, bool> var67 = MapEntry<bool, bool>(false, true);
MapEntry<bool, int> var68 = MapEntry<bool, int>(true, 23);
MapEntry<bool, String> var69 = new MapEntry<bool, String>(true, '');
MapEntry<int, bool> var70 = MapEntry<int, bool>(40, false);
MapEntry<int, int> var71 = MapEntry<int, int>(8, 46);
MapEntry<int, String> var72 = MapEntry<int, String>(49, 'Ke');
MapEntry<String, bool> var73 = MapEntry<String, bool>('7p', false);
MapEntry<String, int> var74 = new MapEntry<String, int>('+&u', 33);
MapEntry<String, String> var75 = MapEntry<String, String>('1(etj', '@##4jr');

Error foo0(int par1) {
  if (par1 >= 41) {
    return var22;
  }
  var66.forEach((loc0, loc1) {
    var32 ??= var32;
  });
  {
    int loc0 = 2;
    while (--loc0 > 0) {
      break;
    }
  }
  return new RangeError(47);
}

Endian foo1(Runes par1, FallThroughError par2, Uint16List par3) {
  return (Endian.little);
}

Uint32List foo2(Null par1, String par2, int par3) {
  if (par3 >= 30) {
    return (false ? Uint32List.fromList(new Uint32List(30)) : var11);
  }
  ((StringBuffer(18)).clear());
  (RangeError.checkValueInInterval(
      (true ? (--var40) : 42),
      (-58 ?? (Float32x4.wxwy as int)),
      (-((Uint8ClampedList.bytesPerElement as int))),
      ((var63[26]).substring(30, -4)),
      var44));
  return (Uint32List.fromList((List<int>.filled(34, var40))));
}

extension fooE0 on Runes {
  Exception foo0_Extension0(
      Set<String> par1, Expando<int> par2, List<int> par3, int par4) {
    if (par4 >= 44) {
      return Exception(35);
    }
    {
      int loc0 = 0;
      do {
        if (var18) {
          return ((!((var58[true]
                  ? var58[((!(((RegExp('F\u2665R')).isDotAll))) || (!(var18)))]
                  : true)))
              ? ((false ? (var52[(--var40)] ? true : var18) : true)
                  ? FormatException('y5\u{1f600}1XPZ', 45, 39)
                  : Exception(29))
              : fooE0(var45).foo0_Extension0(
                  {
                      ((true ? var18 : (var64['Xpa'] ? false : var52[var40]))
                          ? ''
                          : 'NDjj\u{1f600}w\u{1f600}'),
                      ('mCOwFm' ?? 'v')
                    },
                  var50,
                  (var6 ??
                      (false ? Uint8List.fromList([(-1 ^ var10[36])]) : var13)),
                  par4 + 1));
        }
      } while (++loc0 < 4);
    }

    for (int loc0 = 0; loc0 < 21; loc0++) {
      print(MapEntry<bool, bool>(true, true));
      {
        int loc1 = 4;
        while (--loc1 > 0) {
          var74 ??= MapEntry<String, int>(' ', 35);
        }
      }
    }
    return fooE0(var45).foo0_Extension0({
      (var18
          ? (var64[var54[var7[6]]]
              ? (var61[6442450945]
                  ? '5zKk&\u{1f600}L'
                  : ('\u2665PpeyDs' ?? 'DSwK\u{1f600}'))
              : '\u2665iOel1')
          : 'KF\u{1f600}'),
      '6x!',
      var60[(!((false ?? (!(true)))))]
    }, var50, var9, par4 + 1);
  }
}

extension fooE1 on CyclicInitializationError {
  List<String> foo1_Extension0(
      FormatException par1, Duration par2, num par3, int par4) {
    if (par4 >= 41) {
      return var54;
    }
    throw (((!((false ? false : var49[(++var40)])))
            ? (!(true))
            : (false
                ? var52[(var40--)]
                : (((RegExp('BQ7TD8@')).isCaseSensitive) && true)))
        ? ((true && var18) ? Symbol('mfQ6U') : Symbol('yr@'))
        : Symbol('J1'));
  }

  String foo1_Extension1(StringBuffer par1, Int16List par2, int par3) {
    if (par3 >= 14) {
      return var63[var50[
          ((((false ? {var50[-61]} : var56)).add(par3)) ? 8589934591 : 15)]];
    }
    try {
      return fooE1(var36).foo1_Extension1(par1, par2, par3 + 1);
    } on OutOfMemoryError {
      exit(254);
    } catch (exception, stackTrace) {
      switch ((-17 ~/ (true ? (-(var40)) : (-(var42))))) {
        case 3680904311:
          {
            throw (((true || true)
                    ? ([(((var60[var18]).trim()) * 27)] ==
                        ArgumentError.value(37, 'G+cy&', 37))
                    : (!((((var54[(--var40)]).trimRight()) == Provisional()))))
                ? fooE1(var36).foo1_Extension0(
                    FormatException('y', 31, 49), var19, -4294967296, 0)
                : var54);
            break;
          }
        case 3680904315:
          {
            var51 ??= var51;
            break;
          }
        default:
          {
            var66.forEach((loc0, loc1) {
              var52 = ((!((var42 > var40)))
                  ? var52
                  : [
                      (((var18
                              ? Int32x4.bool(false, false, true, false)
                              : (true ? new Int32x4(13, 16, 20, 25) : var15)))
                          .flagW),
                      var18
                    ]);
            });
            break;
          }
      }
    }
    {
      int loc0 = 43;
      while (--loc0 > 0) {
        (((true
                ? (true
                    ? {
                        40: 'nbk',
                        38: fooE1(var36).foo1_Extension1(var47, var8, par3 + 1)
                      }
                    : var63)
                : var63))
            .addAll(var63));
        try {
          var58.forEach((loc1, loc2) {
            /// Single-line documentation comment.
            throw var68;
          });
          {
            int loc1 = 0;
            do {
              var12 = Int64List.fromList(Int8List.fromList(Int64List.fromList(
                  Uint8ClampedList.fromList([var59[true]]))));
            } while (++loc1 < 3);
          }
        } on OutOfMemoryError {
          exit(254);
        } catch (exception, stackTrace) {
          return '3';
        } finally {
          var24 ??= NullThrownError();
        }
      }
    }
    return var63[(Int32x4.xxxz as int)];
  }
}

extension fooE2 on TypeError {
  StateError foo2_Extension0(List<String> par1) {
    var47 = var47;
    if ((!(var49[((false ? var18 : ((Duration() > var19) ? true : false))
        ? -25
        : var40)]))) {
      if (var49[43]) {
        var63 = ((((!(true)) ? (8589934591 >= (6442450945 % -14)) : var18) ^
                (var18
                    ? (((false
                            ? var14[(true ? -9 : var40)]
                            : Int32x4.bool(false, true, true, true)))
                        .flagW)
                    : false))
            ? (var64['1']
                ? {
                    (--var40): 'h\u{1f600}E(S@r',
                    (var40++): var63[var6[36]],
                    (--var40): var60[true]
                  }
                : {
                    ((({((~(var40)) ?? var40): 'dU\u2665nE'}).isNotEmpty)
                            ? -45
                            : var40):
                        var63[(true
                            ? 36
                            : ((var61[var40] ? false : false)
                                ? var40
                                : (~((var40--)))))],
                    (~((Int32x4.zzwz as int))): (true
                        ? var44
                        : (fooE1(var36).foo1_Extension1(var47, var8, 0) +
                            var36.foo1_Extension1(var47, Int16List(18), 0))),
                    (((var6 == Symbol('\u2665uarCSV')) &&
                                (var18 ? var18 : var18))
                            ? (var40++)
                            : 25):
                        (((((!(((RegExp('t')).isMultiLine))) ? var18 : false)
                                ? var8[((true ? -65 : (3 % -99)) ~/ 30)]
                                : var40))
                            .toStringAsExponential((Int32x4.wxxz as int)))
                  })
            : {
                (-9223372032559808513 ~/ (-(4294967297))):
                    var36.foo1_Extension1(StringBuffer(24), var8, 0),
                if ((!((var18 ^ false))))
                  (var0[(var42 ~/ var40)] ? -39 : -96): 'BuzKc'
                else
                  (Int32x4.yxyy as int): (false ? 'Rxpx2T' : '(xEVAx'),
                (Int32x4.xxxw as int): var54[(Float32x4.zyyw as int)],
                (~(-7)): ('' * 8)
              });
      } else {
        var60 = {
          (!(var18)): fooE1(var36).foo1_Extension1(
              StringBuffer(0), Int16List.fromList(Uint64List(6)), 0),
          var18: ('U6o5y' * 31),
          ((((RegExp('')).isCaseSensitive) &&
                  (false ||
                      var58[(({var40}).add(var12[(-9223372030412324863 ??
                          var65[((var18).toString())])]))])) ||
              ((new Duration() * (false ? var40 : var40)) <=
                  (-((var19 ?? var19))))): 'HZIfq',
          var64[var44]: var44,
          var52[(var5[-0] | ((++var40) >> var40))]: ((var18
                  ? false
                  : (true
                      ? var2[-91]
                      : var58[
                          ((((var15).shuffleMix(Int32x4(3, 6, 11, 16), var40)))
                              .flagX)]))
              ? var54[12]
              : var54[(-((var18 ? var40 : var40)))]),
          var2[(~(-87))]: 'LxD'
        };
        var20 ??= ((((var18 ? RegExp('S#lVaW(') : var43)).isUnicode)
            ? FallThroughError()
            : foo0(0));
      }
    }
    return StateError('99');
  }

  Int64List foo2_Extension1(
      Exception par1, Int16List par2, List<String> par3, int par4) {
    if (par4 >= 5) {
      return ((!(((new RegExp('I!'))
              .hasMatch((false ? 'A\u{1f600}\u26656' : ('F4xY' ?? var51[0]))))))
          ? Int64List(30)
          : var12);
    } // Single-line comment.
    if ((((bool.fromEnvironment((((-(var40))).toString()))) & false) ||
        var58[var49[-4294967295]])) {
      try {
        var2 = var2;
      } on OutOfMemoryError {
        exit(254);
      } catch (exception, stackTrace) {
        (({27: '7BxmY'}).clear());
      }
    }
    var13 = var13;
    return (var22).foo2_Extension1(
        var38,
        par2,
        var36.foo1_Extension0(
            (var58[true]
                ? FormatException('2IWwRf', 3, 34)
                : new FormatException('d!B', 4, 28)),
            Duration(),
            45,
            0),
        par4 + 1);
  }

  NullThrownError foo2_Extension2(Exception par1,
      IntegerDivisionByZeroException par2, FormatException par3) {
    var42 = 30;
    var1 = MapEntry<String, bool>('abGhTN', true);
    return var24;
  }
}

extension fooE3 on Null {
  Int32x4 foo3_Extension0(int par1) {
    if (par1 >= 6) {
      return (((Int32x4(12, 1, 48, 9)).withX((22 ?? ((8 | par1) >> 41)))) ^
          var15);
    }
    ((((((var5).sublist(((!((!(false)))) ? -87 : -9223372030412324865),
                    (--var40))) +
                var12) +
            (var8 ?? var8)))
        .fillRange(-9223372036854775807, -2147483649, (Float32x4.xwyw as int)));
    return Int32x4.bool(true, true, false, false);
  }
}

extension fooE4 on Duration {
  MapEntry<int, String> foo4_Extension0(Exception par1, Int32x4 par2) {
    (({
      ...{
        (false ? -22 : (var18 ? var13[var40] : (++var40))),
        var40,
        -9223372030412324864,
        (var64[var44] ? 27 : var40),
        (Float32x4.wyyx as int)
      },
      ...{-94, (var40--)},
      (~(var40)),
      for (int loc0 in {(DateTime.april as int)}) (var40++)
    }).clear());
    return MapEntry<int, String>(15, 'Y3U');
  }

  CyclicInitializationError foo4_Extension1(bool par1, Int32x4List par2) {
    {
      int loc0 = 12;
      while (--loc0 > 0) {
        {
          UnsupportedError loc1 = var31;
          {
            int loc2 = 48;
            while (--loc2 > 0) {
              var50 ??= (false ? new Expando<int>('N') : var50);
            }
          }
        }
        return (true
            ? (false ? CyclicInitializationError('pbsl\u2665B)') : var36)
            : CyclicInitializationError('SY8K'));
      }
    }
    return CyclicInitializationError('x');
  }
}

class X0 {
  Int32x4 fld0_0 = Int32x4(4, 17, 25, 21);
  FallThroughError fld0_1 = new FallThroughError();
  Int16List fld0_2 = Int16List.fromList(Int32List.fromList(Uint32List(21)));
  MapEntry<String, int> fld0_3 = MapEntry<String, int>('Z)i6o', 1);

  List<bool> foo0_0(Map<String, int> par1) {
    (({(~((-(var40)))): 'S'}).addAll({
      for (int loc0 = 0; loc0 < 9; loc0++) -40: var44,
      (Int32x4.ywzy as int): ((var31).message),
      if (var58[(!(false))])
        -45: (String.fromEnvironment(((((true && var49[-9223372036854775807])
                ? CyclicInitializationError('8DdLh-y')
                : var36))
            .toString()))),
      var40: var54[(var40++)]
    }));
    return ([
          true,
          (var64[var63[13]]
              ? (((true
                      ? var15
                      : (var58[var58[false]]
                          ? new Int32x4(18, 23, 13, 30)
                          : Int32x4(49, 44, 37, 37))))
                  .flagW)
              : (!(var52[(Float32x4.yzyw as int)]))),
          var18,
          (!(((var56).add((~(43))))))
        ] ??
        var52);
  }

  NullThrownError foo0_1(int par1) {
    if (par1 >= 20) {
      return var22.foo2_Extension2(var38, IntegerDivisionByZeroException(),
          FormatException('JHGQ-3', 48, 18));
    }
    try {
      var66.forEach((loc0, loc1) {
        {
          int loc2 = 0;
          do {
            for (int loc3 = 0; loc3 < 10; loc3++) {
              throw StackOverflowError();
            }
            var27 ??= var27;
          } while (++loc2 < 20);
        }

        {
          int loc2 = 28;
          while (--loc2 > 0) {
            // Single-line comment.
            return NullThrownError();
          }
        }
      });
    } on OutOfMemoryError {
      exit(254);
    } catch (exception, stackTrace) {
      /// Single-line documentation comment.
      throw var23;
    } finally {
      // Single-line comment.
      try {
        /*
         * Multi-line
         * comment.
         */
        ((((((var41.foo3_Extension0(0)).flagW) |
                    (((true ? true : var49[(Float32x4.yxxy as int)])
                            ? var18
                            : var58[var64['Zmg\u26656']])
                        ? var64[((true ? '' : ('+TZ' + var44)) + var54[-89])]
                        : true))
                ? RuneIterator.at('8zi', 34)
                : (((var52[var40] ? var45 : Runes('M!y'))).iterator)))
            .reset((Float32x4.xzxx as int)));
      } on OutOfMemoryError {
        exit(254);
      } catch (exception, stackTrace) {
        // Single-line comment.
        {
          int loc0 = 0;
          do {
            var31 ??= (var18 ? UnimplementedError('') : var31);
          } while (++loc0 < 19);
        }
      } finally {
        var33 ??= var33;
        print({
          'p',
          '5',
          'nFd',
          ((('\u2665QJhrGu').substring(
                  (var40 ~/
                      ((false ? true : (!(true)))
                          ? (var40 - 15)
                          : -4294967296)),
                  -52)) *
              36),
          ('aA\u{1f600}' +
              (var60[((true
                          ? true
                          : (!(((var14[(-(((var52[27] ? 39 : var40) << -35)))])
                              .flagX)))) ^
                      var18)] *
                  8)),
          ((var64[var44]).toString())
        });
      }
    }
    return var24;
  }

  Int8List foo0_2(Symbol par1, MapEntry<bool, bool> par2,
      Map<String, String> par3, int par4) {
    if (par4 >= 40) {
      return Int8List(9);
    }
    var1 ??= MapEntry<String, bool>('B\u{1f600}\u2665v-fx', true);
    if (false) {
      if ((var42 >= -64)) {
        {
          int loc0 = 0;
          do {
            ((var63).addAll({3: ((((var18).toString()) + var44) + 'PIW@')}));
            var41 = null;
          } while (++loc0 < 20);
        }
      }
      switch (((Float32x4.yyxy as int) & var40)) {
        case 2432097039:
          {
            if ((!((var18 |
                ((!((bool.fromEnvironment('Doptl\u{1f600}R'))))
                    ? true
                    : var18))))) {
              return var5;
            } else {
              var63 = {
                (-((true
                    ? var11[fld0_2[(Int32x4.zwzz as int)]]
                    : var11[(var18
                        ? var12[var59[
                            ((Int32x4.bool(true, false, true, false)).flagZ)]]
                        : var40)]))): var44,
                ...{(-(-0)): '@yx+(O'},
                ...{
                  (var40 >> -39):
                      (((var18 ? var52[-9223372036854775807] : false)
                              ? var58[var18]
                              : (!((false || false))))
                          ? '\u{1f600}B4hFc'
                          : '33xC'),
                  if ((var19 >= Duration()))
                    (Float32x4.ywyz as int): var44
                  else
                    var5[var50[(var42 ~/ var42)]]: var51[var40],
                  ...{
                    var62[-12]: '@LYD',
                    ((false ? var42 : var40) ~/ -42):
                        (([''] == var47) ? '' : var44)
                  }
                },
                (Float32x4.yyyx as int): 'eD0\u2665A',
                if ((!(var18)))
                  ((var15).x as int):
                      ((!(var58[(!(var64[')']))])) ? var44 : var44)
                else
                  -88: ((StateError('')).toString()),
                var13[var40]: var44
              };
            }
            break;
          }
        case 2432097049:
          {
            var33 ??= ConcurrentModificationError(18);
            break;
          }
        default:
          {
            var59 = {
              false: (~(((~(var40)) >> var40))),
              (false ? var18 : (!(false))): var40,
              (false ?? (!((((-49).isInfinite) && var58[var58[var18]])))):
                  (var40--),
              (!((var54 == NullThrownError()))): -12
            };
            break;
          }
      }
    } else {
      try {
        if (((34 - 11) >= (-(49)))) {
          var39 = var39;
          var56 = var56;
        }
      } on OutOfMemoryError {
        exit(254);
      } catch (exception, stackTrace) {
        throw StackOverflowError();
      }
      if (var18) {
        print({
          (var58[true] ? (++var40) : var12[(5 | (Int32x4.wwxx as int))]):
              (++var40),
          (Int64List.bytesPerElement as int):
              var6[(~(var50[var62[var65[par3['Zb']]]]))],
          (var18 ? (true ? 10 : (++var40)) : -79): (var64['h\u{1f600}X\u2665(']
              ? (true
                  ? var5[(((((((((33 > (true ? var40 : var42)) ? var43 : var43))
                                      .isMultiLine)
                                  ? ''
                                  : '#'))
                              .endsWith(var51[9223372032559808512]))
                          ? (!(var18))
                          : var49[22])
                      ? var40
                      : var40)]
                  : (33 ~/ 38))
              : (++var40))
        });
      }
    }
    return foo0_2(
        Symbol('y-r3rR'), MapEntry<bool, bool>(true, false), par3, par4 + 1);
  }

  @override
  Int32x4List call(int par1) {
    if (par1 >= 5) {
      return Int32x4List(5);
    }
    if ((true
        ? var61[(Int32x4.zwyx as int)]
        : (((Float32x4.ywyy as int)).isInfinite))) {
      return var14;
    }
  }

  void run() {
    var17 ??= Provisional();
  }
}

extension XE0 on X0 {
  IntegerDivisionByZeroException foo0_Extension0(
      Map<bool, int> par1, RuneIterator par2, Duration par3) {
    var64.forEach((loc0, loc1) {
      {
        int loc2 = 0;
        do {
          fld0_3 ??= MapEntry<String, int>('4T\u2665i', 30);
        } while (++loc2 < 44);
      }
    });
    return (var52[(Uint32List.bytesPerElement as int)]
        ? var39
        : IntegerDivisionByZeroException());
  }

  List<bool> foo0_Extension1(List<int> par1) {
    /**
     ** Multi-line
     ** documentation comment.
     */
    if (false) {
      switch (((var40++) | -57)) {
        case 3773120366:
          {
            for (int loc0 in foo2(
                null,
                (false
                    ? (var36.foo1_Extension1(var47, Int16List(25), 0) ??
                        (Uri.encodeFull(fooE1(var36)
                            .foo1_Extension1(var47, Int16List(8), 0))))
                    : '\u2665Lgd(n'),
                0)) {
              try {
                var6 = Uint8List(12);
              } on OutOfMemoryError {
                exit(254);
              } catch (exception, stackTrace) {
                var20 = foo0(0);
                var1 = MapEntry<String, bool>('X', true);
              } finally {
                try {
                  var41 = (var0[(ZLibOption.strategyHuffmanOnly as int)]
                      ? (provisional)
                      : (((((~(-43)) | (2147483649 ^ var40))).isNaN)
                          ? (var64[(true ? 'TA6\u{1f600}FQT' : 'p\u2665p!-')]
                              ? null
                              : null)
                          : null));
                  var49 ??= var49;
                } on OutOfMemoryError {
                  exit(254);
                } catch (exception, stackTrace) {
                  try {
                    /*
                   * Multi-line
                   * comment.
                   */
                    var64 = var64;
                  } on OutOfMemoryError {
                    exit(254);
                  } catch (exception, stackTrace) {
                    var23 = CastError();
                    for (int loc1 = 0; loc1 < 14; loc1++) {
                      continue;
                    }
                  } finally {
                    var69 = MapEntry<bool, String>(false, 'SemmWM');
                  }
                  var14[(-((~(-54))))] += var14[(--var40)];
                }
                for (int loc1 = 0; loc1 < 1; loc1++) {
                  var5 = Int8List(38);
                  var13 = var13;
                }
              }
            }
            break;
          }
        case 3773120375:
          {
            var25 = var27;
            break;
          }
        case 3773120384:
          {
            try {
              // Single-line comment.
              ((Uint8ClampedList(24)).removeRange(
                  (var62[-9223372032559808513] ^ -29), var7[var40]));
              var4 ??= ByteData(11);
            } on OutOfMemoryError {
              exit(254);
            } catch (exception, stackTrace) {
              var13 = Uint64List.fromList(
                  Uint8List.fromList(Uint8ClampedList.fromList([(35 | -41)])));
              if ((((!(((false ? var0[var40] : var18)
                          ? (false | (SecurityContext.alpnSupported))
                          : true)))
                      ? false
                      : var18)
                  ? true
                  : var18)) {
                var9 = Uint16List(15);
              }
            }
            break;
          }
      }
      for (int loc0 = 0; loc0 < 22; loc0++) {
        var14 = X0()(0);
        throw MapEntry<bool, int>(true, 16);
      }
    } else {
      ((StringBuffer(44)).clear());
      var39 ??= IntegerDivisionByZeroException();
    }
    return [
      false,
      (!(var18)),
      false,
      var64[
          var36.foo1_Extension1(StringBuffer(2), Int16List.fromList([-27]), 0)],
      true,
      false
    ];
  }
}

class X1 extends X0 {
  Map<bool, String> fld1_0 = {true: '\u2665SE)b'};

  Map<int, int> foo1_0(Deprecated par1, int par2) {
    if (par2 >= 22) {
      return {
        (var40++): var7[(--var40)],
        (((-(var59[true])) | ((--var40) ?? var11[var9[-76]])) >> var62[14]):
            (~((par2--)))
      };
    }
    throw UnimplementedError('O');
  }

  @override
  Int32x4List call(int par1) {
    var26 ??= IndexError(27, 18, '+Qy9', '', 6);
    {
      int loc0 = 41;
      while (--loc0 > 0) {
        /// Single-line documentation comment.
        try {
          fld1_0 = {
            var52[var10[par1]]:
                (((var40++)).toStringAsPrecision(var13[(par1--)])),
            var2[44]: var36.foo1_Extension1(var47,
                (Int16List.fromList(Uint16List.fromList(Int64List(34)))), 0),
            ((!(true))
                    ? false
                    : var52[(var18 ? 33 : (true ? var8[var5[par1]] : -27))]):
                (var36.foo1_Extension1(
                        var47,
                        Int16List.fromList(Uint16List.fromList(Int8List(25))),
                        0) +
                    '7'),
            var18: var36.foo1_Extension1(
                var47, ((var8).sublist(var59[var49[par1]], (par1--))), 0)
          };
          var66 = var66;
        } on OutOfMemoryError {
          exit(254);
        } catch (exception, stackTrace) {
          {
            int loc1 = 33;
            while (--loc1 > 0) {
              var52 = (var52 +
                  ((loc0 < (var49[var11[(-((loc1 ?? -57)))]] ? (-(-1)) : par1))
                      ? ((true
                              ? [true, false]
                              : [
                                  true,
                                  var18,
                                  (((((~(37)) << -9223372036854775808) |
                                          ((loc0).modInverse(loc1) as int)))
                                      .isNegative),
                                  ('D\u2665Sp' ==
                                      IndexError(14, 12, 'PDTOXf', '&5e', 13))
                                ]) ??
                          [true, (!(false))])
                      : [true]));
            }
          }
          if (var18) {
            var20 ??= NullThrownError();
            var14[(Float32x4.zyxw as int)] &= (var41).foo3_Extension0(0);
          } else {
            var74 = MapEntry<String, int>('Jwvy&', 9);
          }
        }
      }
    }
    return Int32x4List(11);
  }

  void run() {
    super.run();
    var49 ??= var49;
  }
}

extension XE1 on X1 {
  IndexError foo1_Extension0(
      Runes par1, MapEntry<bool, int> par2, Exception par3, int par4) {
    if (par4 >= 19) {
      return var27;
    }
    for (int loc0 = 0; loc0 < 19; loc0++) {
      if (((((var58[var18] && (var19 > Duration()))
              ? (true ? (~(-43)) : var5[(var40--)])
              : 2147483647))
          .isInfinite)) {
        return var27;
      } else {
        var41 = var41;
        var23 = (var18
            ? ((var18 ? (false ?? var18) : (false ? ((-38).isEven) : var18))
                ? CastError()
                : CastError())
            : CastError());
      }
    }
    return IndexError(15, 17, 'yw', '', 20);
  }

  Expando<String> foo1_Extension1() {
    /// Single-line documentation comment.
    var59.forEach((loc0, loc1) {
      throw var68;
    });
    return var51;
  }

  Expando<int> foo1_Extension2(CyclicInitializationError par1, Null par2) {
    {
      int loc0 = 0;
      do {
        // Single-line comment.
        var67 ??= (((!((var18 && var58[false])))
                ? ((((var30).toString())).endsWith(var63[
                    ((true ? loc0 : (var9[11] >> (-(-34)))) <<
                        (Float32x4.zwww as int))]))
                : var18)
            ? MapEntry<bool, bool>(false, false)
            : MapEntry<bool, bool>(true, true));
      } while (++loc0 < 29);
    }

    {
      int loc0 = 25;
      while (--loc0 > 0) {
        for (int loc1 = 0; loc1 < 40; loc1++) {
          throw new Expando<String>('+huc0\u2665');
        }
        try {
          continue;
        } on OutOfMemoryError {
          exit(254);
        } catch (exception, stackTrace) {
          var66.forEach((loc1, loc2) {
            if (true) {
              var5 = Int8List.fromList(
                  Uint8ClampedList.fromList([var50[(-(loc0))]]));
            }
          });
          if ((NetworkInterface.listSupported)) {
            for (int loc1 = 0; loc1 < 37; loc1++) {
              var74 ??= var74;
              {
                Set<int> loc2 = {
                  1,
                  (var9[(--var40)] ^
                      (-82 ??
                          (true
                              ? var59[var18]
                              : (var58[var58[(!(false))]] ? (~(loc0)) : 0)))),
                  loc0,
                  ((((var47).isNotEmpty) ??
                          (var52[(Float32x4.xyzw as int)] || (var19 < var19)))
                      ? (var40--)
                      : ((Float32x4.zxzz as int) ^ 48)),
                  ((false | ((var18 ? false : var18) ? (!(var18)) : true))
                      ? (((!(false))
                              ? ((true ? false : var18)
                                  ? (!(var18))
                                  : (!(var61[var12[44]])))
                              : var18)
                          ? (var40++)
                          : 10)
                      : (--var40))
                };
                fld1_0 = ((!(var18))
                    ? ((!((!(var18))))
                        ? fld1_0
                        : {
                            false: (Uri.decodeFull(
                                var66[((Deprecated('uvZ6GU')).toString())]))
                          })
                    : {
                        var18: (true
                            ? ((!(true))
                                ? ''
                                : fooE1(par1)
                                    .foo1_Extension1(StringBuffer(49), var8, 0))
                            : ('' + 'qD6Fry')),
                        (((var58[true] ? RegExp('Zp') : RegExp(''))).isDotAll):
                            fooE1(par1)
                                .foo1_Extension1(StringBuffer(38), var8, 0),
                        ((StringBuffer(39)).isEmpty):
                            ((MapEntry<int, String>(41, 'S2lAKd')).toString()),
                        var64[(var18
                                ? (var60[(false
                                        ? false
                                        : (SecurityContext.alpnSupported))] ??
                                    '\u{1f600}lsZ')
                                : 'c4+Ry')]:
                            (Uri.decodeQueryComponent(
                                var63[(var49[(var40--)] ? -66 : (var40++))])),
                        (!(((StringBuffer(41)).isNotEmpty))):
                            ((null).toString())
                      });
                var66 = var66;
              }
            }
            return Expando<int>('eo');
          }
        } finally {
          print(var27);
        }
      }
    }
    return Expando<int>('');
  }
}

main() {
  try {
    foo0(0);
  } on OutOfMemoryError {
    exit(254);
  } catch (e, st) {
    print('foo0() throws');
  }
  try {
    foo1(
        (var61[(false ? 1 : var40)]
            ? (true ? Runes('\u{1f600}\u{1f600}RK') : var45)
            : ((!(true)) ? ((var63[var40]).runes) : var45)),
        FallThroughError(),
        Uint16List(33));
  } on OutOfMemoryError {
    exit(254);
  } catch (e, st) {
    print('foo1() throws');
  }
  try {
    foo2(((9223372036854775807 < -24) ? (true ? null : var41) : var41), '', 0);
  } on OutOfMemoryError {
    exit(254);
  } catch (e, st) {
    print('foo2() throws');
  }
  try {
    var45.foo0_Extension0(
        {'udb(R', '\u2665IEp\u{1f600}e', 'DMEbe#g', ''}, var50, var8, 0);
  } on OutOfMemoryError {
    exit(254);
  } catch (e, st) {
    print('var45.foo0_Extension0() throws');
  }
  try {
    fooE1(var36).foo1_Extension0(
        FormatException('n', 3, 48), var19, ((var40 % var42) * -2), 0);
  } on OutOfMemoryError {
    exit(254);
  } catch (e, st) {
    print('fooE1(var36).foo1_Extension0() throws');
  }
  try {
    fooE1(var36).foo1_Extension1(
        (false ? StringBuffer(36) : StringBuffer(2)), Int16List(25), 0);
  } on OutOfMemoryError {
    exit(254);
  } catch (e, st) {
    print('fooE1(var36).foo1_Extension1() throws');
  }
  try {
    var22.foo2_Extension0(
        (var54 + ['\u2665aAaW', 'Wc', '\u2665u- jf\u{1f600}']));
  } on OutOfMemoryError {
    exit(254);
  } catch (e, st) {
    print('var22.foo2_Extension0() throws');
  }
  try {
    (var22).foo2_Extension1(IntegerDivisionByZeroException(), var8, ['OiV'], 0);
  } on OutOfMemoryError {
    exit(254);
  } catch (e, st) {
    print('(var22).foo2_Extension1() throws');
  }
  try {
    var22.foo2_Extension2(
        (((var66[((('2S2\u{1f600}Y' * 43))
                    .substring((Float32x4.zyyy as int), var9[34]))])
                .endsWith(var44))
            ? ((!(var58[var58[var18]])) ? Exception(9) : var38)
            : var38),
        IntegerDivisionByZeroException(),
        FormatException('T', 23, 36));
  } on OutOfMemoryError {
    exit(254);
  } catch (e, st) {
    print('var22.foo2_Extension2() throws');
  }
  try {
    var41.foo3_Extension0(0);
  } on OutOfMemoryError {
    exit(254);
  } catch (e, st) {
    print('var41.foo3_Extension0() throws');
  }
  try {
    fooE4(var19).foo4_Extension0(
        var38,
        ((((Int32x4(3, 32, 0, 1) - Int32x4(38, 16, 29, 3))).flagX)
            ? var14[(false ? var40 : (var40++))]
            : var14[var11[-75]]));
  } on OutOfMemoryError {
    exit(254);
  } catch (e, st) {
    print('fooE4(var19).foo4_Extension0() throws');
  }
  try {
    var19.foo4_Extension1((SecurityContext.alpnSupported), var14);
  } on OutOfMemoryError {
    exit(254);
  } catch (e, st) {
    print('var19.foo4_Extension1() throws');
  }

  try {
    X0().foo0_0({'i\u2665\u26651': -89, 'YPf': -88, 'k': -62, 'zhny': -65});
  } on OutOfMemoryError {
    exit(254);
  } catch (e, st) {
    print('X0().foo0_0 throws');
  }
  try {
    X0().foo0_1(0);
  } on OutOfMemoryError {
    exit(254);
  } catch (e, st) {
    print('X0().foo0_1 throws');
  }
  try {
    X0().foo0_2(Symbol('L Cn'), MapEntry<bool, bool>(true, true),
        {' pP': '', '': '2A\u2665B', '': 'm\u2665b'}, 0);
  } on OutOfMemoryError {
    exit(254);
  } catch (e, st) {
    print('X0().foo0_2 throws');
  }
  try {
    X0()(0);
  } on OutOfMemoryError {
    exit(254);
  } catch (e, st) {
    print('X0() throws');
  }
  try {
    X0().foo0_Extension0({false: 29, true: 27}, var46, (-((-(var19)))));
  } on OutOfMemoryError {
    exit(254);
  } catch (e, st) {
    print('X0().foo0_Extension0 throws');
  }
  try {
    (X0()).foo0_Extension1((false
        ? ([-0, -12] ?? Uint8ClampedList(4))
        : (List<int>.filled(43, var40))));
  } on OutOfMemoryError {
    exit(254);
  } catch (e, st) {
    print('(X0()).foo0_Extension1 throws');
  }
  try {
    X1().foo1_0(Deprecated('CR4-'), 0);
  } on OutOfMemoryError {
    exit(254);
  } catch (e, st) {
    print('X1().foo1_0 throws');
  }
  try {
    X1()((Int32x4.xyzz as int));
  } on OutOfMemoryError {
    exit(254);
  } catch (e, st) {
    print('X1() throws');
  }
  try {
    (X1()).foo1_Extension0((('-pjz').runes),
        (true ? var68 : MapEntry<bool, int>(false, 16)), var39, 0);
  } on OutOfMemoryError {
    exit(254);
  } catch (e, st) {
    print('(X1()).foo1_Extension0 throws');
  }
  try {
    (X1()).foo1_Extension1();
  } on OutOfMemoryError {
    exit(254);
  } catch (e, st) {
    print('(X1()).foo1_Extension1 throws');
  }
  try {
    (X1()).foo1_Extension2(var36, var41);
  } on OutOfMemoryError {
    exit(254);
  } catch (e, st) {
    print('(X1()).foo1_Extension2 throws');
  }
  try {
    X1().run();
  } on OutOfMemoryError {
    exit(254);
  } catch (e, st) {
    print('X1().run() throws');
  }
  try {
    print(
        '$var0\n$var1\n$var2\n$var3\n$var4\n$var5\n$var6\n$var7\n$var8\n$var9\n$var10\n$var11\n$var12\n$var13\n$var14\n$var15\n$var16\n$var17\n$var18\n$var19\n$var20\n$var21\n$var22\n$var23\n$var24\n$var25\n$var26\n$var27\n$var28\n$var29\n$var30\n$var31\n$var32\n$var33\n$var34\n$var35\n$var36\n$var37\n$var38\n$var39\n$var40\n$var41\n$var42\n$var43\n$var44\n$var45\n$var46\n$var47\n$var48\n$var49\n$var50\n$var51\n$var52\n$var53\n$var54\n$var55\n$var56\n$var57\n$var58\n$var59\n$var60\n$var61\n$var62\n$var63\n$var64\n$var65\n$var66\n$var67\n$var68\n$var69\n$var70\n$var71\n$var72\n$var73\n$var74\n$var75\n');
  } on OutOfMemoryError {
    exit(254);
  } catch (e, st) {
    print('print() throws');
  }
}
