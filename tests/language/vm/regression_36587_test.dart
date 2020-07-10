// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Regression test extracted from a large DartFuzz-generated test.
// https://github.com/dart-lang/sdk/issues/36587

import "package:expect/expect.dart";

import 'dart:async';
import 'dart:cli';
import 'dart:collection';
import 'dart:convert';
import 'dart:core';
import 'dart:io';
import 'dart:isolate';
import 'dart:math';
import 'dart:typed_data';

Set<int> var0 = {-62, -13, 2147483648, -10, -9223372028264841217, -54, 47};
Set<int>? var1 = {-59};
bool var2 = false;
bool var3 = true;
int var4 = 58;
double? var5 = 0.004032426761438224;
String var6 = 'u6X2';
List<int> var7 = [56, -95, 6442450944, -31, 82];
Set<int>? var8 = {9223372036854775807, 4294967297};
Map<int, String> var9 = {
  6: 'Ei(ZR',
  75: 'O0A-',
  99: 't',
  49: 'Qu',
  20: 'FujA\u2665',
  47: ''
};

String? foo2() {
  var8 ??= Set.identity();
  switch ((--var4)) {
    case 3826530052:
      {
        {
          int loc0 = 0;
          do {
            try {
              throw {64: var6};
            } catch (e) {
              if ((!(var3))) {
                break;
              } else {
                try {
                  var8 = ((false ? FileSystemEntity.isWatchSupported : var3)
                      ? {Int32x4.wxxx, var4, -43, Float32x4.wzxz}
                      : {
                          (var4++),
                          (var7[(false ? -87 : (++loc0))] %
                              (var7[((++loc0) * var4)] ~/ 73))
                        });
                  var0 = ((((-((((true ? var2 : false) ? (!(var3)) : true)
                                  ? var5
                                  : ((0.38834735336907733 as dynamic) ??
                                      0.8105736840461367)))) +
                              (0.3752597438445757).abs()))
                          .isFinite
                      ? {
                          (true ? 65 : (var3 ? (loc0--) : var4)),
                          var7[Float32x4.xxxx]
                        }
                      : Set.identity());
                  var1 = (((true
                          ? ({var7[var7[-9223372032559808513]]}).toSet()
                          : (Set.identity()).difference(var8!)) as dynamic) ??
                      var8);
                  var9[Float32x4.zxyz] = '';
                } catch (e) {
                  loc0 ~/= ((var3 != var3)
                      ? (~((false ? (-(loc0)) : Int32x4.wzwx)))
                      : var4);
                } finally {
                  var1 = var8;
                  var5 ??= 0.6273822429057158;
                  throw [
                    (loc0++),
                    2147483647,
                    (var4--),
                    (-(ZLibOption.defaultWindowBits)),
                    (~((loc0--))),
                    (var4++)
                  ];
                }
              }
              break;
            }
          } while (++loc0 < 74);
        }
      }
  }
}

main() {
  Expect.equals(58, var4);
  foo2();
  Expect.equals(57, var4);
}
