// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// @dart = 2.9

import "dart:io";

import "package:async_helper/async_helper.dart";
import "package:expect/expect.dart";

const HOST_NAME = "localhost";
String localFile(path) => Platform.script.resolve(path).toFilePath();

SecurityContext serverContext = new SecurityContext()
  ..useCertificateChain(localFile('certificates/server_chain.pem'))
  ..usePrivateKey(localFile('certificates/server_key.pem'),
      password: 'dartdart')
  ..setTrustedCertificates(
    localFile('certificates/client_authority.pem'),
  )
  ..setClientAuthorities(
    localFile('certificates/client_authority.pem'),
  );

SecurityContext clientContext = new SecurityContext()
  ..setTrustedCertificates(localFile('certificates/trusted_certs.pem'))
  ..useCertificateChain(localFile('certificates/client1.pem'))
  ..usePrivateKey(localFile('certificates/client1_key.pem'),
      password: 'dartdart');

void main() {
  asyncStart();
  HttpServer.bindSecure(HOST_NAME, 0, serverContext,
          backlog: 5, requestClientCertificate: true)
      .then((server) {
    server.listen((HttpRequest request) {
      Expect.isNotNull(request.certificate);
      Expect.equals('/CN=user1', request.certificate.subject);
      request.response.write("Hello");
      request.response.close();
    });

    HttpClient client = new HttpClient(context: clientContext);
    client
        .getUrl(Uri.parse("https://$HOST_NAME:${server.port}/"))
        .then((request) => request.close())
        .then((response) {
      Expect.equals('/CN=localhost', response.certificate.subject);
      Expect.equals('/CN=intermediateauthority', response.certificate.issuer);
      return response.fold(<int>[], (message, data) => message..addAll(data));
    }).then((message) {
      String received = new String.fromCharCodes(message);
      Expect.equals(received, "Hello");
      client.close();
      server.close();
      asyncEnd();
    });
  });
}
