// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import "dart:async";
import "dart:io";

import "package:async_helper/async_helper.dart";
import "package:expect/expect.dart";

InternetAddress HOST;
const CERTIFICATE = "localhost_cert";

Future testClientCertificate() {
  var completer = new Completer();
  SecureServerSocket.bind(HOST,
                          0,
                          CERTIFICATE,
                          requestClientCertificate: true).then((server) {
    var clientEndFuture = SecureSocket.connect(HOST,
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
                          CERTIFICATE,
                          requireClientCertificate: true).then((server) {
    var clientEndFuture = SecureSocket.connect(HOST,
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
        completer.complete();
      });
    });
  });
  return completer.future;
}

void main() {
  String certificateDatabase = Platform.script.resolve('pkcert').toFilePath();
  SecureSocket.initialize(database: certificateDatabase,
                          password: 'dartdart',
                          useBuiltinRoots: false);

  asyncStart();
  InternetAddress.lookup("localhost").then((hosts) => HOST = hosts.first)
    .then((_) => testClientCertificate())
    .then((_) => testRequiredClientCertificate())
    .then((_) => asyncEnd());
}
