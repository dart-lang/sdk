// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import "package:expect/expect.dart";
import "package:async_helper/async_helper.dart";
import "dart:async";

void main() {
  StackTrace stack;
  try {
    throw 0;
  } catch (e, s) {
    stack = s;
  }
  var string = "$stack";
  StackTrace stringTrace = new StackTrace.fromString(string);
  Expect.isTrue(stringTrace is StackTrace);
  Expect.equals(stack.toString(), stringTrace.toString());

  string = "some random string, nothing like a StackTrace";
  stringTrace = new StackTrace.fromString(string);
  Expect.isTrue(stringTrace is StackTrace);
  Expect.equals(string, stringTrace.toString());

  // Use stacktrace asynchronously.
  asyncStart();
  var c = new Completer();
  c.completeError(0, stringTrace);
  c.future.then((v) {
    throw "Unexpected value: $v";
  }, onError: (e, s) {
    Expect.equals(string, s.toString());
  }).then((_) {
    var c = new StreamController();
    c.stream.listen((v) {
      throw "Unexpected value: $v";
    }, onError: (e, s) {
      Expect.equals(string, s.toString());
      asyncEnd();
    });
    c.addError(0, stringTrace);
    c.close();
  });
}
