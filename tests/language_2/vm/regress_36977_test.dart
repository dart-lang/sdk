// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
//
// VMOptions=--deterministic
//
// Regression test, reduced case found by DartFuzz that crashed DBC register
// allocator (https://github.com/dart-lang/sdk/issues/36977).

// [NNBD non-migrated]: This test contains dozens and dozens of static errors
// under NNBD. Migrating the test to fix those errors significantly changes the
// code under test in ways that are likely to invalidate it.

import 'dart:async';
import 'dart:cli';
import 'dart:collection';
import 'dart:convert';
import 'dart:core';
import 'dart:io';
import 'dart:isolate';
import 'dart:math';
import 'dart:typed_data';

double var0 = 0.9297828201722298;
bool var1 = false;
int var2 = -99;
double var3 = 0.26752130449990763;
String var4 = 'OJG';
List<int> var5 = [0, -92, 49, 96];
Set<int> var6 = {29, 9223372036854775807, 75};
Map<int, String> var7 = {
  56: '\u{1f600}D',
  35: '62',
  13: '',
  14: '5k1\u{1f600}\u{1f600}'
};

double foo0(String par1) {
  throw ({
        51: MapBase.mapToString(var7),
        9: '-Io',
        65: ((var2 * var5[-77])).toRadixString(
            ((false ? false : (true ? var1 : (!((!(var1))))))
                ? (--var2)
                : (-(-16)))),
        61: ''
      } ??
      var7);
}

int foo1(Set<int> par1, Set<int> par2) {
  return Int32x4.zxzy;
}

String foo2() {
  {
    int loc0 = 58;
    while (--loc0 > 0) {
      switch ((~((~((-((~(foo1((false ? var6 : var6), {
        (~(-84)),
        ((var1 ? var5[(loc0 + (var2--))] : -77) >>
            ((var1 ? var2 : ((-(var2)) - loc0)) +
                foo1(
                    {
                      -8,
                      19,
                      (true ? var2 : 70),
                      39,
                      loc0,
                      Int32x4.wxyw,
                      var5[var5[Int32x4.wzxz]],
                      -12
                    },
                    (var6 ??
                        {
                          var5[(var1 ? var5[loc0] : var2)],
                          var5[(loc0--)],
                          loc0
                        })))),
        ((Int32x4.yzzw % loc0) % -87),
        Int32x4.wxyz,
        Float32x4.wzxz
      })))))))))) {
        case 3666713542:
          {
            var4 = (true
                ? var4
                : String.fromCharCode((var1
                    ? ((true ? true : true) ? var5[(var2++)] : var2)
                    : (((((false ? (true ? false : true) : false) ? 52 : var2) -
                                foo1(var6, var6)) ~/
                            var2) ^
                        loc0))));
          }
          break;
        case 3666713543:
          {
            var5 = [(Float32x4.xzyw << (Int32x4.zywz * var2))];
          }
          break;
      }
    }
  }
  return 'hLw';
}

class X0 {
  bool fld0_0 = true;

  Set<int> foo0_0(Map<int, String> par1, int par2) {
    try {
      if ((var5 != var5)) {
        throw 0.2119336645634784;
      }
    } catch (exception, stackTrace) {
      if (fld0_0) {
        print({
          ((Float32x4.xzzx %
                  ((-(30)) *
                      foo1(
                          var6,
                          ({
                                (par2++),
                                foo1({
                                  var5[-83],
                                  (true ? -58 : foo1(var6, var6)),
                                  par2,
                                  (var5[-49] - 46),
                                  var2,
                                  var5[76],
                                  73
                                }, (var6).difference(var6)),
                                (((false ? var5[49] : 6442450943) > -98)
                                    ? -92
                                    : var5[7]),
                                -93,
                                var5[var5[27]],
                                var5[-5],
                                (-(((var1 ? false : true) ? var5[-87] : par2)))
                              } ??
                              {FileSystemEvent.MODIFY, 31, var2})))) +
              var2),
          (((++par2)).isEven
              ? foo1(
                  ((var6).toSet()).intersection((var1
                      ? var6
                      : (true
                          ? (var6 ??
                              {
                                foo1({
                                  (45 ^ -59),
                                  var2,
                                  -94,
                                  Int32x4.yyzw,
                                  var2,
                                  44,
                                  var5[foo1(var6, (var6 ?? {-91, var2}))]
                                }, var6),
                                ((++par2) % 70),
                                88
                              })
                          : var6))),
                  ({
                        -85,
                        (var2++),
                        (++par2),
                        45,
                        par2,
                        (--par2),
                        (var5[par2] ??
                            (-((~(foo1(var6, {
                              foo1(
                                  ({
                                        (var2 -
                                            (FileSystemEntity.isFileSync(
                                                    'd)\u{1f600}+Sm')
                                                ? (false ? 22 : var2)
                                                : -15)),
                                        var5[var2],
                                        par2,
                                        var5[(foo1(
                                                var6,
                                                ({
                                                      var2,
                                                      (~(-9223372030412324863)),
                                                      (var2++),
                                                      -18
                                                    } ??
                                                    var6)) &
                                            Int32x4.yxwx)],
                                        (fld0_0
                                            ? (~((-(-50))))
                                            : foo1({
                                                foo1({-92, var5[81]}, var6),
                                                var2,
                                                76,
                                                var5[(false
                                                    ? (true
                                                        ? var2
                                                        : var5[Float32x4.yzxx])
                                                    : var5[var5[var2]])],
                                                Duration.minutesPerHour,
                                                34
                                              }, var6)),
                                        -72
                                      } ??
                                      var6),
                                  {25, Float32x4.wwww})
                            })))))),
                        (par2--)
                      } ??
                      var6))
              : (-((SecurityContext.alpnSupported
                  ? Float32x4.zwyz
                  : foo1({
                      14,
                      var5[var2],
                      (~(39)),
                      93,
                      Float32x4.xyxx,
                      (-(var5[(-65 << -28)])),
                      24,
                      (~(-64))
                    }, {
                      -31,
                      (foo1(var6, {
                            Float32x4.zzyx,
                            96,
                            Float32x4.yyxw,
                            var2,
                            par2
                          }) +
                          Int32x4.wzyy),
                      (~(52)),
                      -13,
                      par2,
                      -83,
                      ZLibOption.DEFAULT_MEM_LEVEL,
                      (var2++)
                    })))))
        });
      }
    } finally {
      for (int loc0 = 0; loc0 < 90; loc0++) {
        if (false) {
          var5 ??= [(~((++par2)))];
          var0 += ((0.08377494829959586 - (-(var3))) *
              (-(((true ? (var0 + 0.8491470957055424) : var0) /
                  ((!(var1))
                      ? var0
                      : (var0 *
                          ((([
                                        -67,
                                        6442450943,
                                        -95,
                                        var5[par2],
                                        -30,
                                        6442450945,
                                        loc0
                                      ] ??
                                      [
                                        (true ? 6442450943 : 16),
                                        var5[var5[1]],
                                        var2,
                                        Float32x4.xwzy,
                                        par2,
                                        var5[28],
                                        Int32x4.xxwx,
                                        var5[-23]
                                      ]) !=
                                  [var5[var5[(--par2)]], Int32x4.yzxy])
                              ? var3
                              : 0.9197172211286759)))))));
        } else {
          print((var4).codeUnits);
        }
      }
      var7 ??= {
        9: (var7[(((!(fld0_0)) ? -27 : (Float32x4.xyzz).round()) ^
                ((~(54)) +
                    foo1({
                      var2,
                      28,
                      -9223372028264841217,
                      (par2--),
                      (++par2),
                      -1,
                      (-(var5[var2]))
                    }, var6)))])
            .padLeft(68, (0.0875980111263257).toStringAsPrecision((++par2))),
        88: (foo2() ?? '1rcZ'),
        32: 'NeAEG',
        5: ('\u{1f600}n)V\u2665#').replaceRange(
            (-(-1)),
            (-(par2)),
            ((((!((var1 || (true ? var1 : (var7).isEmpty)))) ? var1 : false) &&
                    (var7).isEmpty)
                ? ((false ? false : var1) ? '!Tlx)' : par1[6442450943])
                : var4)),
        13: var7[(((!(((par1[-27] ?? 'AcM') != 'Gb')))
                ? true
                : (var6 ==
                    ({
                          13,
                          96,
                          var5[Int32x4.zxyw],
                          -41,
                          ((fld0_0 || true) ? var5[-45] : var5[95]),
                          (--par2),
                          -37
                        } ??
                        {
                          8589934591,
                          ((--var2) ??
                              (var2 *
                                  ((!(var1))
                                      ? var5[Float32x4.yxxx]
                                      : (var2++)))),
                          (var5[var5[Float32x4.wwzz]] * -30),
                          Int32x4.xzzw,
                          (-((~(22)))),
                          15
                        })))
            ? (fld0_0
                ? var2
                : foo1({
                    var5[-9223372028264841217],
                    foo1(
                        {
                          -82,
                          var5[Float32x4.zzyx],
                          par2,
                          (~(var5[par2])),
                          (par2++),
                          63
                        },
                        (false
                            ? {
                                0,
                                Uint16List.bytesPerElement,
                                -41,
                                8,
                                Int32x4.xxyz,
                                RawSocketOption.levelSocket
                              }
                            : var6)),
                    foo1({var5[(~(-47))], (-(-46))},
                        ({var5[2], (-(-28))} ?? var6)),
                    (par2--),
                    foo1(({var5[-69], 52}).difference(var6),
                        {25, (-(var5[9223372034707292159])), 52}),
                    (var2++),
                    Int32x4.ywyz,
                    (FileSystemEntity.isWatchSupported ? (++par2) : var2)
                  }, {
                    Float32x4.wxzx,
                    var2,
                    par2,
                    var5[var2],
                    par2,
                    var2
                  }))
            : (++par2))]
      };
    }
    return var6;
  }

  Map<int, String> foo0_1(double par1) {
    fld0_0 = (0.8454395181150425).isInfinite;
    return {
      86: var4,
      59: ((((par1 ?? 0.45641338431576617)).toStringAsExponential(
                  (foo1({51, 35, (var1 ? (~(var2)) : -35)}, var6) ^
                      Int32x4.xwzx)))
              .trimLeft() +
          'FX')
    };
  }

  void run() {
    {
      int loc0 = 2;
      while (--loc0 > 0) {
        var2 %= (fld0_0 ? var2 : -26);
      }
    }
    try {
      switch ((true
          ? (~((var1 ? 40 : foo1((var6).difference(var6), {77}))))
          : (92 ?? Float32x4.zxxx))) {
        case 583336190:
          {
            var7 = (foo0_1(((2 ^ var2)).truncateToDouble()) ??
                ((FileSystemEntity.isFileSync('J u') && false)
                    ? ({
                          96: 'PRN',
                          26: 'rayc(',
                          91: '',
                          69: 'NG',
                          78: 'B7',
                          53: 'KOQzI',
                          85: 'ZuksL'
                        } ??
                        var7)
                    : var7));
          }
          break;
        case 583336197:
          {
            var7 = (((--var2) != (~(((var2--) ~/ (++var2)))))
                ? ((true ? Map.from(Map.of(var7)) : var7) ?? var7)
                : foo0_1(0.48262288106096063));
          }
          break;
      }
      for (int loc0 = 0; loc0 < 8; loc0++) {
        /*
         * Multi-line
         * comment.
         */
        {
          int loc1 = 22;
          while (--loc1 > 0) {
            var6 ??= var6;
            var7[(FileSystemEntity.isWatchSupported
                ? foo1(
                    (foo0_0({49: '7asVc2S', 12: 'x\u2665\u{1f600}tI'}, loc0))
                        .difference(((!(true))
                            ? foo0_0({
                                24: 'kB9',
                                87: 'vIEqX@r',
                                36: '5u',
                                34: 'M8\u{1f600}Og\u2665',
                                73: '-bMA\u{1f600}N',
                                39: 'F((\u{1f600}Y',
                                54: 'FHp!'
                              }, 4294967297)
                            : var6)),
                    foo0_0({
                      95: '!sL',
                      30: '\u2665',
                      51: 'E+jWt\u{1f600}',
                      78: 'cCr#k',
                      56: ')P-a'
                    }, -19))
                : 76)] = (var4 + 'n\u2665\u{1f600}j');
          }
        }
      }
    } catch (exception, stackTrace) {
      var3 ??= ((!(true))
          ? foo0(var7[(false
              ? foo1(
                  ((foo0_0({
                            60: 'Nt2h',
                            48: 'gWolH9',
                            42: ')',
                            15: 'n!YW\u2665',
                            79: '7E\u{1f600}'
                          }, 37) ??
                          {19}) ??
                      var6),
                  {-17, 4294967297, -94, -63})
              : (var2--))])
          : ((-(double.nan)) / 0.7833677975390729));
    }
  }
}

main() {
  new X0().run();
}
