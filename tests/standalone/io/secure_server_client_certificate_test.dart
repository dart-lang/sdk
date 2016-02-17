// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import "dart:async";
import "dart:io";

import "package:async_helper/async_helper.dart";
import "package:expect/expect.dart";

InternetAddress HOST;

String localFile(path) => Platform.script.resolve(path).toFilePath();

SecurityContext serverContext(String certType) => new SecurityContext()
  ..useCertificateChainSync(localFile('certificates/server_chain.$certType'))
  ..usePrivateKeySync(localFile('certificates/server_key.$certType'),
                      password: 'dartdart')
  ..setTrustedCertificatesSync(localFile(
      'certificates/client_authority.$certType'))
  ..setClientAuthoritiesSync(localFile(
      'certificates/client_authority.$certType'));

SecurityContext clientCertContext(String certType) => new SecurityContext()
  ..setTrustedCertificatesSync(localFile(
      'certificates/trusted_certs.$certType'))
  ..useCertificateChainSync(localFile('certificates/client1.$certType'))
  ..usePrivateKeySync(localFile('certificates/client1_key.$certType'),
                                password: 'dartdart');

SecurityContext clientNoCertContext(String certType) => new SecurityContext()
  ..setTrustedCertificatesSync(localFile(
      'certificates/trusted_certs.$certType'));

Future testClientCertificate(
    {bool required, bool sendCert, String certType}) async {
  var server = await SecureServerSocket.bind(HOST, 0, serverContext(certType),
      requestClientCertificate: true, requireClientCertificate: required);
  var clientContext =
      sendCert ? clientCertContext(certType) : clientNoCertContext(certType);
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
  await testClientCertificate(required: false, sendCert: true, certType: 'pem');
  await testClientCertificate(required: true, sendCert: true, certType: 'pem');
  await testClientCertificate(
      required: false, sendCert: false, certType: 'pem');
  await testClientCertificate(required: true, sendCert: false, certType: 'pem');

  await testClientCertificate(required: false, sendCert: true, certType: 'p12');
  await testClientCertificate(required: true, sendCert: true, certType: 'p12');
  await testClientCertificate(
      required: false, sendCert: false, certType: 'p12');
  await testClientCertificate(required: true, sendCert: false, certType: 'p12');
  asyncEnd();
}
