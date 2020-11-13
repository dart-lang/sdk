// Copyright (c) 2020, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// dart2jsOptions=--enable-asserts --disable-inlining --disable-type-inference --no-minify

import 'dart:async';
import 'package:expect/expect.dart';

// This test contains many different Rti instances that are initialized at
// startup.

typedef F1 = String Function(String, {int opt1});
typedef F2 = String Function(String, {required int req1, int opt1});

class Thingy {
  const Thingy();
}

class Generic<AA> {
  const Generic();
}

bool isObject(o) => o is Object;
bool isF1(o) => o is F1;
bool isF2(o) => o is F2;
bool isThingy(o) => o is Thingy;
bool isGenericF1(o) => o is Generic<F1>;
bool isGenericF2Q(o) => o is Generic<F2?>;
bool isG3(o) => o is FutureOr<AA> Function<AA>(AA);

String foo1(String s) => s;
String foo2(String s, {int opt1 = 0}) => '$s $opt1';
String foo3(String s, {int opt1 = 0, required int req1}) => '$s $req1 $opt1';
Never foo4() => throw 'never';

void test() {
  var items = [foo1, foo2, foo3, foo4, Thingy(), Generic<F1>()];

  void check(String answers, bool Function(dynamic) predicate) {
    Expect.equals(items.length, answers.length);
    for (int i = 0; i < items.length; i++) {
      var item = items[i];
      String code = answers[i];
      bool expected = code == 'T' ||
          (code == 'S' && hasSoundNullSafety) ||
          (code == 'W' && hasUnsoundNullSafety);
      Expect.equals(expected, predicate(item), "$predicate '$code' $item");
    }
  }

  // T = true, S = true only in strong mode, W = true only in weak mode.
  check('TTTTTT', isObject);
  check('.TW...', isF1);
  check('..T...', isF2);
  check('....T.', isThingy);
  check('.....T', isGenericF1);
  check('......', isGenericF2Q);
  check('......', isG3);
}

void main() {
  test();
  test();
}
