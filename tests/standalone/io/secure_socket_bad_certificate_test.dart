// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
//
// VMOptions=
// VMOptions=--short_socket_read
// The --short_socket_write option does not work with external server
// www.google.dk.  Add this to the test when we have secure server sockets.
// See TODO below.

import "dart:async";
import "dart:isolate";
import "dart:io";

void WriteAndClose(Socket socket, String message) {
  var data = message.charCodes;
  int written = 0;
  void write() {
    written += socket.writeList(data, written, data.length - written);
    if (written < data.length) {
      socket.onWrite = write;
    } else {
      socket.close(true);
    }
  }
  write();
}

void main() {
  SecureSocket.initialize(useBuiltinRoots: false);
  testCertificateCallback(host: "www.google.dk",
                          acceptCertificate: false).then((_) {
    testCertificateCallback(host: "www.google.dk",
                            acceptCertificate: true).then((_) {
      // TODO(7153): Open a receive port, and close it when we get here.
      // Currently, it can happen that neither onClosed or onError is called.
      // So we never reach this point. Diagnose this and fix.
    });
  });
}

Future testCertificateCallback({String host, bool acceptCertificate}) {
  Completer completer = new Completer();
  var secure = new SecureSocket(host, 443);
  List<String> chunks = <String>[];
  secure.onConnect = () {
    Expect.isTrue(acceptCertificate);
    WriteAndClose(secure, "GET / HTTP/1.0\r\nHost: $host\r\n\r\n");
  };
  secure.onBadCertificate = (_) { };
  secure.onBadCertificate = null;
  Expect.throws(() => secure.onBadCertificate = 7,
                (e) => e is TypeError || e is SocketIOException);
  secure.onBadCertificate = (X509Certificate certificate) {
    Expect.isTrue(certificate.subject.contains("O=Google Inc"));
    Expect.isTrue(certificate.startValidity < new DateTime.now());
    Expect.isTrue(certificate.endValidity > new DateTime.now());
    return acceptCertificate;
  };
  secure.onData = () {
    Expect.isTrue(acceptCertificate);
    chunks.add(new String.fromCharCodes(secure.read()));
  };
  secure.onClosed = () {
    Expect.isTrue(acceptCertificate);
    String fullPage = Strings.concatAll(chunks);
    Expect.isTrue(fullPage.contains('</body></html>'));
    completer.complete(null);
  };
  secure.onError = (e) {
    Expect.isFalse(acceptCertificate);
    completer.complete(null);
  };
  return completer.future;
}
