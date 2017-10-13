// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import "dart:async";
import "package:expect/expect.dart";

main() async {
  var error = "no error";
  try {
    try {
      await new Future.error("error");
    } on MissingType catch (e) {} /*@compile-error=unspecified*/
  } catch (e) {
    error = e;
  }
  Expect.isTrue(error is TypeError);
}
