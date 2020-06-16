// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/// Test that optional arguments of js-interop factory constructors are not
/// elided.
/// This is a regression test for issue 35916
@JS()
library test;

import "package:js/js.dart";
import "package:expect/expect.dart";

@JS()
@anonymous
class Margins {
  external factory Margins(
      {int top, int start, int end, int right, int bottom, int left});
  external int get top;
  external int get right;
  external int get left;
  external int get bottom;
}

main() {
  var m = new Margins(bottom: 21, left: 88, right: 20, top: 24);
  Expect.equals(m.top, 24);
  Expect.equals(m.bottom, 21);
  Expect.equals(m.left, 88);
  Expect.equals(m.right, 20);
}
