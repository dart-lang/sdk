// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import "dart:async";
import "dart:io";

import "package:async_helper/async_helper.dart";
import "package:expect/expect.dart";
import "package:path/path.dart";

const HOST_NAME = "localhost";
const CERTIFICATE = "localhost_cert";

void testClientCertificate() {
  asyncStart();
  SecureServerSocket.bind(HOST_NAME,
                          0,
                          CERTIFICATE,
                          requestClientCertificate: true).then((server) {
    var clientEndFuture = SecureSocket.connect(HOST_NAME,
                                               server.port,
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
        asyncEnd();
      });
    });
  });
}

void testRequiredClientCertificate() {
  asyncStart();
  SecureServerSocket.bind(HOST_NAME,
                          0,
                          CERTIFICATE,
                          requireClientCertificate: true).then((server) {
    var clientEndFuture = SecureSocket.connect(HOST_NAME,
                                               server.port,
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
        asyncEnd();
      });
    });
  });
}

void testNoClientCertificate() {
  asyncStart();
  SecureServerSocket.bind(HOST_NAME,
                          0,
                          CERTIFICATE,
                          requestClientCertificate: true).then((server) {
    var clientEndFuture = SecureSocket.connect(HOST_NAME,
                                               server.port);
    server.listen((serverEnd) {
      X509Certificate certificate = serverEnd.peerCertificate;
      Expect.isNull(certificate);
      clientEndFuture.then((clientEnd) {
        clientEnd.close();
        serverEnd.close();
        server.close();
        asyncEnd();
      });
    });
  });
}

void testNoRequiredClientCertificate() {
  asyncStart();
  bool clientError = false;
  SecureServerSocket.bind(HOST_NAME,
                          0,
                          CERTIFICATE,
                          requireClientCertificate: true).then((server) {
    Future clientDone = SecureSocket.connect(HOST_NAME, server.port)
      .catchError((e) { clientError = true; });
    server.listen((serverEnd) {
      Expect.fail("Got a unverifiable connection");
    },
    onError: (e) {
      clientDone.then((_) {
        Expect.isTrue(clientError);
        server.close();
        asyncEnd();
      });
    });
  });
}

void main() {
  String certificateDatabase = join(dirname(Platform.script), 'pkcert');
  SecureSocket.initialize(database: certificateDatabase,
                          password: 'dartdart',
                          useBuiltinRoots: false);

  testClientCertificate();
  testRequiredClientCertificate();
  testNoClientCertificate();
  testNoRequiredClientCertificate();
}
