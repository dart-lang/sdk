// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// This is a regression test for http://dartbug.com/40248.

import "package:expect/expect.dart";

class Base {
  set push(int x);
  set float(covariant int x);
  noSuchMethod(i) => print("${runtimeType}: ${i.positionalArguments[0]}");
}

class Me extends Base {}

class You extends Base {
  set push(num x);
  set float(num x);
}

main() {
  List<Base> list = [Me(), You()];
  for (Base baba in list) {
    baba.push = 0;
    baba.float = 1;
    if (baba is You) {
      baba.push = 2.3;
      baba.float = 4.5;
    }
    try {
      (baba as dynamic).push = 6.7;
      Expect.isTrue(baba is You);
    } on TypeError {
      Expect.isTrue(baba is Me);
    }
    try {
      (baba as dynamic).float = 8.9;
      Expect.isTrue(baba is You);
    } on TypeError {
      Expect.isTrue(baba is Me);
    }
  }
}
