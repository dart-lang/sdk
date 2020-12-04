// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// VMOptions=--long-ssl-cert-evaluation

// This test verifies that dart isolate is not getting blocked during
// certificate evaluation.

import 'dart:async';
import 'dart:io';

import "package:expect/expect.dart";
import "package:async_helper/async_helper.dart";

void log(String s) {
  print(s);
}

Timer stallDetector() {
  final sw = Stopwatch()..start();
  return Timer.periodic(Duration(milliseconds: 5), (_) {
    int elapsedMs = sw.elapsedMilliseconds;
    // Would the evaluation be synchronous, the dart isolate is going to
    // be blocked for over a second.
    Expect.isTrue(elapsedMs < 1000);
    if (sw.elapsedMilliseconds > 10) {
      log('EVENT LOOP WAS STALLED FOR ${sw.elapsedMilliseconds} ms');
    }
    sw.reset();
  });
}

void main() async {
  asyncStart();
  final url = 'https://google.com';
  final timer = stallDetector();
  var sw = Stopwatch()..start();
  var httpClient = HttpClient();
  try {
    var request = await httpClient.getUrl(Uri.parse(url));
    var response = await request.close();
    int elapsedMs = sw.elapsedMilliseconds;
    log('REQUEST COMPLETE IN $elapsedMs ms');
    // Request have to take at least a second due to
    // vm "--long-ssl-cert-evaluation" option.
    Expect.isTrue(elapsedMs > 1000);

    asyncEnd();
  } finally {
    httpClient.close(force: true);
    timer.cancel();
  }
}
