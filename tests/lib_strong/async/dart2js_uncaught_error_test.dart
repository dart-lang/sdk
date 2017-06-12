// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import "dart:async";
import "dart:js";
import "dart:collection" show Queue;
import "package:expect/expect.dart";
import "package:async_helper/async_helper.dart";

var errors = new Queue();
int ctr = 0;

main() {
  print("STARTED");
  asyncStart();

  void errorHandler(self, message, url, line, [column, error]) {
    print(">> $message / $ctr");
    var expect = errors.removeFirst();
    if (ctr == 2) {
      asyncEnd();
      print("DONE");
    }
    Expect.equals(expect[0].toString(), message);
    Expect.equals(expect[1].toString(), error["stack"].toString());
  }

  context["onerror"] = new JsFunction.withThis(errorHandler);

  void throwit() {
    var err = ++ctr;
    try {
      throw err;
    } catch (e, s) {
      errors.add([e, s]);
      rethrow;
    }
  }

  () async {
    () async {
      throwit();
    }();
    throwit();
  }();
}
