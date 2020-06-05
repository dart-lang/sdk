// Copyright (c) 2020, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Tests positional and optional arguments for various JS objects.

@JS()
library js_parameters_test;

import 'package:js/js.dart';
import 'package:expect/expect.dart';

@JS()
external void eval(String code);

@JS()
class Foo {
  external factory Foo();
  external singleArg(a);
  external singlePositionalArg([dynamic a]);
  external mixedPositionalArgs(a, [dynamic b]);
}

@JS()
class Bar {
  external static singleArg(a);
  external static singlePositionalArg([dynamic a]);
  external static mixedPositionalArgs(a, [dynamic b]);
}

external singleArg(a);
external singlePositionalArg([dynamic a]);
external mixedPositionalArgs(a, [dynamic b]);

main() {
  eval(r"""
    function Foo() {}
    Foo.prototype.singleArg = function(a) {
      return a;
    }
    Foo.prototype.singlePositionalArg = singleArg;
    Foo.prototype.mixedPositionalArgs = function(a, b) {
      if (arguments.length == 0) return a;
      return arguments[arguments.length - 1];
    }

    var Bar = {
      singleArg: function(a) {
        return a;
      },
      singlePositionalArg: singleArg,
      mixedPositionalArgs: function(a, b) {
        if (arguments.length == 0) return a;
        return arguments[arguments.length - 1];
      },
    };

    function singleArg(a) {
      return a;
    }
    var singlePositionalArg = singleArg;
    function mixedPositionalArgs(a, b) {
      if (arguments.length == 0) return a;
      return arguments[arguments.length - 1];
    }
  """);

  var foo = Foo();
  Expect.equals(foo.singleArg(2), 2);
  Expect.equals(foo.singlePositionalArg(2), 2);
  Expect.equals(foo.singlePositionalArg(), null);
  Expect.equals(foo.mixedPositionalArgs(3), 3);
  Expect.equals(foo.mixedPositionalArgs(3, 4), 4);

  Expect.equals(Bar.singleArg(2), 2);
  Expect.equals(Bar.singlePositionalArg(2), 2);
  Expect.equals(Bar.singlePositionalArg(), null);
  Expect.equals(Bar.mixedPositionalArgs(3), 3);
  Expect.equals(Bar.mixedPositionalArgs(3, 4), 4);

  Expect.equals(singleArg(2), 2);
  Expect.equals(singlePositionalArg(2), 2);
  Expect.equals(singlePositionalArg(), null);
  Expect.equals(mixedPositionalArgs(3), 3);
  Expect.equals(mixedPositionalArgs(3, 4), 4);
}
