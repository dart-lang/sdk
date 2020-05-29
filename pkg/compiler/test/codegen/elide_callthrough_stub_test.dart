// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// @dart = 2.7

// Check that calls through fields elide the call-through stub.  This
// optimization is done by the simplifier, so inlining does not need to be
// enabled.

import 'package:async_helper/async_helper.dart';
import 'package:expect/expect.dart';
import '../helpers/compiler_helper.dart';

const String TEST1 = r'''
class W {
  final Function _fun;
  W(this._fun);
  foo(zzz) => _fun(zzz); //   this._fun$1(zzz) -->  this._fun.call$1(zzz)
}
add1(x) => x + 1;
main() {
  var w = new W(add1);
  var x = w.foo(42);
}
''';

const String TEST2 = r'''
class W {
  final Function __fun;
  Function get _fun => __fun;
  W(this.__fun);
  foo(zzz) => _fun(zzz); //   this._fun$1(zzz) stays same.
}
add1(x) => x + 1;
main() {
  var w = new W(add1);
  var x = w.foo(42);
}
''';

main() {
  runTests() async {
    String generated1 = await compileAll(TEST1);
    // Direct call through field.
    Expect.isTrue(generated1.contains(r'this._fun.call$1(zzz)'));
    // No stub.
    Expect.isFalse(generated1.contains(r'_fun$1:'));
    // No call to stub.
    Expect.isFalse(generated1.contains(r'_fun$1('));

    String generated2 = await compileAll(TEST2);
    // No call through field.
    Expect.isFalse(generated2.contains(r'this._fun.call$1(zzz)'));
    // Call through stub.
    Expect.isTrue(generated2.contains(r'this._fun$1(zzz)'));
    // Stub is generated.
    Expect.isTrue(generated2.contains(r'_fun$1:'));
    // Call through getter (inside stub).
    Expect.isTrue(generated2.contains(r'get$_fun().call$1'));
  }

  asyncTest(() async {
    print('--test from kernel------------------------------------------------');
    await runTests();
  });
}
