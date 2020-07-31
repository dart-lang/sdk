// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// VMOptions=--optimization_counter_threshold=1

import "package:expect/expect.dart";

import 'dart:typed_data';

// Found by DartFuzzing: would sometimes crash on OSR
// https://github.com/dart-lang/sdk/issues/38231

import 'dart:async';
import 'dart:cli';
import 'dart:collection';
import 'dart:convert';
import 'dart:core';
import 'dart:io';
import 'dart:isolate';
import 'dart:math';
import 'dart:typed_data';

Map<int, String> var0 = {
  41: 'V\u2665Y\u2665#Xs',
  for (int loc0 in {
    if (true) for (int loc0 in {-2147483649}) -4294967167 else if (false) -1,
    -60,
    -82,
    -21,
    for (int loc0 in [
      -9223372036854771712,
      for (int loc0 = 0; loc0 < 53; loc0++) 96
    ])
      1,
    -58,
    77
  })
    95: '',
  5: 'z2\u2665e',
  if (false) for (int loc0 in [-87, -2147483649, 0, 97, -53, 95]) 10: '#synP3',
  22: ''
};
String var1 = ')LIpwG';
double var2 = 0.30016980633333135;
bool var3 = true;
bool var4 = true;
int var5 = -9223372036854774808;
double var6 = 0.7012235530406754;
String var7 = 'H';
List<int> var8 = [90, -50, -34, -97, -33, 1];
Set<int> var9 = {
  42,
  36,
  9223372034707292159,
  ...{52},
  97,
  for (int loc0 in {
    if (true) ...{13} else -54,
    -26,
    -38,
    9223372032559808513,
    60
  })
    for (int loc1 in {
      for (int loc1 in {19, 60}) -4294967280,
      -17,
      -62
    }) ...{23, 11},
  for (int loc0 = 0; loc0 < 30; loc0++) -44
};
Map<int, String> var10 = {
  for (int loc0 in {
    ...{
      -52,
      -9223372030412324864,
      if (true) 82,
      ...{76, 5, 9223372032559841279, 98, 58, 97, -127, 72},
      for (int loc0 in [-97]) -14,
      for (int loc0 = 0; loc0 < 21; loc0++) 88
    },
    -52,
    for (int loc0 = 0; loc0 < 63; loc0++) ...{64, 0},
    for (int loc0 = 0; loc0 < 67; loc0++) ...{67}
  })
    54: '',
  41: 'cvokV0',
  4: '9\u2665',
  35: 'vRkv',
  41: '\u2665',
  63: 'Nu+u\u26659S'
};

class X0 {}

class X1 with X0 {
  bool foo1_0(List<int> par1, bool par2) => true;
  Map<int, String> foo1_1(Set<int> par1, bool par2, Set<int> par3) {
    return {1: "a", 2: "b"};
  }
}

main() {
  try {
    X1().foo1_0([1, 2], true);
  } catch (exception, stackTrace) {
    print('X1().foo1_0() throws');
  }
  try {
    X1().foo1_1(
        {
          32,
          -94,
          -2147483649,
          -43,
          for (int loc0 in {56, -31}) -9223372032559775745,
          53,
          86,
          4294967296
        },
        var4,
        {1, 2});
  } catch (exception, stackTrace) {
    print('X1().foo1_1() throws');
  }
}
