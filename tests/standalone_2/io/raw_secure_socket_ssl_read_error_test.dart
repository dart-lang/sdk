// Copyright (c) 2022, the Dart project authors.  Please see the AUTHORS file
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
// OtherResources=certificates/untrusted_server_chain.pem
// OtherResources=certificates/untrusted_server_key.pem

// @dart = 2.9

import "dart:io";

import "package:async_helper/async_helper.dart";
import "package:expect/expect.dart";

InternetAddress HOST;
String localFile(path) => Platform.script.resolve(path).toFilePath();

SecurityContext serverContext = new SecurityContext()
  ..useCertificateChain(localFile('certificates/server_chain.pem'))
  ..usePrivateKey(localFile('certificates/server_key.pem'),
      password: 'dartdart');

SecurityContext clientContext = new SecurityContext()
  ..setTrustedCertificates(localFile('certificates/trusted_certs.pem'));

testSslReadError() async {
  // This test provokes an error in the BoringSSL `SSL_read` function by
  // sending unencrypted bytes through a secure connection.
  // See https://github.com/dart-lang/sdk/issues/48311
  final serverSocket = await RawServerSocket.bind(HOST, 0);
  serverSocket.forEach((socket) async {
    final secureSocket = await RawSecureSocket.secureServer(
        socket, serverContext,
        subscription: socket.listen((event) {}));
    secureSocket.write([1, 2, 3]);
    // Send content using the original unencrypted connection to provoke a
    // TtsException in the client.
    socket.write([1, 2, 3]);
    secureSocket.close();
    serverSocket.close();
  });

  final Socket clientSocket = await Socket.connect(HOST, serverSocket.port);
  final secureClientSocket =
      await SecureSocket.secure(clientSocket, context: clientContext);
  secureClientSocket.listen((data) {
    Expect.fail("expected TlsException");
  }, onError: (err) {
    Expect.isTrue(err is TlsException, "unexpected error: $err");
    secureClientSocket.close();
    clientSocket.close();
  });
}

main() {
  print("asyncStart main");
  asyncStart();
  InternetAddress.lookup("localhost").then((hosts) async {
    HOST = hosts.first;
    await testSslReadError();
    print("asyncEnd main");
    asyncEnd();
  });
}
