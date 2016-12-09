// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library isolate_errors;

import "dart:isolate";
import "dart:async";
import "package:async_helper/async_helper.dart";
import "package:expect/expect.dart";

isomain(arg) {
  if (arg is SendPort) {
    RawReceivePort wait = new RawReceivePort();
    wait.handler = (message) {
      wait.close();
      isomain(message);
    };
    arg.send(wait.sendPort);
  } else {
    throw new ArgumentError(arg);
  }
}

manyErrorsMain(int count) {
  for (int i = 0; i < count; i++) {
    Timer.run(() { throw "test#$i"; });
  }
}

main(){
  asyncStart();
  {
    asyncStart();
    Isolate.spawn(isomain, "test-1", paused: true).then((Isolate i) {
      var errors = [];
      i.errors.listen(null,
        onError: (e, s) {
          errors.add(e.toString().contains("test-1"));
        },
        onDone: () {
          Expect.listEquals([true], errors);
          asyncEnd();
        });
      i.resume(i.pauseCapability);
    });
  }

  {
    asyncStart();
    var messageReceived = new Completer();
    var p = new RawReceivePort()..handler = messageReceived.complete;
    Isolate.spawn(isomain, p.sendPort).then((i) {
      messageReceived.future.then((port) {
        p.close();
        // Isolate has started and is waiting for response.
        var errors = [];
        i.errors.listen(null,
          onError: (e, s) {
            errors.add(e.toString().contains("test-2"));
          },
          onDone: () {
            Expect.listEquals([true], errors);
            asyncEnd();
          });
        port.send("test-2");
      });
    });
  }

  // {
  //   asyncStart();
  //   Isolate.spawn(manyErrorsMain, 5,
  //                 paused: true, errorsAreFatal: false).then((i) {
  //     var errors = [];
  //     i.errors.listen(null,
  //       onError: (e, s) {
  //         print(e);
  //         errors.add(e.toString().contains("test#${errors.length}"));
  //       },
  //       onDone: () {
  //         print("done?");
  //         Expect.listEquals([true, true, true, true, true], errors);
  //         asyncEnd();
  //       });
  //     i.resume(i.pauseCapability);
  //   });
  // }

  asyncEnd();
}
