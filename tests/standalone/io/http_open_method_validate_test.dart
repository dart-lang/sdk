// Copyright (c) 2022, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
//
// Verify that HttpClient open, openUrl method argument is validated.

import "dart:io";
import "package:expect/expect.dart";

void testInvalidArgumentException(String method) {
  Expect.throws(() => HttpClient()..open(method, "127.0.0.1", 8080, "/"),
      (e) => e is ArgumentError);
  Expect.throws(
      () => HttpClient()..openUrl(method, Uri.parse("http://127.0.0.1/")),
      (e) => e is ArgumentError);
}

main() {
  const String separators = "\t\n\r()<>@,;:\\/[]?={}";
  for (int i = 0; i < separators.length; i++) {
    String separator = separators.substring(i, i + 1);
    testInvalidArgumentException(separator);
    testInvalidArgumentException(separator + "CONNECT");
    testInvalidArgumentException("CONN" + separator + "ECT");
    testInvalidArgumentException("CONN" + separator + separator + "ECT");
    testInvalidArgumentException("CONNECT" + separator);
  }
}
