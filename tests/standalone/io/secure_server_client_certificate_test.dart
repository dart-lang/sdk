// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import "dart:async";
import "dart:io";

import "package:async_helper/async_helper.dart";
import "package:expect/expect.dart";

InternetAddress HOST;

String localFile(path) => Platform.script.resolve(path).toFilePath();

SecurityContext serverContext = new SecurityContext()
  ..useCertificateChain(localFile('certificates/server_chain.pem'))
  ..usePrivateKey(localFile('certificates/server_key.pem'),
      password: 'dartdart')
  ..setTrustedCertificates(file: localFile('certificates/client_authority.pem'))
  ..setClientAuthorities(localFile('certificates/client_authority.pem'));

SecurityContext clientCertContext = new SecurityContext()
  ..setTrustedCertificates(file: localFile('certificates/trusted_certs.pem'))
  ..useCertificateChain(localFile('certificates/client1.pem'))
  ..usePrivateKey(localFile('certificates/client1_key.pem'),
      password: 'dartdart');

SecurityContext clientNoCertContext = new SecurityContext()
  ..setTrustedCertificates(file: localFile('certificates/trusted_certs.pem'));

Future testClientCertificate({bool required, bool sendCert}) async {
  var server = await SecureServerSocket.bind(HOST, 0, serverContext,
      requestClientCertificate: true, requireClientCertificate: required);
  var clientContext = sendCert ? clientCertContext : clientNoCertContext;
  var clientEndFuture =
      SecureSocket.connect(HOST, server.port, context: clientContext);
  if (required && !sendCert) {
    try {
      await server.first;
    } catch (e) {
      try {
        await clientEndFuture;
      } catch (e) {
        return;
      }
    }
    Expect.fail("Connection succeeded with no required client certificate");
  }
  var serverEnd = await server.first;
  var clientEnd = await clientEndFuture;

  X509Certificate clientCertificate = serverEnd.peerCertificate;
  if (sendCert) {
    Expect.isNotNull(clientCertificate);
    Expect.equals("/CN=user1", clientCertificate.subject);
    Expect.equals("/CN=clientauthority", clientCertificate.issuer);
  } else {
    Expect.isNull(clientCertificate);
  }
  X509Certificate serverCertificate = clientEnd.peerCertificate;
  Expect.isNotNull(serverCertificate);
  Expect.equals("/CN=localhost", serverCertificate.subject);
  Expect.equals("/CN=intermediateauthority", serverCertificate.issuer);
  clientEnd.close();
  serverEnd.close();
}

main() async {
  asyncStart();
  HOST = (await InternetAddress.lookup("localhost")).first;
  await testClientCertificate(required: false, sendCert: true);
  await testClientCertificate(required: true, sendCert: true);
  await testClientCertificate(required: false, sendCert: false);
  await testClientCertificate(required: true, sendCert: false);
  asyncEnd();
}
