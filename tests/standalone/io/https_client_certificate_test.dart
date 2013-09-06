// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import "dart:async";
import "dart:io";

import "package:async_helper/async_helper.dart";
import "package:expect/expect.dart";
import "package:path/path.dart";

const HOST_NAME = "localhost";


Function test() {
  asyncStart();
  HttpServer.bindSecure(HOST_NAME,
                        0,
                        backlog: 5,
                        certificateName: 'localhost_cert',
                        requestClientCertificate: true).then((server) {
    server.listen((HttpRequest request) {
      Expect.isNotNull(request.certificate);
      Expect.equals('CN=localhost', request.certificate.subject);
      request.response.write("Hello");
      request.response.close();
    });

    HttpClient client = new HttpClient();
    client.getUrl(Uri.parse("https://$HOST_NAME:${server.port}/"))
        .then((request) => request.close())
        .then((response) {
          Expect.equals('CN=localhost', response.certificate.subject);
          Expect.equals('CN=myauthority', response.certificate.issuer);
          return response.fold(<int>[],
                               (message, data) => message..addAll(data));
        })
        .then((message) {
          String received = new String.fromCharCodes(message);
          Expect.equals(received, "Hello");
          client.close();
          server.close();
          asyncEnd();
        });
  });
}

void InitializeSSL() {
  var testPkcertDatabase = join(dirname(Platform.script), 'pkcert');
  SecureSocket.initialize(database: testPkcertDatabase,
                          password: 'dartdart');
}

void main() {
  InitializeSSL();
  test();
}
