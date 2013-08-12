// Copyright (c) 2013, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
//
// Client that tests that a certificate authority certificate loaded
// at runtime can be used to verify a certificate chain. The server it
// connects to uses localhost_cert, signed by myauthority_cert, to connect
// securely.  This client tests that addCertificate works if a certificate
// database has been specified.

import 'dart:io';

void main() {
  int port = int.parse(new Options().arguments[0]);
  String certificate = new Options().arguments[1];
  String database = new Options().arguments[2];
  SecureSocket.initialize(database: database,
                          password: 'dartdart',
                          readOnly: false);
  SecureSocket.removeCertificate('localhost_cert');
  SecureSocket.removeCertificate('myauthority_cert');
  var mycert = new File(certificate).readAsBytesSync();
  SecureSocket.addCertificate(mycert,
                              SecureSocket.TRUST_ISSUE_SERVER_CERTIFICATES);
  if (null != SecureSocket.getCertificate('myauthority_cert')) {
    throw "Expected getCertificate to return null";
  }
  SecureSocket.connect('localhost', port).then((SecureSocket socket) {
    socket.writeln('hello world');
    socket.listen((data) { });
    return socket.close();
  }).then((_) {
    // The certificate is only in the in-memory cache, so cannot be removed.
    try {
      SecureSocket.removeCertificate('myauthority_cert');
    } catch (e) {
      if (e is! CertificateException) throw "error $e";
    }
  }).then((_) {
    print('SUCCESS');  // Checked by parent process.
  });
}
