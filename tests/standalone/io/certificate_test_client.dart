// Copyright (c) 2013, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
//
// Client that tests that a certificate authority certificate loaded
// at runtime can be used to verify a certificate chain. The server it
// connects to uses localhost_cert, signed by myauthority_cert, to connect
// securely.

import 'dart:io';

void main() {
  int port = int.parse(new Options().arguments[0]);
  String certificate = new Options().arguments[1];
  SecureSocket.initialize();
  var mycert = new File(certificate).readAsBytesSync();
  bool threw = false;
  try {
    SecureSocket.addCertificate("I am not a cert".codeUnits,
                                SecureSocket.TRUST_ISSUE_SERVER_CERTIFICATES);
  } on CertificateException catch (e) {
    threw = true;
  }
  if (!threw) throw "Expected bad certificate to throw";

  threw = false;
  try {
    SecureSocket.addCertificate(mycert, "Trust me, I'm a string");
  } on CertificateException catch (e) {
    threw = true;
  }
  if (!threw) throw "Expected bad trust string to throw";

  SecureSocket.addCertificate(mycert,
                              SecureSocket.TRUST_ISSUE_SERVER_CERTIFICATES);

  SecureSocket.connect('localhost', port).then((SecureSocket socket) {
    socket.writeln('hello world');
    socket.listen((data) { });
    return socket.close();
  }).then((_) {
    SecureSocket.changeTrust('myauthority_cert', ',,');
    return SecureSocket.connect('localhost', port);
  }).then((_) {
    throw "Expected untrusted authority to stop connection";
  }, onError: (e) {
    if (e is! CertificateException) throw e;
  }).then((_) {
    SecureSocket.changeTrust('myauthority_cert', 'C,,');
    return SecureSocket.connect('localhost', port);
  }).then((SecureSocket socket) {
    socket.writeln('hello world');
    socket.listen((data) { });
    return socket.close();
  }).then((_) {
    SecureSocket.removeCertificate('myauthority_cert');
    return SecureSocket.connect('localhost', port);
  }).then((_) {
    throw "Expected untrusted root to stop connection";
  }, onError: (e) {
    if (e is! CertificateException) throw e;
  }).then((_) {
    print('SUCCESS');  // Checked by parent process.
  });
}
