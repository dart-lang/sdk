// Copyright (c) 2020, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

@JS()
library js_typed_interop_test;

import 'dart:html';

import 'package:js/js.dart';
import 'package:expect/minitest.dart';

_injectJs() {
  document.body!.append(new ScriptElement()
    ..type = 'text/javascript'
    ..innerHtml = r"""
  var Foo = {
    get42: function(b) { return arguments.length >= 1 ? b : 42; }
  };
""");
}

@JS()
class Foo {
  external static num get42([num? b = 3
      // TODO(41375): This should be a static error. It's invalid to have a
      // default value.
      ]);
}

main() {
  _injectJs();

  test('call tearoff from dart with default', () {
    var f = Foo.get42;
    // Note: today both SSA and CPS remove the extra argument on static calls,
    // but they fail to do so on tearoffs.
    expect(f(), 3);
    // TODO(41375): Remove this once the above is resolved. This is temporary
    // to track this test failure.
    throw ("This test should not execute. It should fail to compile above.");
  });
}
