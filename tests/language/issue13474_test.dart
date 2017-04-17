// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
// VMOptions=--enable_type_checks

import "package:expect/expect.dart";

main() {
  var a;
  Expect.throws(() {
    true && (a = 5);
  }, (error) => error is TypeError);
  Expect.throws(() {
    (a = 5) && true;
  }, (error) => error is TypeError);
  Expect.throws(() {
    false || (a = 5);
  }, (error) => error is TypeError);
  Expect.throws(() {
    (a = 5) || false;
  }, (error) => error is TypeError);
  Expect.throws(() {
    (a = 5) || true;
  }, (error) => error is TypeError);

  // No exceptions thrown.
  false && (a = 5);
  true || (a = 5);
}
