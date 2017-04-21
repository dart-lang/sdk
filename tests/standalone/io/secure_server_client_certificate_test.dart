// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// OtherResources=certificates/server_chain.pem
// OtherResources=certificates/server_key.pem
// OtherResources=certificates/trusted_certs.pem
// OtherResources=certificates/client_authority.pem
// OtherResources=certificates/client1.pem
// OtherResources=certificates/client1_key.pem
// OtherResources=certificates/server_chain.p12
// OtherResources=certificates/server_key.p12
// OtherResources=certificates/trusted_certs.p12
// OtherResources=certificates/client_authority.p12
// OtherResources=certificates/client1.p12
// OtherResources=certificates/client1_key.p12

import "dart:async";
import "dart:io";

import "package:async_helper/async_helper.dart";
import "package:expect/expect.dart";

InternetAddress HOST;

String localFile(path) => Platform.script.resolve(path).toFilePath();

SecurityContext serverContext(String certType, String password) =>
    new SecurityContext()
      ..useCertificateChain(localFile('certificates/server_chain.$certType'),
          password: password)
      ..usePrivateKey(localFile('certificates/server_key.$certType'),
          password: password)
      ..setTrustedCertificates(
          localFile('certificates/client_authority.$certType'),
          password: password)
      ..setClientAuthorities(
          localFile('certificates/client_authority.$certType'),
          password: password);

SecurityContext clientCertContext(String certType, String password) =>
    new SecurityContext()
      ..setTrustedCertificates(
          localFile('certificates/trusted_certs.$certType'),
          password: password)
      ..useCertificateChain(localFile('certificates/client1.$certType'),
          password: password)
      ..usePrivateKey(localFile('certificates/client1_key.$certType'),
          password: password);

SecurityContext clientNoCertContext(String certType, String password) =>
    new SecurityContext()
      ..setTrustedCertificates(
          localFile('certificates/trusted_certs.$certType'),
          password: password);

Future testClientCertificate(
    {bool required, bool sendCert, String certType, String password}) async {
  var server = await SecureServerSocket.bind(
      HOST, 0, serverContext(certType, password),
      requestClientCertificate: true, requireClientCertificate: required);
  var clientContext = sendCert
      ? clientCertContext(certType, password)
      : clientNoCertContext(certType, password);
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
    Expect.isTrue(clientCertificate.subject.contains("user1"));
    Expect.isTrue(clientCertificate.issuer.contains("clientauthority"));
  } else {
    Expect.isNull(clientCertificate);
  }
  X509Certificate serverCertificate = clientEnd.peerCertificate;
  Expect.isNotNull(serverCertificate);
  Expect.isTrue(serverCertificate.subject.contains("localhost"));
  Expect.isTrue(serverCertificate.issuer.contains("intermediateauthority"));
  clientEnd.close();
  serverEnd.close();
}

main() async {
  asyncStart();
  HOST = (await InternetAddress.lookup("localhost")).first;
  await testClientCertificate(
      required: false, sendCert: true, certType: 'pem', password: 'dartdart');
  await testClientCertificate(
      required: true, sendCert: true, certType: 'pem', password: 'dartdart');
  await testClientCertificate(
      required: false, sendCert: false, certType: 'pem', password: 'dartdart');
  await testClientCertificate(
      required: true, sendCert: false, certType: 'pem', password: 'dartdart');

  await testClientCertificate(
      required: false, sendCert: true, certType: 'p12', password: 'dartdart');
  await testClientCertificate(
      required: true, sendCert: true, certType: 'p12', password: 'dartdart');
  await testClientCertificate(
      required: false, sendCert: false, certType: 'p12', password: 'dartdart');
  await testClientCertificate(
      required: true, sendCert: false, certType: 'p12', password: 'dartdart');
  asyncEnd();
}
