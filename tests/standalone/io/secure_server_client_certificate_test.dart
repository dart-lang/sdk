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
                  password: 'dartdart');

SecurityContext clientContext = new SecurityContext()
  ..setTrustedCertificates(file: localFile('certificates/trusted_certs.pem'));

Future testClientCertificate() {
  var completer = new Completer();
  SecureServerSocket.bind(HOST,
                          0,
                          serverContext,
                          requestClientCertificate: true).then((server) {
    var clientEndFuture = SecureSocket.connect(HOST,
                                               server.port,
                                               context: clientContext,
                                               sendClientCertificate: true);
    server.listen((serverEnd) {
      X509Certificate certificate = serverEnd.peerCertificate;
      Expect.isNotNull(certificate);
      Expect.equals("CN=localhost", certificate.subject);
      Expect.equals("CN=myauthority", certificate.issuer);
      clientEndFuture.then((clientEnd) {
        X509Certificate certificate = clientEnd.peerCertificate;
        Expect.isNotNull(certificate);
        Expect.equals("CN=localhost", certificate.subject);
        Expect.equals("CN=myauthority", certificate.issuer);
        clientEnd.close();
        serverEnd.close();
        server.close();
        completer.complete();
      });
    });
  });
  return completer.future;
}

Future testRequiredClientCertificate() {
  var completer = new Completer();
  SecureServerSocket.bind(HOST,
                          0,
                          serverContext,
                          requireClientCertificate: true).then((server) {
    var clientEndFuture = SecureSocket.connect(HOST,
                                               server.port,
                                               context: clientContext,
                                               sendClientCertificate: true);
    server.listen((serverEnd) {
      X509Certificate certificate = serverEnd.peerCertificate;
      Expect.isNotNull(certificate);
      Expect.equals("CN=localhost", certificate.subject);
      Expect.equals("CN=myauthority", certificate.issuer);
      clientEndFuture.then((clientEnd) {
        X509Certificate certificate = clientEnd.peerCertificate;
        Expect.isNotNull(certificate);
        Expect.equals("CN=localhost", certificate.subject);
        Expect.equals("CN=myauthority", certificate.issuer);
        clientEnd.close();
        serverEnd.close();
        server.close();
        completer.complete();
      });
    });
  });
  return completer.future;
}

void main() {
  asyncStart();
  InternetAddress.lookup("localhost").then((hosts) => HOST = hosts.first)
    .then((_) => testClientCertificate())
    .then((_) => testRequiredClientCertificate())
    .then((_) => asyncEnd());
}
