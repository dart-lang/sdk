// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/// Test that optional arguments of js-interop constructors are not passed
/// explicitly when missing.
///
/// This is a regression test for issue 32697

import "package:js/js.dart";
import "package:expect/expect.dart";
import "dart:js" as js;

@JS('C')
class C {
  external C([a]);
  external bool get isUndefined;
}

main() {
  js.context.callMethod("eval", [
    """
  function C(a){
    this.isUndefined = a === undefined;
  };
  """
  ]);

  Expect.isTrue(new C().isUndefined);
}
