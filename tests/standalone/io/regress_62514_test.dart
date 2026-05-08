// Copyright (c) 2026, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
//
// OtherResources=certificates/server_chain.pem
// OtherResources=certificates/server_key.pem

// Test that cancellation of subscription to [SecureSocket] works as
// expected.

import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

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

    final bytes = Uint8List(1024 * 1024);
    final dataStream = Stream.fromIterable(
      Iterable<List<int>>.generate(100, (_) => bytes),
    );

    secureServer.listen((client) async {
      runZonedGuarded(() async {
        await dataStream.pipe(client);
        await client.close();
      }, (e, st) {});
    });

    final secureClient = await SecureSocket.connect(
      InternetAddress.loopbackIPv4,
      secureServer.port,
      context: SecurityContext()..setTrustedCertificates(serverCert),
    );
    final canContinue = Completer();
    late final StreamSubscription clientSub;
    clientSub = secureClient.listen((event) async {
      await clientSub.cancel();
      canContinue.complete();
    });
    // We need to give the race a chance to happen.
    await Future.delayed(Duration(milliseconds: 100));
    await canContinue.future;

    await Future.wait([secureClient.close(), secureServer.close()]);
  });
}
