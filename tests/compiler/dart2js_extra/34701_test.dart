// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// dart2jsOptions=--omit-implicit-checks

/// Regression test for issue 34701.

import 'dart:async';
import 'package:expect/expect.dart';

class A {
  @pragma('dart2js:noInline') //# 01: ok
  Future<T> _foo<T>(FutureOr<T> Function() f) async {
    return await f();
  }

  @pragma('dart2js:noInline') //# 01: continued
  Future<String> get m async => _foo(() => "a");
}

class M {}

class B extends A with M {
  @pragma('dart2js:noInline') //# 01: continued
  Future<T> _foo<T>(FutureOr<T> Function() f) => super._foo(f);
}

main() async {
  var b = new B();
  print(b.m.runtimeType);
  print((await b.m).runtimeType);
  Expect.isTrue(b.m is Future<String>);
  Expect.isTrue((await b.m) is String);
}
