// Copyright (c) 2020, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// VMOptions=--old_gen_heap_size=20

import "dart:io";
import "dart:isolate";

import "package:expect/expect.dart";

handleRequest(request) {
  if (request % 2 == 0) {
    var leak = [];
    while (true) {
      leak = [leak];
    }
  }
  return "Okay";
}

handleMessage(message) {
  print(">> $message");
  var responsePort = message[0];
  var request = message[1];
  try {
    responsePort.send(<dynamic>[request, handleRequest(request)]);
  } catch (e, st) {
    responsePort.send(<dynamic>[request, "Failed: $e\n$st"]);
  }
}

main(args) async {
  var child = new RawReceivePort(handleMessage);

  var parent;
  parent = new RawReceivePort((message) {
    print("<< $message");
    var request = message[0];
    var response = message[1];
    if (request % 2 == 0) {
      Expect.isTrue(response.contains("Out of Memory"));
    } else {
      Expect.equals("Okay", response);
    }
    if (request == 5) {
      child.close();
      parent.close();
    } else {
      child.sendPort.send(<dynamic>[parent.sendPort, request + 1]);
    }
  });

  child.sendPort.send(<dynamic>[parent.sendPort, 1]);
}
