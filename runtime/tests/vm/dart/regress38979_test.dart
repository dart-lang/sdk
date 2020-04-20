// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Verifies that compiler doesn't crash on a particular piece of code.

import "package:expect/expect.dart";
import 'dart:typed_data';

Int8List var3 = Int8List(1);
bool var14 = true;
Duration var15 = Duration();
int var16 = 22;
String var18 = '';
Map<bool, bool> var25 = {};
Map<bool, int> var26 = {};
Map<int, String> var30 = {};
Map<String, bool> var31 = {};

int foo1(Int8List par1, Map<bool, int> par2) {
  throw 'err';
}

class X0 {
  Int32x4 foo0_0(Duration par1, Set<bool> par2) {
    if (var14) {
      {
        int loc0 = 0;
        do {
          var31 = {
            (String.fromCharCode(((true ? true : true)
                    ? (var14 ? 33 : var16)
                    : (-(foo1(var3,
                        {(false ? false : var14): (true ? 20 : var3[27])})))))):
                ((((var16 > (-((-(loc0))))) ? Duration() : Duration()) +
                        (var14 ? (true ? var15 : par1) : Duration())) <
                    Duration()),
            (((var30[(Int32x4.yzxw as int)]).toUpperCase()) +
                (Uri.encodeComponent(('2' ??
                    (var25[true]
                        ? (String.fromEnvironment(''))
                        : var18))))): (!(var14)),
            (var31['MgOdzM']
                    ? var30[15]
                    : (('D9q6Ma').substring(
                        (~((--var16))), foo1(var3, (false ? {} : var26))))):
                (!(false)),
          };
        } while (++loc0 < 39);
      }
    }
  }
}

main() {
  Expect.throws(() => X0().foo0_0(Duration(), {true, false}),
      (e) => e is NoSuchMethodError);
}
