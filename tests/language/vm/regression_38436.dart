// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// VMOptions=--optimization_counter_threshold=1

import "package:expect/expect.dart";

// Found by DartFuzzing: would sometimes crash on OSR
// https://github.com/dart-lang/sdk/issues/38436

import 'dart:async';
import 'dart:cli';
import 'dart:collection';
import 'dart:convert';
import 'dart:core';
import 'dart:io';
import 'dart:isolate';
import 'dart:math';
import 'dart:typed_data';

String var0 = '';
bool var1 = true;
int var2 = -30;
double var3 = 0.895077679110543;
String var4 = '';
List<int> var5 = [55, -70];
Set<int> var6 = {
  1024,
  for (int loc0 in [
    79,
    ...[23],
    ...[90, -89, -24],
    -90,
    11,
    -19,
    -91
  ])
    -55,
  67,
  -80,
  for (int loc0 = 0; loc0 < 29; loc0++) 20,
  for (int loc0 = 0; loc0 < 24; loc0++) ...{23, -41},
  ...{
    -75,
    128,
    9223372034707292159,
    -56,
    -59,
    for (int loc0 in {
      -67,
      for (int loc1 in [-27, -59, 31, 32, -66, -87]) -9223372036854775680,
      85,
      -45,
      if (false) 70,
      13,
      43,
      48
    })
      if (true) 63,
    ...{-90, -24, -9223372036854743041, -9223372032559808383, 86},
    -25
  }
};
Map<int, String> var7 = {
  6: '',
  ...{56: 'B\u2665pwO', 73: 'ZJDi\u{1f600}m'},
  ...{73: ')', 14: '93Q'},
  98: 'xA0jQL',
  21: ')\u2665TOy',
  for (int loc0 = 0; loc0 < 82; loc0++) 34: 'Q3\u2665#61',
  ...{70: 'XXRXl3O', 56: '\u2665lda2Zy', 38: 'Dr#mtz', 6: 'nx'},
  27: '('
};

Set<int> foo0() {
  var3 += ((((var0 + var7[var5[88]])).isEmpty ? true : var1)
      ? (var1 ? (var3 ?? var3) : var3)
      : (var1 ? 0.24414824314186978 : var3));
  var1 ??= true;
  return {(var2--), Duration.secondsPerHour, var5[var2]};
}

Map<int, String> foo1(List<int> par1, bool par2) {
  throw ((-(var3)) * (-(0.943305664017911)));
}

List<int> foo2(Set<int> par1, List<int> par2, Map<int, String> par3) {
  switch (-49) {
    case 4149672951:
      {
        for (int loc0 in foo0()) {
          var6 = var6;
          try {
            for (int loc1 = 0; loc1 < 70; loc1++) {
              switch (((var1
                      ? ((var1 ? var1 : true) ? Float32x4.xzzw : (--var2))
                      : (4295032831 % (loc1 + 93))))
                  .floor()) {
                case 3294548737:
                  {
                    var5[Int32x4.xxwy] ^=
                        (loc0 * ('!').compareTo(((!(true)) ? var4 : 'S')));
                  }
                  break;
                case 3294548738:
                  {
                    var0 = var4;
                    loc0 <<= Int32x4.zwxz;
                  }
                  break;
              }
              {
                int loc2 = 0;
                do {
                  var1 = ('Ncb\u2665P9K').isEmpty;
                  var1 ??= (!(true));
                } while (++loc2 < 91);
              }
            }
            par3 ??= {
              44: ((false
                      ? false
                      : ((true
                              ? var7
                              : {
                                  17: par3[(var5[-73] - -20)],
                                  80: var7[
                                      ((++loc0) ~/ ((!(false)) ? 47 : var2))],
                                  30: '8Qvz3',
                                  36: '',
                                  10: (('@B!0bW6' + var4)).toLowerCase(),
                                  89: var7[-9223372036854775296],
                                  4: ') '
                                }) !=
                          var7))
                  ? ((var1 || (!(var1))) ? var7[Float32x4.wxzw] : var7[-7])
                  : '8h'),
              for (int loc1 in [
                (false
                    ? ((([
                                  var2,
                                  -39,
                                  -74,
                                  Float32x4.zzxy,
                                  (~(var5[(67 + -86)])),
                                  -53
                                ] +
                                [(var2++), var5[par2[(--loc0)]]]) !=
                            [
                              var5[var5[var5[(loc0++)]]],
                              loc0,
                              loc0,
                              -55,
                              -69,
                              loc0
                            ])
                        ? (loc0--)
                        : loc0)
                    : var2),
                (75 ^ 93),
                (false ? var5[Float32x4.xzyw] : (loc0++)),
                ...[
                  for (int loc2 in {
                    -22,
                    (loc0 ^ 2),
                    var5[(-((par2[-79] * 86)))],
                    (++loc0),
                    ((par2[var5[-45]] ?? 55) >> (true ? Int32x4.wyww : -45)),
                    (~((++var2))),
                    par2[var2]
                  })
                    (loc0--),
                  if ((var7[(false ? (-(loc0)) : 19)]).endsWith(var4))
                    (++var2)
                  else
                    (var1 ? loc0 : 39),
                  (((var2++) & var2) & -26),
                  if (false) (var1 ? Float32x4.wzzw : var5[129]),
                  for (int loc2 in {
                    (loc0--),
                    (true ? loc0 : loc0),
                    var2,
                    var5[(0.4452451921266031).floor()],
                    (~(-4294967196)),
                    (loc0--),
                    (--var2)
                  })
                    (var1 ? -30 : (loc0++)),
                  (~((var1 ? 51 : var2))),
                  (((var3 ?? pi) < 0.9098824013356337)
                      ? ((true ? 57 : -48) << (--var2))
                      : par2[-59])
                ]
              ])
                84: var4,
              57: var4
            };
          } catch (exception, stackTrace) {
            /**
           ** Multi-line
           ** documentation comment.
           */
            for (int loc1 = 0; loc1 < 89; loc1++) {
              switch ((var2--)) {
                case 3807258589:
                  {
                    print(({
                          (-34 ^
                              ((false || var1)
                                  ? 24
                                  : (-(((-((var1
                                          ? par2[(-(71))]
                                          : 9223372032559808768))) +
                                      (~(loc1))))))),
                          (~((true ? loc0 : (false ? -75 : 33)))),
                          Float32x4.zxwz,
                          (false ? (15 * -83) : (var2--)),
                          ((var7 !=
                                  ((true ? var1 : false)
                                      ? var7
                                      : {
                                          99: (true ? 'TobD' : var0),
                                          59: (var4 ?? var4),
                                          13: var4,
                                          58: Uri.encodeFull(var4),
                                          99: var7[loc1]
                                        }))
                              ? loc1
                              : (var1
                                  ? ((72 >> -15) ~/ (loc0--))
                                  : -9223372030412324864)),
                          32
                        } ??
                        par1));
                  }
                  break;
                case 3807258592:
                  {
                    var1 ??= true;
                    try {
                      var7 = {9: (var1 ? 'ON' : 'f\u{1f600}b')};
                      par2 = (true
                          ? var5
                          : [
                              DateTime.january,
                              (40 - (~(var2))),
                              (var1 ? (--loc0) : 23),
                              var5[(--var2)]
                            ]);
                    } catch (exception, stackTrace) {
                      var3 /= 0.9998663372091022;
                    } finally {
                      par2 ??= ((var1
                              ? false
                              : (((par1 ??
                                          {
                                            -68,
                                            86,
                                            -33,
                                            var5[(-9223372034707292159 - 90)],
                                            (24 - (++var2)),
                                            (-(var2)),
                                            (loc1 * Int32x4.wyxx)
                                          }))
                                      .difference({
                                    (var1 ? Float32x4.yzyw : (loc1 % loc0)),
                                    6,
                                    22,
                                    91,
                                    loc0,
                                    (true ? loc1 : loc1)
                                  }) ==
                                  foo0()))
                          ? par2
                          : [
                              (var2--),
                              (-((++loc0))),
                              ((-(var5[-52])) ~/
                                  (true ? Int32x4.wyyy : (loc0--))),
                              (var3).toInt()
                            ]);
                      var5[99] += (~(Float32x4.ywxw));
                    }
                  }
                  break;
              }
              var5 = (par2 ??
                  [
                    ...[72],
                    for (int loc2 in {Float32x4.xxwz, loc1})
                      ((loc0--) ~/ (var2++)),
                    par2[(++var2)],
                    (-((--var2))),
                    (var2++),
                    -56,
                    (~((~(loc0)))),
                    for (int loc2 in {
                      (-((~(17)))),
                      Float32x4.zzzw,
                      Float32x4.zyyz,
                      (var2--),
                      (Int32x4.wzwz % 78),
                      loc0
                    })
                      Int32x4.xzzy
                  ]);
            }
            {
              int loc1 = 0;
              do {
                loc0 &= (-(4295000065));
              } while (++loc1 < 94);
            }
          } finally {
            var3 -= 0.020483900923215503;
            try {
              return [
                ...[
                  (loc0--),
                  for (int loc1 in {Float32x4.yxyz})
                    if (var1) (~(-35)) else loc0,
                  (++loc0),
                  for (int loc1 = 0; loc1 < 43; loc1++)
                    (var5[var5[par2[var5[-9223372032559808384]]]] &
                        Int32x4.yzxy),
                  for (int loc1 = 0; loc1 < 98; loc1++) (-((~(Int32x4.xwwy)))),
                  Float32x4.yzzz
                ],
                (-(Int32x4.xzxz))
              ];
            } catch (exception, stackTrace) {
              for (int loc1
                  in (((((!((((0.13101852551635873 == 0.4825498460563603)
                                          ? var7
                                          : var7) !=
                                      var7)))
                                  ? 1
                                  : par2[var2]))
                              .isEven
                          ? {
                              (var2++),
                              (-48 | -54),
                              (~(par2[loc0])),
                              par2[var5[Int32x4.zyzz]],
                              -2,
                              (true ? (~((-(((!(false)) ? -11 : var2))))) : 73),
                              if ((0.15992181539430828).isInfinite) (++var2)
                            }
                          : (false ? {-6} : {((++loc0) % 27), 92})) ??
                      Set.identity())) {
                var6 ??= foo0();
              }
              var5[(~(((true ? -10 : Float32x4.zzwy) -
                  Duration.millisecondsPerSecond)))] = (~((var2--)));
            }
          }
        }
        par3.forEach((loc0, loc1) {
          // Single-line comment.
          var6 = (var6 ?? foo0());
          par1 = {
            if (('X2yPgV').endsWith('b'))
              Float32x4.yxxy
            else if (true)
              Int32x4.xzyw
            else
              for (int loc2 = 0; loc2 < 9; loc2++) (++loc0),
            (4294967551 ?? (-((loc0--)))),
            (-69 ~/
                ((!(false))
                    ? ((((par2[Int32x4.zwzw]).isEven
                                ? (var3).truncateToDouble()
                                : 0.14035347150303745))
                            .isInfinite
                        ? Int32x4.yzxx
                        : par2[loc0])
                    : (var2++))),
            ((loc0++) - ((++var2) >> (~(par2[(var2--)]))))
          };
        });
      }
      break;
    case 4149672955:
      {
        par2[((var2 ^ (~((--var2)))) | -98)] *= -62;
        {
          int loc0 = 0;
          do {
            var0 = par3[(var5[4294967808] >> Float32x4.wwyx)];
          } while (++loc0 < 46);
        }
      }
      break;
  }
  var1 ??= (!((var3).isNaN));
  return (var1
      ? par2
      : Uri.parseIPv6Address(
          (var1 ? '' : '26DgiI'), (ZLibOption.maxMemLevel % 65), 68));
}

class X0 {
  bool fld0_0 = true;
  Set<int> fld0_1 = {
    31,
    if (true) ...{
      -93,
      -4294967041,
      -4294934527,
      if (false) 92,
      if (true) 69
    } else
      85,
    ...{
      ...{73, 27},
      for (int loc0 in {
        for (int loc1 = 0; loc1 < 56; loc1++) -36,
        -23,
        -99,
        20,
        16,
        11,
        if (false) -24,
        if (true) 14
      })
        if (false) 69,
      -9223372032559808513,
      -9223372036854775553,
      -9223372036854774784,
      -22
    },
    81,
    ...{16, if (false) 67 else -30, if (true) 21 else -61, -84},
    -69
  };

  List<int> foo0_0(Map<int, String> par1) {
    if ((var1 ? ((!(fld0_0)) ? true : false) : true)) {
      return ((var4).trim()).codeUnits;
    } else {
      for (int loc0 in var6) {
        fld0_0 ??= var1;
        for (int loc1 = 0; loc1 < 57; loc1++) {
          {
            Map<int, String> loc2 = Map.identity();
            par1 ??= Map.unmodifiable(Map.unmodifiable(Map.unmodifiable((true
                ? loc2
                : ((true
                        ? loc2
                        : foo1(
                            [var5[-60], loc0, var5[-48], -80, var5[var5[37]]],
                            var1)) ??
                    {
                      60: var0,
                      93: ((false ? var0 : '') + 'r\u{1f600}2B#p')
                    })))));
            var4 = ' ';
          }
          try {
            var5 = foo2(
                ({loc0, 37, Float32x4.wwyw} ?? var6),
                ((fld0_0
                        ? [
                            for (int loc2 = 0; loc2 < 1; loc2++)
                              (~(Float32x4.zyzz)),
                            (~((true
                                ? (Float32x4.yyzw >> (48 - (-((var2--)))))
                                : (~(loc0))))),
                            ((var4 ==
                                    String.fromEnvironment(
                                        (var1 ? 'l9FM' : par1[var5[loc0]])))
                                ? (++loc0)
                                : 4),
                            ...[
                              (~((var5[-9223372032559808448] - (++var2)))),
                              ...[
                                for (int loc2 in [
                                  ((-12 <= 55) ? 9223372032559841280 : loc0),
                                  var5[var5[(~(var5[var5[loc1]]))]],
                                  (var1 ? 67 : -74)
                                ])
                                  (var5[var2]).sign,
                                var5[-65],
                                if (fld0_0)
                                  var5[(var5[var5[-90]] ~/ 22)]
                                else
                                  (-9223372036854775679 + var5[16]),
                                76,
                                7
                              ],
                              (++var2),
                              -9223372034707292160,
                              (var2--),
                              var5[(var2--)]
                            ],
                            loc1,
                            Float32x4.ywxz,
                            ((++loc0) + (--loc0)),
                            for (int loc2 in [
                              for (int loc3 = 0; loc3 < 4; loc3++) loc1,
                              ...[
                                Float32x4.zxwy,
                                Float32x4.xzwx,
                                var2,
                                (++var2),
                                Int32x4.xzyy,
                                (var5[loc1] | (true ? -97 : -93)),
                                Float32x4.xwyz,
                                ((true || var1)
                                    ? (~((--loc0)))
                                    : (~((var5[18] % (-55 + loc0)))))
                              ],
                              (~((++loc0))),
                              -85,
                              (~((var2++))),
                              (true
                                  ? ZLibOption.maxMemLevel
                                  : var5[var5[var5[var5[var2]]]]),
                              ((true
                                      ? ((!((false
                                              ? (true ? fld0_0 : (!(false)))
                                              : fld0_0)))
                                          ? fld0_0
                                          : (({
                                                96: var4,
                                                60: '(0yBGn\u{1f600}',
                                                57: var4,
                                                73: var7[-43],
                                                38: var0
                                              })
                                                  .isNotEmpty ||
                                              ({
                                                67: var4,
                                                14: 'M\u{1f600}1HNbP',
                                                6: 's',
                                                85: 'uyq',
                                                95: var7[(-(Int32x4.wwxw))],
                                                33: ''
                                              })
                                                  .isNotEmpty))
                                      : false)
                                  ? var2
                                  : (++var2))
                            ]) ...[-27]
                          ]
                        : [
                            for (int loc2 = 0; loc2 < 87; loc2++)
                              (-47 * (~((((--var2) ^ loc0) ?? 78)))),
                            (-(((({
                                  14: (var3).toStringAsExponential(
                                      (false ? var5[-62] : 33)),
                                  16: '',
                                  71: var4,
                                  78: (([var5[(-(91))]] == var5) ? var4 : var0),
                                  9: par1[loc1],
                                  51: '-8ht',
                                  26: ('(2l3\u2665h' ?? var0),
                                  79: var4
                                })
                                        .isNotEmpty
                                    ? var5[(var2 % loc0)]
                                    : var2) %
                                ((!(NetworkInterface.listSupported))
                                    ? -22
                                    : ((var1
                                            ? ([
                                                  ZLibOption.STRATEGY_DEFAULT,
                                                  21,
                                                  loc1,
                                                  loc1,
                                                  loc0,
                                                  5,
                                                  loc0,
                                                  98
                                                ] ==
                                                Uri.parseIPv4Address(
                                                    var7[loc1]))
                                            : var1)
                                        ? (~((-20 %
                                            (var5).removeAt(Float32x4.wyxw))))
                                        : var5[var5[82]]))))),
                            (-(Float32x4.wwwz)),
                            Int32x4.wxxz,
                            ...[
                              (loc0++),
                              ...[
                                (--loc0),
                                -2,
                                ZLibOption.DEFAULT_WINDOW_BITS,
                                -42,
                                for (int loc2 = 0; loc2 < 2; loc2++) (-(-22)),
                                (~(-81))
                              ],
                              (--var2)
                            ],
                            (++var2),
                            ((!(false)) ? (--var2) : (((~(34)) >> 48) << 79)),
                            loc1
                          ]) +
                    foo2(
                        foo0(),
                        ([
                              (((~(var5[(-(var5[(87 % var5[(++var2)])]))])) ??
                                      -11) ~/
                                  (var2++)),
                              ((((!(var1)) && true) ? loc1 : 98) <<
                                  ((!((true != (var4 == par1[var5[(~(-83))]]))))
                                      ? -44
                                      : var5[88])),
                              Float32x4.yyyz,
                              -44,
                              Int32x4.xzyx,
                              (++loc0)
                            ] ??
                            [
                              ((foo1([((!(var1)) ? 24 : 81), -93], true))
                                      .isEmpty
                                  ? 52
                                  : (~(Int32x4.zyww))),
                              Int32x4.xxwz,
                              (-(-11)),
                              (loc0--),
                              ((!(bool.fromEnvironment('U\u2665')))
                                  ? (loc0++)
                                  : (++var2))
                            ]),
                        {
                          70: var7[7],
                          18: '\u2665(#&c\u{1f600}-',
                          58: 'KuNr',
                          96: '\u{1f600}2\u2665YY',
                          94: var0,
                          28: 'l-'
                        })),
                par1);
            {
              double loc2 = double.infinity;
              /*
               * Multi-line
               * comment.
               */
              return ('a!wNh!').codeUnits;
            }
          } catch (exception, stackTrace) {
            continue;
          } finally {
            fld0_0 = (!(fld0_0));
            var5 ??= ((Uri.parseIPv4Address('H') ??
                    (foo2({
                          loc1,
                          ([
                                if (((true ? loc0 : (loc0++)) <
                                    ((!(var1)) ? -90 : Int32x4.yyzx)))
                                  (~(var2))
                                else
                                  for (int loc2 in {
                                    if (SecurityContext.alpnSupported)
                                      var2
                                    else
                                      Int32x4.wzzy,
                                    -9223372036754112763,
                                    (-((var1
                                        ? var5[62]
                                        : (-(Float32x4.wzwz))))),
                                    (~(Float32x4.yxzy))
                                  })
                                    ((((true && (false ? fld0_0 : var1))
                                                ? fld0_0
                                                : false)
                                            ? true
                                            : (fld0_0 && var1))
                                        ? (true ? (~(loc1)) : var5[-16])
                                        : loc0),
                                for (int loc2 = 0; loc2 < 1; loc2++)
                                  ((false && var1) ? Float32x4.yzyy : 50)
                              ][var2] *
                              [
                                ...[
                                  (((-10 >> Int32x4.wxzw) *
                                          ((0.42979687169554437 >=
                                                  0.17848133910264385)
                                              ? -4
                                              : var5[-15])) |
                                      var5[(loc0++)]),
                                  ...[
                                    (('@jcNl\u2665P')
                                            .compareTo(var7[(loc0--)]) &
                                        (~((~(loc0))))),
                                    if ((!(((!(true)) && true)))) 2,
                                    loc1,
                                    ((var5[(loc0--)] | -38) & (loc0++)),
                                    var2,
                                    (~(-22)),
                                    if (false) loc0 else 80,
                                    (--loc0)
                                  ],
                                  ...[15],
                                  ((~((~(-5)))) ^ Int32x4.xxxz),
                                  79,
                                  for (int loc2 in [
                                    (fld0_0 ? -0 : (loc0++)),
                                    -49,
                                    for (int loc3 in [
                                      -16,
                                      (var2--),
                                      35,
                                      ((14 * -68) ~/ Int32x4.wwyy)
                                    ])
                                      var5[(fld0_0 ? 28 : (-41 ?? 19))],
                                    loc0,
                                    (var3).round(),
                                    if ((!((!((!(false))))))) loc1,
                                    (loc0++),
                                    Int32x4.wyww
                                  ])
                                    ((--var2) * var5[(6 & var5[(~(-53))])]),
                                  (loc0++),
                                  Float32x4.xwxx
                                ],
                                Int32x4.ywyw,
                                (-(ZLibOption.strategyFixed)),
                                (80 % (loc0--)),
                                var5[Int32x4.zxww]
                              ][var5[50]]),
                          (false ? -71 : 39),
                          (var5[-61]).toSigned(loc0),
                          -50,
                          4294967296
                        }, [
                          (16 *
                              (~(((var1 ? ZLibOption.STRATEGY_FIXED : -66) *
                                  4)))),
                          Float32x4.wwwx
                        ], {
                          63: var0,
                          52: (fld0_0 ? 'uG\u2665V@4' : '62'),
                          98: var7[var5[-83]],
                          70: (false
                              ? 'bSg'
                              : base64UrlEncode(([
                                    (~(var2)),
                                    -52,
                                    68,
                                    [
                                      10,
                                      loc1,
                                      92,
                                      53,
                                      Int32x4.zzyw,
                                      (true ? 12 : 19),
                                      (~(var5[(++var2)]))
                                    ][-64],
                                    (++loc0),
                                    (loc0 << -26)
                                  ] +
                                  [
                                    var5[(--loc0)],
                                    (((var1 ? var5[var5[(var2--)]] : loc1) +
                                            (--var2)) <<
                                        Int32x4.wyyx)
                                  ]))),
                          16: 'YsD\u2665\u2665K',
                          0: var0,
                          93: var7[(-(var5[-43]))]
                        }) ??
                        var5)) ??
                [
                  if (fld0_0) -90,
                  (--var2),
                  ...[
                    for (int loc2 in [
                      (false ? (~(-9)) : -4294901760),
                      (-(-7)),
                      -51,
                      (var1 ? -75 : [Float32x4.wwxw, Int32x4.zxyx][-7]),
                      Float32x4.xyww,
                      Int32x4.wwzx,
                      (loc0++),
                      (NetworkInterface.listSupported
                          ? [1000][Float32x4.zzyx]
                          : -71)
                    ])
                      -27,
                    Float32x4.wyzy,
                    (++var2)
                  ]
                ]);
          }
        }
      }
      throw Map.unmodifiable(foo1(
          (MapBase.mapToString(foo1((false ? [var2] : var5), false))).codeUnits,
          true));
    }
  }

  void run() {}
}

class X1 extends X0 {
  double fld1_0 = 0.47694301047645304;
  bool fld1_1 = true;

  Map<int, String> foo1_0(
      Map<int, String> par1, Map<int, String> par2, double par3) {
    // Single-line comment.
    for (int loc0 = 0; loc0 < 91; loc0++) {
      par2.forEach((loc1, loc2) {
        {
          bool loc3 = (fld1_1 || ('U\u2665').isEmpty);
          var3 /= 0.8504341352135224;
        }
      });
      {
        int loc1 = 66;
        while (--loc1 > 0) {
          if (((!((true || fld1_1))) == true)) {
            var0 ??= par2[var5[(~((false ? ((!(var1)) ? -95 : var2) : -37)))]];
            /**
             ** Multi-line
             ** documentation comment.
             */
            return Map.unmodifiable({
              55: var4,
              73: 'c#',
              17: (fld1_1
                  ? '7\u{1f600}e'
                  : ((!(var1)) ? '8E7AK2e' : 'Fm\u{1f600} F')),
              40: 'mb(\u{1f600}\u2665l',
              36: Uri.decodeFull((true ? par2[-32769] : var7[Float32x4.zyxz])),
              51: ((false &&
                      (((var1 ? true : true) || false)
                          ? (var7[(var2--)]).isEmpty
                          : true))
                  ? (fld1_1
                      ? (fld1_1 ? (var1).toString() : 'r9M')
                      : ((true ? (0.2863696758528199 != par3) : false)
                          ? (fld1_1 ? par1[Int32x4.zwyz] : var4)
                          : var4))
                  : var4),
              8: '6G',
              62: '+z@Gp'
            });
          } else {
            var5[Int32x4.zzyy] ??= (-(var5[((!(false)) ? loc1 : -34)]));
            {
              int loc2 = (-(7));
              var3 /= (true
                  ? (-(((-9223372032459145467).isEven
                      ? fld1_0
                      : (-((-(0.7008573255099826)))))))
                  : par3);
            }
          }
          for (int loc2 in foo2(var6, var5, {
            if (false) 11: par1[((var4).isEmpty ? 55 : -61)],
            12: 'f5j2v\u{1f600}',
            52: (((foo1(
                            (((var1
                                        ? {var5[-66], var2, 88, 12, 6, -96}
                                        : (var1
                                            ? {-25, 84, (var2--), var5[83]}
                                            : {-36, var5[51], var2})) !=
                                    {var5[(++var2)]})
                                ? [-2147483648, 46, loc0, var5[loc0], -21]
                                : foo2(
                                    {var5[var5[loc0]]},
                                    (true
                                        ? var5
                                        : [
                                            -30,
                                            var5[(-(-42))],
                                            var2,
                                            Float32x4.zywx,
                                            loc1,
                                            63,
                                            -25,
                                            -28
                                          ]),
                                    {30: 'j\u2665U', 98: var4})),
                            false))
                        .isNotEmpty
                    ? (false ? fld1_0 : 0.3202297128057393)
                    : 0.1301025669674245))
                .toStringAsFixed(((fld1_1 ? 79 : -88) + Int32x4.xyzw)),
            88: (false ? var7[(var2++)] : (var4 ?? '')),
            31: (var1
                ? (var1 ? par2[-87] : (true ? par2[-14] : var4))
                : ((fld1_1 != true) ? '3nd9t&' : var4)),
            22: ('(Czi' + '-Y')
          })) {
            var7[(loc2--)] = 's';
          }
        }
      }
    }
    return par1;
  }

  String foo1_1(int par1) => var0;
  Set<int> foo1_2(String par1) {
    for (int loc0 = 0; loc0 < 58; loc0++) {
      switch ((~(13))) {
        case 746492976:
          {
            switch (Duration.millisecondsPerDay) {
              case 3635015902:
                {
                  var7[var5[(var5[var2] * (-(var5[Float32x4.yxxz])))]] ??=
                      (var7[-79] + '(O@');
                  var7[loc0] ??= String.fromCharCode(var5[(true
                      ? (var5[((var1 ? true : (false ? fld1_1 : var1))
                              ? var5[Float32x4.wyyz]
                              : 73)] ~/
                          (-(84)))
                      : -15)]);
                }
                break;
              case 3635015905:
                {
                  var1 = (var1
                      ? (foo1_0(
                              (((!(false)) || fld1_1) ? var7 : var7),
                              foo1_0(
                                  {74: '\u2665e', 10: 'tw8jc0R'},
                                  foo1_0(
                                      var7,
                                      foo1_0(
                                          ({
                                                17: var7[Int32x4.zyxy],
                                                82: var7[64],
                                                27: 'VEtj',
                                                90: Uri.encodeQueryComponent(
                                                    foo1_1(var2)),
                                                68: 'wew0\u{1f600}'
                                              } ??
                                              foo1_0(var7, var7, var3)),
                                          ({
                                                65: 'mBeBfUj',
                                                81: var4,
                                                35: (var7[-43] + 'l'),
                                                68: var4
                                              } ??
                                              {
                                                33: ('N\u{1f600}xaY+' ?? par1),
                                                44: var7[var5[var2]],
                                                83: var4,
                                                86: 'k'
                                              }),
                                          asin(0.4245871535895427)),
                                      (-(0.2913717674787144))),
                                  0.9439800024935644),
                              (-((true
                                  ? ((var1 ? false : var1)
                                      ? 0.09441225978923817
                                      : 0.42622157485045953)
                                  : (-(0.29370792038584836)))))))
                          .isNotEmpty
                      : (false && true));
                  var3 += (-(fld1_0));
                }
                break;
            }
          }
          break;
        case 746492979:
          {
            var4 = var0;
            for (int loc1 = 0; loc1 < 88; loc1++) {
              var2 += 32;
            }
          }
          break;
      }
    }
    {
      int loc0 = 0;
      do {
        return foo0();
      } while (++loc0 < 57);
    }
    return foo0();
  }

  String foo1_3() {
    if ((0.42144855521066793).isNegative) {
      print((false ? (-(fld1_0)) : (-((-((-(0.26854952952179667))))))));
      switch (30) {
        case 3830102525:
          {
            try {
              var7.forEach((loc0, loc1) {
                var1 = (!(true));
                var6 = (foo1_2(var7[99]) ?? var6);
              });
              var6 ??= var6;
            } catch (exception, stackTrace) {
              var4 ??= ListBase.listToString([
                (Duration.microsecondsPerSecond + -82),
                (true
                    ? var5[(var2 ~/ (false ? (~((var1 ? 46 : var2))) : var2))]
                    : (-9223372034707292161 >> var5[var5[-86]])),
                Float32x4.wxyx
              ]);
            } finally {
              /**
             ** Multi-line
             ** documentation comment.
             */
              fld1_1 = (var5[var5[var2]]).isOdd;
            }
            /*
           * Multi-line
           * comment.
           */
            if ((SetBase.setToString((fld1_1
                    ? {12, (fld1_1 ? (-(-22)) : (-(4395630341)))}
                    : var6)))
                .isNotEmpty) {
              try {
                {
                  int loc0 = 86;
                  while (--loc0 > 0) {
                    {
                      int loc1 = 0;
                      do {
                        var0 = var7[(-(((--var2) &
                            ((var1 ? (fld1_0).isNaN : true)
                                ? (-16 | -20)
                                : ((0.7513819161190503).isNaN ? 45 : loc1)))))];

                        /// Single-line documentation comment.
                        var5[(true ? loc0 : Float32x4.zxzx)] %= loc0;
                      } while (++loc1 < 17);
                    }
                    for (int loc1 = 0; loc1 < 25; loc1++) {
                      var5[Float32x4.zywy] <<= Int32x4.ywwx;
                    }
                  }
                }
              } catch (exception, stackTrace) {
                var7 = Map.from(foo1_0({
                  81: (foo1_1(((++var2) * (-(var5[21])))) +
                      (var7[8] + (var7[var5[53]] ?? var0))),
                  for (int loc0 in [
                    (true ? 58 : Float32x4.wyww),
                    var5[(fld1_1 ? 46 : var2)]
                  ])
                    63: var7[(false
                        ? var5[((24 >> -9223372036854710272) & var2)]
                        : var5[(80 << var5[-31])])],
                  67: var0,
                  1: '3mlOA',
                  30: ('OQbG').substring((var2--), (--var2)),
                  93: ((var7[74] ?? var7[(++var2)])).toLowerCase(),
                  ...{
                    85: foo1_1(-21),
                    if ((!((!(false))))) 86: var0,
                    49: '62+v',
                    59: foo1_1((--var2)),
                    for (int loc0 in [
                      -10,
                      -65,
                      (var2++),
                      (var2++),
                      ((({
                                    ((var7[60] == var7[-30])
                                        ? var5[(-((var2++)))]
                                        : (var2--))
                                  } ==
                                  {var5[var2], -40, -81, (var2++), 93, 26})
                              ? 38
                              : (var1 ? var5[97] : -82)) *
                          (--var2)),
                      (~((true ? 5 : Float32x4.yxyy))),
                      (var2++),
                      ((++var2) << ((var2 % Int32x4.yxxw) >> (++var2)))
                    ])
                      54: (var0 + 'ANyqN'),
                    94: (var1 ? '0T\u2665#w' : (var0).toUpperCase()),
                    68: '@n',
                    67: base64UrlEncode(((0.07857744084458451).isInfinite
                        ? ([
                              var2,
                              var5[70],
                              -32,
                              Float32x4.yxwz,
                              31,
                              (~(var2)),
                              (var2 ?? (-70 + 57)),
                              -91
                            ] +
                            [
                              var2,
                              var5[((!(var1))
                                  ? var5[(var2 ~/ Float32x4.zwyw)]
                                  : var5[var5[(var5[(~(var2))] % var2)]])],
                              (var2 | (false ? (-(var2)) : var5[80])),
                              (var2--),
                              DateTime.daysPerWeek,
                              (var2 ~/ var2)
                            ])
                        : (var1 ? var5 : [(var2++)])))
                  },
                  if (false)
                    if (false)
                      26: (Uri.encodeComponent(foo1_1(var2)) + var7[var5[var2]])
                    else ...{
                      4: (double.negativeInfinity).toStringAsFixed(var2),
                      46: Uri.decodeQueryComponent('bst3jz'),
                      5: ((true
                              ? (true ? '(-f' : var7[(-(Int32x4.yzxz))])
                              : var7[(var5[(fld1_1 ? (var2--) : var2)] >>
                                  (-((false ? 8589934591 : 33))))]) ??
                          '4ov'),
                      37: var7[var5[100663045]],
                      13: '2B'
                    }
                }, {
                  71: 'Hxbq',
                  22: ('\u{1f600}Jtj').substring(
                      (-36 | var5[(~((var2++)))]), 9223372032559874048)
                }, 0.3710694748818374));
                fld1_0 ??= 0.010604823956237519;
              } finally {
                for (int loc0 = 0; loc0 < 84; loc0++) {
                  var5[Float32x4.xwwz] <<=
                      ((((fld1_1 ? false : ('e\u{1f600}O+Vc').isNotEmpty) &&
                                  (!(fld1_1)))
                              ? (-73 | var5[Int32x4.yzwx])
                              : Uint16List.bytesPerElement) ~/
                          var2);
                }
              }
            }
          }
          break;
        case 3830102528:
          {
            fld1_1 ??= true;
            throw (-((-17).ceilToDouble()));
          }
          break;
      }
    }
    return var0;
  }

  void run() {
    super.run();
    {
      int loc0 = 61;
      while (--loc0 > 0) {
        {
          int loc1 = 77;
          while (--loc1 > 0) {
            {
              int loc2 = 0;
              do {
                break;
              } while (++loc2 < 84);
            }
          }
        }
        if (((var1 || fld1_1) && (!((!((!((!((!(true)))))))))))) {
          switch (Int32x4.yyzx) {
            case 900727295:
              {
                /// Single-line documentation comment.
                fld1_1 ??= (!(true));
                for (int loc1 in ((var5 ??
                        Uri.parseIPv6Address(
                            foo1_3(), var5[(loc0 + var5[4096])], -34)) ??
                    var5)) {
                  var7[(38 << (false ? (~(-58)) : Float32x4.yyxy))] =
                      Uri.decodeFull(foo1_3());
                  var5 ??= var5;
                }
              }
              break;
            case 900727304:
              {
                fld1_1 =
                    (SecurityContext.alpnSupported ? (var3).isFinite : var1);
                fld1_0 += 0.3154406798513474;
              }
              break;
          }
          var2 ^= var2;
        } else {
          if (((-(var3)) <= (-(fld1_0)))) {
            var6 = foo1_2('0vsDWF9');
          } else {
            var6 ??= ((fld1_0 <= 0.16230005903410238)
                ? ((!((0.5144029832155854 > (0.8199455895430549 / var3))))
                    ? foo1_2('ken')
                    : var6)
                : (fld1_1 ? {56, 6442450945, 2} : {34}));
          }
          var5[Float32x4.zwzw] += (true ? var2 : (~(Float32x4.wyyx)));
        }
      }
    }
  }
}

class X2 extends X0 with X1 {
  Set<int> fld2_0 = {for (int loc0 = 0; loc0 < 60; loc0++) -56, 29};

  bool foo2_0(int par1) => var1;
  bool foo2_1(bool par1) {
    for (int loc0 in var6) {
      var2 ~/= ((((((fld2_0 ?? (true ? var6 : var6)) ?? fld2_0))
                      .union({(~(-21)), 10}) !=
                  {(var5[90] ~/ (-(-90)))})
              ? par1
              : (var7[(~(82))]).isNotEmpty)
          ? ((~(loc0)) *
              ((true ? (-4294966272 ?? -21) : var2) +
                  Duration.millisecondsPerMinute))
          : (-9223372032559807488 ~/ 4294968296));
    }
    if (('DeAm#f' ==
        ((Uri.encodeQueryComponent((0.3687340601979223).toString()) ??
                var7[-23]) ??
            foo1_3()))) {
      throw (([Float32x4.wyyz, -9223372036854743039])
              .sublist((--var2), (--var2)) +
          ((true ? var1 : (!(false)))
              ? foo2(
                  foo1_2('JLXt'),
                  [
                    var5[Int32x4.zxzx],
                    Int32x4.xxwy,
                    (var2++),
                    Float32x4.yzxx,
                    (var2++),
                    -15
                  ],
                  foo1_0(var7, var7, 0.7904389283184639))
              : (var1
                  ? [Float32x4.yzyz, Int32x4.wxxy, var2, (~(var5[-47]))]
                  : var5)));
    } else {
      var7[var2] ??= ((({
            ...{
              for (int loc0 = 0; loc0 < 19; loc0++)
                36: (var7[var2] ?? (par1 ? ('ccb9z' + 'iM') : var0)),
              3: ('1sG' + var0),
              for (int loc0 in {
                (-(var5[var2])),
                if (var1) Int32x4.zxxx,
                -4294967168,
                -61,
                (~((par1 ? (~(-70)) : (var2--)))),
                (-(7)),
                -96,
                Uint32List.bytesPerElement
              })
                85: var4
            },
            if (foo2_0(-91)) 38: (var3).toString() else 30: 'uI\u2665\u{1f600}',
            72: '@'
          }[(par1 ? 14 : var2)])
                  .trim())
              .substring((36 ~/ var5[(++var2)]), var5[((-(25)) * -53)]) ??
          foo1_3());
      /*
       * Multi-line
       * comment.
       */
      {
        int loc0 = 0;
        do {
          {
            String loc1 = 'jG7t';
            /**
             ** Multi-line
             ** documentation comment.
             */
            {
              int loc2 = 57;
              while (--loc2 > 0) {
                print((var6 ??
                    (foo1_2(var0)).union(foo1_2(('n' + var7[(++var2)])))));
              }
            }
          }
        } while (++loc0 < 69);
      }
    }
    return (!(((!((par1 && false)))
        ? (true && foo2_0(-9223372036854771712))
        : (!(par1)))));
  }

  double foo2_2(Map<int, String> par1, int par2) {
    switch (var2) {
      case 3816231196:
        {
          throw (-(Int32x4.xxwx));
        }
        break;
      case 3816231204:
        {
          var7.forEach((loc0, loc1) {
            switch ((-43 ^ (-(Float32x4.wwxx)))) {
              case 2839002105:
                {
                  var0 ??= (SetBase.setToString(((var1 ? var1 : (true || var1))
                          ? fld2_0
                          : {
                              Int32x4.yyzw,
                              Int32x4.yyxy,
                              (2 >> Int32x4.ywzx),
                              (var1
                                  ? ((foo2_1(var1) ? 17 : loc0) ~/
                                      (-(var5[var2])))
                                  : par2),
                              Float32x4.zwwx,
                              par2,
                              Int32x4.wzzz,
                              Int32x4.zyzw
                            })) ??
                      (loc1 +
                          var7[((true
                                  ? (var1 &&
                                      bool.fromEnvironment(var7[(var2--)]))
                                  : foo2_1(false))
                              ? 35
                              : (-(66)))]));
                  for (int loc2 = 0; loc2 < 23; loc2++) {
                    switch ((-73 ^ (Int32x4.xyzz >> Float32x4.yzzz))) {
                      case 1710454916:
                        {
                          var3 = 0.3372913861348876;
                          print(((-(var3)) * var3));
                        }
                        break;
                      case 1710454922:
                        {
                          var4 ??= ((false
                                  ? (var1
                                      ? var1
                                      : (fld2_0 ==
                                          {
                                            (false ? -27 : (-(92))),
                                            loc2,
                                            var5[loc2],
                                            (var1
                                                ? Float32x4.yywy
                                                : (false ? -74 : 2)),
                                            ((-(-50)) ^ 32),
                                            (var2++)
                                          }))
                                  : var1)
                              ? base64UrlEncode([
                                  for (int loc3 in {
                                    (-(par2)),
                                    loc0,
                                    (-((par2++))),
                                    Float32x4.yyyx
                                  })
                                    (par2--),
                                  (-((-(var5[var5[var5[-41]]])))),
                                  if (({
                                        loc2,
                                        Duration.microsecondsPerSecond,
                                        (([
                                                  (par2++),
                                                  (-90 ^ -5),
                                                  var5[(~(0))],
                                                  loc2
                                                ] !=
                                                var5)
                                            ? -9223372032559808512
                                            : (par2++))
                                      } ==
                                      {
                                        (var1 ? (-((loc2 % loc2))) : loc2),
                                        -94,
                                        -62
                                      }))
                                    (++var2),
                                  loc2,
                                  for (int loc3 in {
                                    55,
                                    (~(var5[var5[(++par2)]])),
                                    ((var1
                                            ? (-((++var2)))
                                            : var5[(true ? var5[68] : 10)]) -
                                        par2),
                                    (-(Float32x4.wzxx))
                                  })
                                    (Int32x4.yxzy | var5[-1]),
                                  (foo2_1(false) ? (-(32)) : loc0),
                                  (--par2),
                                  if ((!(false))) (var1 ? var5[loc0] : 30)
                                ])
                              : ('b1TKp3' ??
                                  (var4 +
                                      var7[(~(var5[
                                          ((var1 ? var2 : loc2) - 72)]))])));
                        }
                        break;
                    }
                    fld2_0 = ((!((false
                            ? false
                            : (false ? (!((var7[-28] != ''))) : var1))))
                        ? (((var1
                                    ? (true ? Set.identity() : var6)
                                    : {
                                        -63,
                                        Int32x4.xxyx,
                                        var5[((var1
                                                ? (var5[-9223372032559808496] >>
                                                    59)
                                                : Int32x4.wxxy) ~/
                                            var5[var5[-48]])],
                                        (par2 ?? par2),
                                        44,
                                        var5[(var1 ? -26 : (-(par2)))]
                                      }) ??
                                ({
                                      loc2,
                                      var2,
                                      ZLibOption.defaultMemLevel,
                                      (true ? Int32x4.wyzz : 40),
                                      (false ? loc2 : var5[42]),
                                      -16
                                    } ??
                                    var6)))
                            .union({loc0, (var2++), (-1 * (~(var2)))})
                        : (bool.fromEnvironment((var3)
                                .toStringAsFixed(Uint64List.bytesPerElement))
                            ? fld2_0
                            : {
                                (par2++),
                                (var1 ? loc2 : (++var2)),
                                ((false || false) ? Int32x4.xyyz : (++par2)),
                                var5[-98],
                                Float32x4.zwwy,
                                var5[var5[62]],
                                (~(Float32x4.ywww))
                              }));
                  }
                }
                break;
              case 2839002106:
                {
                  for (int loc2 = 0; loc2 < 13; loc2++) {
                    {
                      int loc3 = 0;
                      do {
                        switch ((loc3 | -76)) {
                          case 2164097105:
                            {
                              var4 ??= (var1).toString();
                              var5 = ((!(((true || var1) !=
                                      (false ? var1 : (!(foo2_1(var1)))))))
                                  ? foo2(
                                      ((var6).union(foo1_2(loc1))).toSet(),
                                      [
                                        -67,
                                        if (((var1
                                                ? 59
                                                : (-((false ? -97 : par2)))) !=
                                            (false
                                                ? ((var1 || var1)
                                                    ? (-((par2++)))
                                                    : 4)
                                                : (--var2)))) ...[
                                          ((92 ~/ Int32x4.yzwx) << 70),
                                          Float32x4.xxyz,
                                          Int8List.bytesPerElement
                                        ] else
                                          69
                                      ],
                                      var7)
                                  : foo2(foo0(), Uri.parseIPv4Address(var0),
                                      var7));
                            }
                            break;
                          case 2164097111:
                            {
                              var4 ??= var7[Float32x4.zxzw];
                            }
                            break;
                        }
                      } while (++loc3 < 96);
                    }
                    fld2_0 = var6;
                  }
                }
                break;
            }
          });
          for (int loc0 in (foo2_1((var5 !=
                  (false
                      ? [par2]
                      : foo2(
                          var6,
                          [20],
                          ({
                                21: var0,
                                68: foo1_3(),
                                24: ('1MF' + '8s\u2665yx+ ')
                              } ??
                              {
                                9: var7[var2],
                                48: 'mB(wW\u{1f600}',
                                74: 'ojEw\u{1f600}\u{1f600}',
                                80: '\u26655E-hj\u{1f600}',
                                10: (false ? 'W7i5\u2665YX' : '! Ed9&'),
                                88: (false ? var0 : 'N0D9(H\u{1f600}'),
                                5: 'QZ'
                              })))))
              ? foo1_2('XP')
              : {
                  if ((foo2_1(var1)
                      ? (foo2_1((fld2_0).add(-9223372036854774784)) || var1)
                      : var1))
                    (~(Float32x4.zyww)),
                  Float32x4.xwyw,
                  ((((var1 ? true : var1) ? 0.3447071353935154 : var3) >=
                          0.5995056331958718)
                      ? ZLibOption.MAX_LEVEL
                      : 16),
                  9223372032559841279,
                  Int32x4.zwyy
                })) {
            for (int loc1 = 0; loc1 < 19; loc1++) {
              var1 = (!(bool.fromEnvironment(MapBase.mapToString({
                1: '4',
                56: var0,
                85: var0,
                51: var7[-4],
                42: ((!((!(false)))) ? par1[72] : MapBase.mapToString(var7))
              }))));
            }
          }
        }
        break;
    }
    print((((var1 ? 'kP' : (var1 ? 'irjF' : var7[var5[90]])) ??
            ((!(false)) ? 'vWa\u{1f600}' : var0)) +
        'xzpK'));
    return var3;
  }

  void run() {
    super.run();
    {
      int loc0 = (~(-24));
      var0 ??= ((false
              ? foo2_1((true
                  ? (var1 && (var2).isOdd)
                  : (('dTYR' ?? 'G\u{1f600}P14\u{1f600}a')).isEmpty))
              : ((var1 && true) || (!(var1))))
          ? (var4 ?? 'I')
          : 'QO');
    }
  }
}

class X3 extends X1 {
  Map<int, String> fld3_0 = {
    if (true) if (false) 45: 'ynEn\u2665nG' else 70: 'c\u{1f600}mN4\u2665a',
    if (true) 30: '6\u2665P!Pbi',
    81: 't',
    82: '17fx#!',
    92: 'H',
    if (true) 69: ')Ls'
  };
  Set<int> fld3_1 = {27};
  int fld3_2 = 34;

  String foo1_1(int par1) {
    throw (ListBase.listToString(foo2({
          -4294967169,
          par1
        }, [
          -97,
          (var5[(var1 ? var5[87] : Int32x4.yxxy)] * Int32x4.yyxx),
          var2,
          (false ? 10 : var5[var5[(par1++)]])
        ], var7)) ??
        'o');
  }

  bool foo3_0(double par1) {
    {
      Set<int> loc0 = (true ? fld3_1 : var6);
      {
        Set<int> loc1 = (false
            ? foo0()
            : {
                for (int loc2 in [var2, (-(Float32x4.xzzw))])
                  if (false) Float32x4.wxyz else (++fld3_2),
                ((var1
                        ? 5
                        : var5[(((var5[(true ? fld3_2 : fld3_2)] ~/ 48) | 56) %
                            var5[-4])]) ??
                    (var2++))
              });
        for (int loc2 = 0; loc2 < 90; loc2++) {
          {
            int loc3 = 95;
            while (--loc3 > 0) {
              return (((0.7073184699576396).isNaN
                      ? var7
                      : (Map.of(Map.from(var7)) ??
                          Map.unmodifiable(Map.identity()))))
                  .isEmpty;
            }
          }
          try {
            var1 = (((12 >= Int32x4.ywxx) ? true : true)
                ? false
                : (((var1 ? fld3_0[Int32x4.wyxy] : '') ?? var7[Float32x4.xwwx]))
                    .isEmpty);
            var2 |= ((fld3_2++) ?? (fld3_2--));
          } catch (exception, stackTrace) {
            var5 ??= var5;
          } finally {
            var4 = 'A';
            break;
          }
        }
        {
          double loc2 = (-(exp((acos(0.06129144867031855) ?? var3))));
          fld3_0 = (((({Int32x4.ywxw, 6442450943}).union(foo0()))
                      .add((++fld3_2))
                  ? false
                  : false)
              ? foo1_0(
                  (foo1([var5[var2], var5[75], 42], false) ?? var7), var7, loc2)
              : (var1
                  ? {
                      for (int loc3 = 0; loc3 < 48; loc3++) 78: 'dWek8',
                      40: fld3_0[(var5[-81] & Int32x4.xzyw)],
                      73: (' )G\u2665-d(').substring(
                          (NetworkInterface.listSupported
                              ? (~(((++var2) ?? (fld3_2 * fld3_2))))
                              : var5[-75]),
                          fld3_2),
                      74: ('k9O\u2665').trimLeft(),
                      88: var7[(++var2)],
                      for (int loc3 = 0; loc3 < 27; loc3++)
                        60: ((false || var1) ? var7[46] : var0),
                      99: ((var3).isNaN
                          ? (Uri.decodeComponent(foo1_3()) + var4)
                          : var7[-77]),
                      92: (true
                          ? ('').padLeft(82, '')
                          : ('' ?? var7[(false ? 94 : 58)]))
                    }
                  : var7));

          /// Single-line documentation comment.
          fld3_1 ??= ((loc1 ?? foo1_2(fld3_0[(var2--)])) ?? foo1_2(foo1_3()));
        }
      }
    }
    return (var1 ? (!(var1)) : var1);
  }

  String foo3_1(int par1, String par2, String par3) {
    switch (var2) {
      case 3768780679:
        {
          {
            int loc0 = (++par1);
            var0 ??= ListBase.listToString(var5);
            if (true) {
              var5 = [
                Float32x4.xyxz,
                (var1
                    ? ((!(false)) ? Float32x4.xyyw : (++fld3_2))
                    : var5[fld3_2]),
                par1,
                (~(Float32x4.zxwy)),
                if ((foo3_0(var3)
                    ? ([
                          (++fld3_2),
                          ...[
                            ...[
                              var5[(true ? Float32x4.xxzx : (--fld3_2))],
                              54,
                              (-((((foo3_0(var3)
                                          ? (!(false))
                                          : ((var1 ? (~(-63)) : var5[-40]))
                                              .isOdd)
                                      ? ((0.8329420640871532 != var3) && var1)
                                      : var1)
                                  ? 43
                                  : (Float32x4.zxxy - Float32x4.zxxw)))),
                              Int32x4.zzwx
                            ],
                            ...[
                              (var5[-48] * (fld3_2++)),
                              Int32x4.wyyw,
                              (~(-76)),
                              ((par1).isEven ? (--par1) : -13),
                              Float32x4.wxyx
                            ],
                            for (int loc1 in [
                              (++fld3_2),
                              -15,
                              (SecurityContext.alpnSupported
                                  ? Int32x4.yxyw
                                  : Float32x4.yxxw),
                              if (true) var5[(var1 ? -32768 : par1)],
                              ((--var2) ^ (++fld3_2))
                            ])
                              (fld3_2--),
                            93,
                            (~((-(ZLibOption.minMemLevel)))),
                            ((Float32x4.zyzx >> -14) & Float32x4.yxxw)
                          ],
                          (var1
                              ? (++par1)
                              : ((var3).isInfinite ? Float32x4.zwww : -84)),
                          var2
                        ] ==
                        [
                          9223372032559808639,
                          -85,
                          Float32x4.wzyy,
                          loc0,
                          [
                            ((-(36)) <<
                                ((var1
                                        ? var1
                                        : ({
                                            45: 'ay',
                                            7: par3,
                                            69: Uri.decodeFull(
                                                (foo1_3() + 'LX+'))
                                          })
                                            .isEmpty)
                                    ? (~((13 | 64)))
                                    : (-(var2)))),
                            (par1--),
                            ((~((true ? (var2--) : -31))) >> 9),
                            (-((35 % (~(var5[var5[39]]))))),
                            4395630341,
                            Int32x4.zxxy,
                            if ((var1
                                ? foo3_0(var3)
                                : (0.6201792653929837).isInfinite)) ...[
                              Int32x4.wxxx,
                              (fld3_2 * (--fld3_2)),
                              var5[((~(var5[var5[var5[(-(-23))]]])) +
                                  (~(-4294966296)))],
                              loc0,
                              for (int loc1 in [var5[Float32x4.yzww]]) 17,
                              (~(var5[(++par1)])),
                              -58,
                              ((!(('').isEmpty))
                                  ? ((-(Float32x4.ywwx)) * (++par1))
                                  : Int32x4.yxyz)
                            ]
                          ][((var1 ? var1 : var1) ? var5[0] : par1)],
                          ((~(70)) +
                              (par1 + (-77 | ZLibOption.MAX_WINDOW_BITS))),
                          (-(Int32x4.zywy)),
                          (~(Float32x4.zywz))
                        ])
                    : (var1 ? true : true)))
                  fld3_2
              ];
            }
          }
          var3 *= ((var3 + 0.6761038672016147) ?? (-(double.minPositive)));
        }
        break;
      case 3768780685:
        {
          {
            int loc0 = 67;
            while (--loc0 > 0) {
              {
                Map<int, String> loc1 = foo1(
                    Uri.parseIPv4Address(('E Hu\u{1f600}' + '\u2665l&#!')),
                    (!(false)));
                var3 ??= var3;
              }
              var5 = (var5 +
                  ((({
                    79: (foo1_3() ?? 'eD'),
                    73: (var1 ? par2 : ' xdXgW'),
                    4: 'pUc(q',
                    15: 'K\u{1f600}hmdZ\u2665',
                    95: (var1 ? var4 : (var1 ? fld3_0[-45] : foo1_3()))
                  })
                              .isNotEmpty
                          ? ((var1 ? var1 : (var1 ? var1 : foo3_0(var3))) ||
                              foo3_0(var3))
                          : (!(((false || true) ? var1 : false))))
                      ? [
                          (~((-61 ??
                              (~((-(var5[(var1 ? fld3_2 : var5[34])]))))))),
                          (var5[13] ^ (var1 ? 35 : -76)),
                          (-(((~(-47)) ~/ (--par1))))
                        ]
                      : foo2({
                          -36,
                          ((0.3910802543332075).isNegative
                              ? (~((var2++)))
                              : (var2 &
                                  (var1
                                      ? [
                                          -67,
                                          (fld3_2++),
                                          if ((!((!((var1
                                              ? true
                                              : (!(false))))))))
                                            (false
                                                ? (~(Float32x4.wyyy))
                                                : (var1
                                                    ? (1 ^ (-(16)))
                                                    : var5[94])),
                                          fld3_2,
                                          var2,
                                          67
                                        ][-12]
                                      : Float32x4.wwxw))),
                          26,
                          [
                            (var1
                                ? (--fld3_2)
                                : (((!(var1))
                                        ? (~((foo3_0(0.9959805940480148)
                                            ? (33 ~/ loc0)
                                            : Float32x4.xywx)))
                                        : (15 % var5[var5[-47]])) <<
                                    -86)),
                            (-((~(RawSocketOption.levelIPv6))))
                          ][var5[var5[(ZLibOption.maxMemLevel ^ -3)]]],
                          -29
                        }, [
                          (var1 ? Float32x4.wxxw : (--par1)),
                          ...[
                            52,
                            (-((true ? -12 : 44))),
                            var5[((var5[34] * 30) >> 4294967360)],
                            ((--var2) <<
                                (true
                                    ? var5[(-4 ~/ Int32x4.yyww)]
                                    : (bool.fromEnvironment(var7[fld3_2])
                                        ? (~((false ? loc0 : var5[(++par1)])))
                                        : ((!(false))
                                            ? (var5[var5[loc0]] ^ Int32x4.wxzz)
                                            : par1)))),
                            (((false ? var0 : '') !=
                                    (true
                                        ? MapBase.mapToString(({
                                              7: 'WTT7\u{1f600}e3',
                                              22: '',
                                              36: (var1
                                                  ? 'F'
                                                  : (var1 ? fld3_0[var2] : '')),
                                              37: 'l@a',
                                              85: (var1 ? '' : par3),
                                              82: 'eb',
                                              37: '11',
                                              41: var7[94]
                                            } ??
                                            var7))
                                        : (var1 ? var4 : par2)))
                                ? (~(var5[-71]))
                                : 9),
                            32,
                            if (bool.fromEnvironment(
                                fld3_0[var5[ZLibOption.MIN_MEM_LEVEL]]))
                              var5[(--par1)],
                            (par1--)
                          ],
                          for (int loc1 in {
                            for (int loc2 in [
                              ((!((Map.unmodifiable({
                                        86: var4,
                                        31: var0,
                                        85: (par3 + ''),
                                        91: (var1
                                            ? fld3_0[4]
                                            : '!M\u{1f600}!vOw'),
                                        45: '7T',
                                        19: 'fha+',
                                        38: (false ? '' : fld3_0[70])
                                      }) !=
                                      {
                                        92: '@4',
                                        41: var7[loc0],
                                        24: (foo3_0(0.06591134699771606)
                                            ? '\u2665)\u2665NnO+'
                                            : 'JM3Hn\u{1f600}'),
                                        26: 'aQ51Yz',
                                        64: var7[
                                            (-((var5[18] & (36).bitLength)))]
                                      })))
                                  ? (89 ^
                                      (((44 - par1) * -9223372034707292160) &
                                          var5[128]))
                                  : -46),
                              (fld3_2++),
                              ((([
                                            -89,
                                            var2,
                                            (fld3_2++),
                                            var5[-4294967264],
                                            -25,
                                            var2,
                                            var5[((!(var1))
                                                ? (var1 ? -3 : -81)
                                                : var5[loc0])],
                                            (var1
                                                ? par1
                                                : ((~((fld3_2++))) >>
                                                    (-((-(-64))))))
                                          ] ??
                                          foo2(var6, [
                                            4295032831
                                          ], {
                                            53: foo1_3(),
                                            94: var7[13],
                                            82: var7[-60],
                                            30: fld3_0[-9223372032559742976],
                                            98: foo1_3()
                                          })) !=
                                      var5)
                                  ? (--par1)
                                  : loc0),
                              56,
                              if (((var5[21]).isOdd ? true : false))
                                ((++par1) -
                                    (var1 ? var5[DateTime.january] : (par1--)))
                              else
                                fld3_2,
                              if ((!(var1))) 74,
                              (par1 ^ var5[26])
                            ])
                              (~(var2)),
                            for (int loc2 in {
                              6442450944,
                              Float32x4.ywyw,
                              -9223372032559804416,
                              (~(var5[var5[26]])),
                              Float32x4.xyxy,
                              (--fld3_2),
                              var5[98]
                            })
                              if (false) -26,
                            (~((-((-((-48 - -9223372036854775680))))))),
                            ...{
                              (-((var2--))),
                              if (true) -100663046 else var5[(~(par1))]
                            },
                            (~((~((fld3_2++))))),
                            ...{
                              ((List.filled(0, 26) ==
                                      [
                                        (-(-52)),
                                        -29,
                                        (--fld3_2),
                                        (0.22302566014161784).floor(),
                                        (par1 % -56)
                                      ])
                                  ? (var1
                                      ? (var2++)
                                      : ((!((!(true))))
                                          ? ((var1 || foo3_0(var3)) ? 76 : par1)
                                          : (-(-13))))
                                  : ((foo1_0((var1 ? fld3_0 : var7), var7,
                                              var3))
                                          .isEmpty
                                      ? 97
                                      : (var1 ? var2 : -9223372036854774784))),
                              (-(Float32x4.zyzw)),
                              (--var2)
                            }
                          })
                            ((var3 < (-(var3))) ? -9223372032559808000 : -71),
                          -100663046,
                          if ((var1
                              ? bool.fromEnvironment('vV0')
                              : (Map.from({
                                  78: '',
                                  49: '\u{1f600}\u{1f600}4Mz',
                                  70: fld3_0[par1],
                                  95: '\u{1f600}2tIYqE',
                                  43: (true ? 'baf-\u2665' : var4),
                                  30: var7[(-((-68 % ZLibOption.defaultLevel)))]
                                }))
                                  .isNotEmpty))
                            -13
                          else
                            (var1 ? (-((-(var5[56])))) : (var2--)),
                          (~((~((-((var2++)))))))
                        ], {
                          88: ('bV\u{1f600}iqO').toLowerCase(),
                          42: '(hZ4S',
                          37: var7[-79],
                          36: var0
                        })));
            }
          }
          {
            int loc0 = 0;
            do {
              try {
                print(foo2(
                    fld3_1,
                    (fld3_0[var5[-12]]).codeUnits,
                    (({
                              36: var4,
                              30: '0\u{1f600}EYWqr',
                              66: 'S',
                              3: '+J3Gj',
                              71: '\u{1f600}-q',
                              13: 'V3QN',
                              34: ''
                            } ??
                            {
                              54: fld3_0[(var2--)],
                              74: (foo3_0(
                                      ((-(var3)) * (0.8613045491468889 + var3)))
                                  ? var7[78]
                                  : (((var1 ? (47).isEven : var1) ? true : true)
                                      ? (var4 ?? 'UzK')
                                      : 'fH1smd')),
                              12: '\u2665',
                              18: 'V'
                            }) ??
                        var7)));
              } catch (exception, stackTrace) {
                fld3_1 = foo0();
                for (int loc1 = 0; loc1 < 29; loc1++) {
                  if (var1) {
                    {
                      int loc2 = 0;
                      do {
                        var5 = (foo3_0(var3)
                            ? [
                                ((--par1) ^ (~(93))),
                                if ((var3).isFinite)
                                  for (int loc3 in [
                                    -5,
                                    Int32x4.zxyy,
                                    (true
                                        ? var5[var5[(var1 ? -23 : var5[68])]]
                                        : -99),
                                    ((!(var1))
                                        ? ((false
                                                ? var1
                                                : foo3_0(0.3133865362301862))
                                            ? Float64List.bytesPerElement
                                            : [
                                                Float32x4.yxzx,
                                                if (var1)
                                                  (false ? 40 : 85)
                                                else
                                                  ((String.fromCharCode((foo3_0(
                                                                  0.414460580942719)
                                                              ? var5[-14]
                                                              : var2)) ==
                                                          'mII\u{1f600}zkM')
                                                      ? var5[(~(-51))]
                                                      : ((var1
                                                              ? (!(var1))
                                                              : var1)
                                                          ? var5[0]
                                                          : (-(var2))))
                                              ][5])
                                        : fld3_2),
                                    (par1++),
                                    -72,
                                    Int32x4.zzxy
                                  ])
                                    Int32x4.zyww
                                else
                                  Int32x4.wxyz
                              ]
                            : [
                                ...[
                                  if ((false ? false : var1)) (-(52)),
                                  (++par1),
                                  (par1--),
                                  (-((-([
                                    (((var0 + fld3_0[(++var2)])).isNotEmpty
                                        ? Float32x4.yzxw
                                        : var5[35])
                                  ][loc0])))),
                                  (~(-17))
                                ],
                                38,
                                ...[
                                  (var1 ? (par1++) : -10),
                                  if (true) -62 else var2,
                                  if ((!((var3).isFinite)))
                                    Int32x4.xxzz
                                  else
                                    -45
                                ],
                                if ((true || false)) (-(-93)),
                                (--fld3_2),
                                ([
                                      (fld3_2--),
                                      if ((base64UrlEncode(var5) == 'RY'))
                                        (++fld3_2)
                                      else
                                        -9223372032559808383,
                                      Float32x4.zyxy,
                                      loc0,
                                      -55,
                                      if (('O \u{1f600}e\u2665').isNotEmpty)
                                        if (var1)
                                          (--var2)
                                        else
                                          for (int loc3 in {
                                            loc0,
                                            (~((--var2))),
                                            (-(-35)),
                                            Float32x4.xxyw,
                                            65,
                                            -4,
                                            -4194304251,
                                            -54
                                          })
                                            (((0.671280258888436 ==
                                                        (0.16535430333243706 *
                                                            0.18316039550464436)) ||
                                                    var1)
                                                ? var5[12]
                                                : (~((--var2))))
                                      else if (false)
                                        if (var1) (-(Int32x4.zzwx)) else loc2
                                      else
                                        Int32x4.yzyw
                                    ][loc1] *
                                    (--par1)),
                                (-71 * 38)
                              ]);
                      } while (++loc2 < 89);
                    }
                  } else {
                    {
                      int loc2 = 0;
                      do {
                        fld3_0 ??= ((((Map.unmodifiable(var7)).isEmpty ||
                                    (!(({
                                      11: 'v+MHeiB',
                                      48: var7[(true
                                          ? ((var2--) ?? fld3_2)
                                          : var5[(fld3_2--)])],
                                      52: '(('
                                    })
                                        .isEmpty)))
                                ? fld3_0
                                : {
                                    39: foo1_3(),
                                    21: 'IXzJ+',
                                    76: 'K2C#',
                                    16: ('\u{1f600}Gh' + '#i'),
                                    62: foo1_3(),
                                    19: foo1_3(),
                                    32: par3,
                                    for (int loc3 in [
                                      (par1--),
                                      -66,
                                      -96,
                                      -35,
                                      Float32x4.zzyz
                                    ])
                                      72: 'y vxi'
                                  }) ??
                            {13: par2});
                        switch (4096) {
                          case 3159134388:
                            {
                              /// Single-line documentation comment.
                              {
                                int loc3 = 0;
                                do {
                                  fld3_0 ??= foo1(
                                      var5,
                                      ((((true ? par2 : var7[var5[loc1]]))
                                                  .isNotEmpty
                                              ? 9
                                              : -55) !=
                                          var5[-36]));
                                  fld3_1 = foo0();
                                } while (++loc3 < 79);
                              }
                            }
                            break;
                          case 3159134393:
                            {
                              throw Int32x4.zxxw;
                            }
                            break;
                        }
                      } while (++loc2 < 77);
                    }
                  }
                }
              }
            } while (++loc0 < 98);
          }
        }
        break;
    }
    /*
     * Multi-line
     * comment.
     */
    return ((0.7728524536008519).isNaN ? 'BjzeSsJ' : foo1_3());
  }

  void run() {
    super.run();
    var5 ??= var5;
    print({4294968296});
  }
}

main() {
  int count = 0;
  try {
    foo0();
  } catch (e, st) {
    count++;
  }
  try {
    foo1(('  MQz').codeUnits, var1);
  } catch (e, st) {
    count++;
  }
  try {
    foo2(
        (var6).toSet(),
        (var1
            ? [-9223372036854775681, -66, 9223372032559874047, -3, 74]
            : var5),
        Map.identity());
  } catch (e, st) {
    count++;
  }
  try {
    X0().foo0_0(var7);
  } catch (e, st) {
    count++;
  }
  try {
    X1().foo1_0(
        (false
            ? {
                7: 'QMNg',
                12: 'wzc5-Iq',
                63: '29an-z',
                86: 'sF5',
                59: '\u2665L',
                43: 'k',
                62: 'NvF\u{1f600}k',
                84: 'ZW 1-o'
              }
            : var7),
        {
          28: '@smXqKl',
          66: 'oL',
          if (false) 74: 'B' else 81: 'X',
          if (false) 18: 'j' else 25: 'N',
          44: '\u{1f600}lrx8m',
          20: 'hC',
          73: 'q',
          63: '\u{1f600}nE'
        },
        0.18875619647922648);
  } catch (e, st) {
    count++;
  }
  try {
    X1().foo1_1((-((++var2))));
  } catch (e, st) {
    count++;
  }
  try {
    X1().foo1_2((var1
        ? (false
            ? (true ? var7[((!(var1)) ? var5[Int32x4.xxyx] : 3)] : var4)
            : Uri.encodeComponent(('yd' ?? (var0).padLeft(1, 'Q'))))
        : var7[-2147483649]));
  } catch (e, st) {
    count++;
  }
  try {
    X1().foo1_3();
  } catch (e, st) {
    count++;
  }
  try {
    X2().foo2_0(Int32x4.xyyw);
  } catch (e, st) {
    count++;
  }
  try {
    X2().foo2_1((!(((!(var1)) && (!((var1 ? false : var1)))))));
  } catch (e, st) {
    count++;
  }
  try {
    X2().foo2_2(var7, ((-(var5[(--var2)])) << 98));
  } catch (e, st) {
    count++;
  }
  try {
    X3().foo3_0(0.37767598562234317);
  } catch (e, st) {
    count++;
  }
  try {
    X3().foo3_1(
        -6, var0, (Uri.decodeComponent('yQg') + ((var4 ?? var4) + var0)));
  } catch (e, st) {
    count++;
  }
  try {
    X3().foo1_0(
        Map.unmodifiable({77: 'hG'}),
        ((false
                ? {
                    88: 'Sv-EbnG',
                    73: 'G',
                    46: 'O#',
                    16: 'm1nf(',
                    91: 'F',
                    11: 'Q+O@K',
                    70: '3q\u2665BJ'
                  }
                : Map.identity()) ??
            {
              68: 'r',
              56: 'IH&',
              31: '9cqu',
              49: '8ug',
              84: 'mR2VyC',
              41: 'gk&(asy'
            }),
        (var3 * sin(var3)));
  } catch (e, st) {
    count++;
  }
  try {
    X3().run();
  } catch (e, st) {
    count++;
  } finally {}
  Expect.equals(-47639, var2);
  Expect.equals(9, count);
}
