// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import "package:expect/expect.dart";
import "dart:async";
import "dart:io";
import "dart:isolate";

const SERVER_ADDRESS = "127.0.0.1";
const HOST_NAME = "localhost";
const CERTIFICATE = "localhost_cert";

void testClientCertificate() {
  ReceivePort port = new ReceivePort();
  SecureServerSocket.bind(SERVER_ADDRESS,
                          0,
                          5,
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
        port.close();
      });
    });
  });
}

void testRequiredClientCertificate() {
  ReceivePort port = new ReceivePort();
  SecureServerSocket.bind(SERVER_ADDRESS,
                          0,
                          5,
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
        port.close();
      });
    });
  });
}

void testNoClientCertificate() {
  ReceivePort port = new ReceivePort();
  SecureServerSocket.bind(SERVER_ADDRESS,
                          0,
                          5,
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
        port.close();
      });
    });
  });
}

void testNoRequiredClientCertificate() {
  ReceivePort port = new ReceivePort();
  bool clientError = false;
  SecureServerSocket.bind(SERVER_ADDRESS,
                          0,
                          5,
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
        port.close();
      });
    });
  });
}

void main() {
  Path scriptDir = new Path(new Options().script).directoryPath;
  Path certificateDatabase = scriptDir.append('pkcert');
  SecureSocket.initialize(database: certificateDatabase.toNativePath(),
                          password: 'dartdart',
                          useBuiltinRoots: false);

  testClientCertificate();
  testRequiredClientCertificate();
  testNoClientCertificate();
  testNoRequiredClientCertificate();
}
