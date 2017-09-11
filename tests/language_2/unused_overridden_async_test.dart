// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
import 'dart:async';

class Base {
  Future<int> method() async {
    throw 'Should be unused';
  }
}

class Sub1 extends Base {
  Future<int> method() async {
    return 1;
  }
}

class Sub2 extends Base {
  Future<int> method() async {
    return 2;
  }
}

help(Base object) async {
  print(await object.method());
}

main() async {
  await help(new Sub1());
  await help(new Sub2());
}
