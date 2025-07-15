// Copyright (c) 2025, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// https://github.com/flutter/flutter/issues/170723

import "dart:io";

test(int i) async {
  try {
    var socket = await RawSecureSocket.connect("www.google.com", 443);
    await Future.delayed(
      Duration(seconds: 6), // More than the thread pool timeout.
    );
    socket.close();
  } catch (e, st) {
    // Ignore failures from the remote side rejecting/closing the connection.
    if (!e.toString().contains("Connection reset by peer")) {
      rethrow;
    }
  }
}

main() async {
  var tests = <Future>[];
  for (var i = 0; i < 2000; i++) {
    tests.add(test(i));
  }
  await Future.wait(tests);
}
