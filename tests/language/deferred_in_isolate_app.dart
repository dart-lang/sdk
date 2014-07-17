// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'deferred_in_isolate_lib.dart' deferred as test;

void main(args, msg) {
  assert(args != null);
  assert(args.length == 1);
  assert(msg != null);
  assert(msg.length == 1);

  var expectedMsg = args[0];
  var replyPort = msg[0];

  try {
    print("BeforeLibraryLoading");

    test.loadLibrary().then((_) {
      var obj = new test.DeferredObj(expectedMsg);
      replyPort.send(obj.toString());
    }).catchError((error) {
      replyPort.send("Error from isolate:\n$error");
    });
  } catch (exception, stacktrace) {
    replyPort.send("Exception from isolate:\n$exception\n$stacktrace");
  }
}
