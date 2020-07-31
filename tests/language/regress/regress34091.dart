// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Tests that stack traces from data URIs don't contain the entire URI, and
// instead just have the substitute file name: <data:application/dart>

import "dart:isolate";
import "package:expect/expect.dart";
import 'dart:async';

void main() {
  // This data URI encodes:
  /*
    import "dart:isolate";
    void main(_, p){
      try {
        throw("Hello World");
      } catch (e, s) {
        p.send("$e\n$s");
      }
    }
  */
  final uri = Uri.parse(
      "data:application/dart;charset=utf8,import%20%22dart%3Aisolate%22%3Bvoi" +
          "d%20main(_%2Cp)%7Btry%7Bthrow(%22Hello%20World%22)%3B%7Dcatch(e%2C" +
          "%20s)%7Bp.send(%22%24e%5Cn%24s%22)%3B%7D%7D");
  ReceivePort port = new ReceivePort();
  Isolate.spawnUri(uri, [], port.sendPort);
  port.listen((trace) {
    // Test that the trace contains the exception message.
    Expect.isTrue(trace.contains("Hello World"));

    // Test that the trace contains data URI substitute.
    Expect.isTrue(trace.contains("<data:application/dart>"));

    // Test that the trace doesn't contain any leftover URL encoded junk.
    Expect.isFalse(trace.contains("%20"));

    port.close();
  });
}
