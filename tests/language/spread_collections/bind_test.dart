// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/// Check that spread collections can be used in combination with async/await features.
/// This is a regression test for http://dartbug.com/38896

import "package:async_helper/async_helper.dart";
import 'package:expect/expect.dart';

Future<void> asyncTest1(Future<void> f()) {
  asyncStart();
  return f().then(asyncSuccess);
}

void main() {
  asyncTest1(() async {
    await awaitSpreadMemberCallBindTest(); // A
    await yieldSpreadMemberCallBindTest(); // C
    await spreadAwaitMemberCallBindTest(); // G
    await spreadAwaitMemberAccessBindTest(); // I
  });
}

class A {
  List<int> m1() => [1, 2];
  Future<List<int?>> run() async {
    return [await null, ...m1()];
  }
}

Future<void> awaitSpreadMemberCallBindTest() async {
  // spread on member call in await
  Expect.listEquals([null, 1, 2], await A().run());
}

class C {
  List<int> m2() => [1, 2];

  Future<List<int>> run() async {
    return await run3().toList();
  }

  Stream<int> run3() async* {
    for (var k in [...await m2()]) yield k;
  }
}

Future<void> yieldSpreadMemberCallBindTest() async {
  var expected = [1, 2];

  // spread on await of member call with yield
  Expect.listEquals(expected, await C().run());
}

class G {
  List<int> m2() => [1, 2];

  Future<List<int>> run() async {
    return [...await m2()];
  }
}

Future<void> spreadAwaitMemberCallBindTest() async {
  var expected = [1, 2];

  // spread on await of member call
  Expect.listEquals(expected, await G().run());
}

class I1 {
  List<int> foo() => [1, 2];
}

class I {
  I1 b = I1();
  Future<List<int>> run() async {
    return [...await b.foo()];
  }
}

Future<void> spreadAwaitMemberAccessBindTest() async {
  var expected = [1, 2];

  // spread on await of member access
  Expect.listEquals(expected, await I().run());
}
