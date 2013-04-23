// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
//
// VMOptions=
// VMOptions=--short_socket_read
// VMOptions=--short_socket_write
// VMOptions=--short_socket_write --short_socket_read
// The --short_socket_write option does not work with external server
// www.google.dk.  Add this to the test when we have secure server sockets.
// See TODO below.

import "package:expect/expect.dart";
import "dart:async";
import "dart:isolate";
import "dart:io";

void main() {
  ReceivePort keepAlive = new ReceivePort();
  SecureSocket.initialize(useBuiltinRoots: false);
  testCertificateCallback(host: "www.google.dk",
                          acceptCertificate: false).then((_) {
    testCertificateCallback(host: "www.google.dk",
                            acceptCertificate: true).then((_) {
                                keepAlive.close();
      // TODO(7153): Open a receive port, and close it when we get here.
      // Currently, it can happen that neither onClosed or onError is called.
      // So we never reach this point. Diagnose this and fix.
    });
  });
}

Future testCertificateCallback({String host, bool acceptCertificate}) {
  Expect.throws(
      () {
        var x = 7;
        SecureSocket.connect(host, 443, onBadCertificate: x);
      },
      (e) => e is ArgumentError || e is TypeError);

  bool badCertificateCallback(X509Certificate certificate) {
    Expect.isTrue(certificate.subject.contains("O=Google Inc"));
    Expect.isTrue(certificate.startValidity.isBefore(new DateTime.now()));
    Expect.isTrue(certificate.endValidity.isAfter(new DateTime.now()));
    return acceptCertificate;
  };

  return SecureSocket.connect(host,
                              443,
                              onBadCertificate: badCertificateCallback)
      .then((socket) {
        Expect.isTrue(acceptCertificate);
        socket.write("GET / HTTP/1.0\r\nHost: $host\r\n\r\n");
        socket.close();
        return socket.fold(<int>[], (message, data)  => message..addAll(data))
            .then((message) {
              String received = new String.fromCharCodes(message);
              Expect.isTrue(received.contains('</body></html>'));
            });
      }).catchError((e) {
        Expect.isFalse(acceptCertificate);
      });
}
