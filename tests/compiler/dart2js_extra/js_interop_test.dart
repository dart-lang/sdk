// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import "package:js/js.dart";
import "package:expect/expect.dart";
import "dart:js" as js;

@JS('aFoo.bar')
external dynamic get jsBar;

main() {
  js.context.callMethod("eval", [
    """
  function Foo(){
    this.bar = 'Foo.bar';
  };
  aFoo = new Foo();
  """
  ]);

  Expect.equals('Foo.bar', jsBar);
}
