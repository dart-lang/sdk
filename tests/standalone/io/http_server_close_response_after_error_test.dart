// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
//
// VMOptions=
// VMOptions=--short_socket_read
// VMOptions=--short_socket_write
// VMOptions=--short_socket_read --short_socket_write
// OtherResources=http_server_close_response_after_error_client.dart

import 'dart:async';
import 'dart:io';

const CLIENT_SCRIPT = "http_server_close_response_after_error_client.dart";

void main() {
  HttpServer.bind("127.0.0.1", 0).then((server) {
    server.listen((request) {
      request.listen(null, onError: (e) {}, onDone: () {
        request.response.close();
      });
    });
    Process.run(Platform.executable, [
      Platform.script.resolve(CLIENT_SCRIPT).toString(),
      server.port.toString()
    ]).then((result) {
      if (result.exitCode != 0) throw "Bad exit code";
      server.close();
    });
  });
}
