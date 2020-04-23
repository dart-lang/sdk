// Copyright (c) 2020, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import "dart:io";

import "package:async_helper/async_helper.dart";

// The ’ character is U+2019 RIGHT SINGLE QUOTATION MARK.
final value = 'Bob’s browser';

// When a invalid value is added to http header, test that a FormatException is
// thrown on an invalid user-agent header.
Future<void> main() async {
  final client = HttpClient();
  client.userAgent = value;

  asyncExpectThrows<FormatException>(() async {
    try {
      await client.getUrl(Uri.parse('https://postman-echo.com/get?'));
    } finally {
      client.close(force: true);
    }
  });
}
