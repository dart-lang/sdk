// Copyright (c) 2026, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
//
// OtherResources=certificates/server_chain.pem
// OtherResources=certificates/server_key.pem

// This test verifies that setting readEventsEnabled to false on
// RawSecureSocket correctly updates readEventsEnabled on the underlying
// RawSocket.

import 'dart:async';
import 'dart:io';

import 'package:async_helper/async_helper.dart';
import 'package:expect/expect.dart';

String relativeToScript(path) => Platform.script.resolve(path).toFilePath();

final String serverCert = relativeToScript('certificates/server_chain.pem');
final String serverKey = relativeToScript('certificates/server_key.pem');

void main() {
  asyncTest(() async {
    final serverContext = SecurityContext()
      ..useCertificateChain(serverCert)
      ..usePrivateKey(serverKey, password: 'dartdart');

    final secureServer = await SecureServerSocket.bind(
      InternetAddress.loopbackIPv4,
      0,
      serverContext,
    );

    final connection = secureServer.first;

    final clientSocket = await RawSocket.connect(
      InternetAddress.loopbackIPv4,
      secureServer.port,
    );
    final clientSecureSocket = await RawSecureSocket.secure(
      clientSocket,
      context: SecurityContext()..setTrustedCertificates(serverCert),
    );

    clientSecureSocket.listen((event) {});

    final connected = await connection;
    connected.drain();

    Expect.isTrue(clientSocket.readEventsEnabled);

    for (var i = 0; i < 2; i++) {
      clientSecureSocket.readEventsEnabled = false;
      Expect.isFalse(clientSocket.readEventsEnabled);

      clientSecureSocket.readEventsEnabled = true;
      Expect.isTrue(clientSocket.readEventsEnabled);
    }

    await Future.wait([
      clientSecureSocket.close(),
      secureServer.close(),
      connected.close(),
    ]);
  });
}
