// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Note: the following comment is used by test.dart to additionally compile the
// other isolate's code.
// OtherScripts=issue_21398_child_isolate.dart

import 'dart:isolate';
import 'dart:async';
import "package:expect/expect.dart";
import 'package:async_helper/async_helper.dart';

class FromMainIsolate {
  String toString() => 'from main isolate';
  int get fld => 10;
}

funcChild(args) {
  var reply = args[1];
  var obj = args[0];
  Expect.isTrue(obj is FromMainIsolate);
  Expect.equals(10, obj.fld);
  reply.send(new FromMainIsolate());
}

main() {
  var receive1 = new ReceivePort();
  var receive2 = new ReceivePort();

  // First spawn an isolate using spawnURI and have it
  // send back a "non-literal" like object.
  asyncStart();
  Isolate.spawnUri(Uri.parse('issue_21398_child_isolate.dart'), [],
      [new FromMainIsolate(), receive1.sendPort]).catchError((error) {
    Expect.isTrue(error is ArgumentError);
    asyncEnd();
  });
  asyncStart();
  Isolate
      .spawnUri(
          Uri.parse('issue_21398_child_isolate.dart'), [], receive1.sendPort)
      .then((isolate) {
    receive1.listen((msg) {
      Expect.stringEquals(msg, "Invalid Argument(s).");
      receive1.close();
      asyncEnd();
    }, onError: (e) => print('$e'));
  });

  // Now spawn an isolate using spawnFunction and send it a "non-literal"
  // like object and also have the child isolate send back a "non-literal"
  // like object.
  asyncStart();
  Isolate.spawn(funcChild, [new FromMainIsolate(), receive2.sendPort]).then(
      (isolate) {
    receive2.listen((msg) {
      Expect.isTrue(msg is FromMainIsolate);
      Expect.equals(10, msg.fld);
      receive2.close();
      asyncEnd();
    }, onError: (e) => print('$e'));
  });
}
