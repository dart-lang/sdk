// Copyright (c) 2020, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import "dart:io";

import 'package:expect/expect.dart';

// Test that a HTTP "CONNECT" request with 200 status code won't close the
// underlying socket.
// issue: https://github.com/dart-lang/sdk/issues/37808
Future<void> testConnect(int statusCode, int port) async {
  final url = "https://domain.invalid";
  var client = HttpClient();
  try {
    client.findProxy = (uri) => "PROXY 127.0.0.1:$port";
    try {
      final request = await client.getUrl(Uri.parse(url));
      await request.close();
      Expect.fail('request should have thrown an exception');
    } catch (e) {
      if (statusCode == HttpStatus.ok) {
        // Underlying sockets won't be closed and then handshake will fail.
        Expect.type<HandshakeException>(e);
      } else {
        Expect.type<HttpException>(e);
      }
    }
  } finally {
    client.close();
  }
}

Future<void> main() async {
  final server = await HttpServer.bind('127.0.0.1', 0);
  try {
    final statusCodes = <int>[200, 299, 199, 300];
    int index = 0;
    server.listen((request) {
      request.response.statusCode = statusCodes[index++];
      request.response.headers.contentLength = 0;
      request.response.close();
    });
    for (final statusCode in statusCodes) {
      await testConnect(statusCode, server.port);
    }
  } finally {
    server.close();
  }
}
