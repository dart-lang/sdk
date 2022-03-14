// Copyright (c) 2021, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
//
// VMOptions=
// VMOptions=--short_socket_read
// VMOptions=--short_socket_write
// VMOptions=--short_socket_read --short_socket_write
// OtherResources=certificates/server_chain.pem
// OtherResources=certificates/server_key.pem
// OtherResources=certificates/trusted_certs.pem

import "dart:async";
import "dart:io";

import "package:async_helper/async_helper.dart";
import "package:expect/expect.dart";

late InternetAddress HOST;

String localFile(path) => Platform.script.resolve(path).toFilePath();

SecurityContext serverContext = new SecurityContext()
  ..useCertificateChain(localFile('certificates/server_chain.pem'))
  ..usePrivateKey(localFile('certificates/server_key.pem'),
      password: 'dartdart');

Future<HttpServer> startEchoServer() {
  return HttpServer.bindSecure(HOST, 0, serverContext).then((server) {
    server.listen((HttpRequest req) {
      final res = req.response;
      res.write("Test");
      res.close();
    });
    return server;
  });
}

testSuccess(HttpServer server) async {
  var log = "";
  SecurityContext clientContext = new SecurityContext()
    ..setTrustedCertificates(localFile('certificates/trusted_certs.pem'));

  final client = HttpClient(context: clientContext);
  client.keyLog = (String line) {
    log += line;
  };
  final request =
      await client.getUrl(Uri.parse('https://localhost:${server.port}/test'));
  final response = await request.close();
  await response.drain();

  Expect.contains("CLIENT_HANDSHAKE_TRAFFIC_SECRET", log);
}

testExceptionInKeyLogFunction(HttpServer server) async {
  SecurityContext clientContext = new SecurityContext()
    ..setTrustedCertificates(localFile('certificates/trusted_certs.pem'));

  final client = HttpClient(context: clientContext);
  var numCalls = 0;
  client.keyLog = (String line) {
    ++numCalls;
    throw FileSystemException("Something bad happened");
  };
  final request =
      await client.getUrl(Uri.parse('https://localhost:${server.port}/test'));
  final response = await request.close();
  await response.drain();

  Expect.notEquals(0, numCalls);
}

void main() async {
  asyncStart();
  await InternetAddress.lookup("localhost").then((hosts) => HOST = hosts.first);
  final server = await startEchoServer();

  await testSuccess(server);
  await testExceptionInKeyLogFunction(server);

  await server.close();
  asyncEnd();
}
