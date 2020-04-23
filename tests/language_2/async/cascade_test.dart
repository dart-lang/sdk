// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';

import 'package:expect/expect.dart';

// Note, this is a regression test for:
// https://github.com/dart-lang/sdk/issues/29252
class Foo {
  Future _x;
  int z;
  List list = [];

  Future foo() async {
    _x ??= new Future(() async {
      z = await new Future.value(42);
      list = list.toList()..add(z);
    });
    await _x;
    return list[0];
  }
}

main() async {
  var f = new Foo();
  var result = await f.foo();
  Expect.equals(42, result);
}
