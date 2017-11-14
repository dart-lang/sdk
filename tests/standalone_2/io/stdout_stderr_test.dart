// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import "package:expect/expect.dart";
import "dart:async";
import "dart:convert";
import "dart:io";

callIOSink(IOSink sink) {
  // Call all methods on IOSink.
  sink.encoding = ascii;
  Expect.equals(ascii, sink.encoding);
  sink.write("Hello\n");
  sink.writeln("Hello");
  sink.writeAll(["H", "e", "l", "lo\n"]);
  sink.writeCharCode(72);
  sink.add([101, 108, 108, 111, 10]);

  var controller = new StreamController(sync: true);
  var future = sink.addStream(controller.stream);
  controller.add([72, 101, 108]);
  controller.add([108, 111, 10]);
  controller.close();

  future.then((_) {
    controller = new StreamController(sync: true);
    controller.stream.pipe(sink);
    controller.add([72, 101, 108]);
    controller.add([108, 111, 10]);
    controller.close();
  });
}

main() {
  callIOSink(stdout);
  stdout.done.then((_) {
    callIOSink(stderr);
    stderr.done.then((_) {
      stdout.close();
      stderr.close();
    });
  });
}
