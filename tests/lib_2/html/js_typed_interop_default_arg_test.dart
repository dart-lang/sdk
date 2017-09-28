// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

@JS()
library js_typed_interop_test;

import 'dart:html';

import 'package:js/js.dart';
import 'package:expect/minitest.dart';

_injectJs() {
  document.body.append(new ScriptElement()
    ..type = 'text/javascript'
    ..innerHtml = r"""
  var Foo = {
    get42: function(b) { return arguments.length >= 1 ? b : 42; },
    get43: function(b) { return arguments.length >= 1 ? b : 43; }
  };
""");
}

@JS()
class Foo {
  // Note: it's invalid to provide a default value.
  external static num get42([num b
      = 3 // //# default_value: compile-time error
      ]);
  external static num get43([num b]);
}

main() {
  _injectJs();

  test('call directly from dart', () {
    expect(Foo.get42(2), 2);
    expect(Foo.get42(), 42);
  });

  test('call tearoff from dart with arg', () {
    var f = Foo.get42;
    expect(f(2), 2); //# explicit_argument: ok
  });

  test('call tearoff from dart with default', () {
    var f = Foo.get42;
    // Note: today both SSA and CPS remove the extra argument on static calls,
    // but they fail to do so on tearoffs.
    expect(f(), 3); //# default_value: continued

    f = Foo.get43;
    expect(f(), 43);
  });
}
