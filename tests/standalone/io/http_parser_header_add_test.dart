// Copyright (c) 2021, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
//
// Verify that FormatException is thrown when HttpClient userAgent has
// invalid value.

import "dart:async";
import "dart:io";
// ignore: IMPORT_INTERNAL_LIBRARY
import "dart:_http" show TestingClass$_HttpHeaders, TestingClass$_HttpParser;
import "package:async_helper/async_helper.dart";
import "package:expect/expect.dart";

typedef _HttpParser = TestingClass$_HttpParser;

Future<void> testFormatException() async {
  final server = await HttpServer.bind("127.0.0.1", 0);
  server.listen((HttpRequest request) {
    request.response.statusCode = 200;
    request.response.close();
  });

  // The ’ character is U+2019 RIGHT SINGLE QUOTATION MARK.
  final client = HttpClient()..userAgent = 'Bob’s browser';
  try {
    await asyncExpectThrows<FormatException>(
        client.open("CONNECT", "127.0.0.1", server.port, "/"));
  } finally {
    client.close(force: true);
    server.close();
  }
}

void testNullSubscriptionData() {
  _HttpParser httpParser = new _HttpParser.requestParser();
  httpParser.detachIncoming().listen((data) {}, onDone: () {});
}

main() {
  asyncTest(testFormatException);
  testNullSubscriptionData();
}
