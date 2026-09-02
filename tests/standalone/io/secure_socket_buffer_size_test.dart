// Copyright (c) 2026, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
//
// OtherResources=certificates/server_chain.pem
// OtherResources=certificates/server_key.pem
// OtherResources=certificates/trusted_certs.pem

import "dart:io";
import "dart:typed_data";

import "package:expect/expect.dart";

String localFile(String path) => Platform.script.resolve(path).toFilePath();

SecurityContext clientContext({int? secureSocketBufferSize}) {
  final context = SecurityContext();
  if (secureSocketBufferSize != null) {
    context.secureSocketBufferSize = secureSocketBufferSize;
  }
  return context
    ..setTrustedCertificates(localFile('certificates/trusted_certs.pem'));
}

Future<int> initialWrite(
  SecureServerSocket server,
  SecurityContext context,
) async {
  final socket = await RawSecureSocket.connect(
    InternetAddress.loopbackIPv4,
    server.port,
    context: context,
  );
  final written = socket.write(Uint8List(32 * 1024));
  await socket.close();
  return written;
}

void testInvalidSizes() {
  final context = SecurityContext();
  Expect.equals(8 * 1024, context.secureSocketBufferSize);
  Expect.throwsRangeError(() => context.secureSocketBufferSize = 8 * 1024 - 1);
  Expect.throwsRangeError(
    () => context.secureSocketBufferSize = 1024 * 1024 + 1,
  );
  context.secureSocketBufferSize = 64 * 1024;
  Expect.equals(64 * 1024, context.secureSocketBufferSize);
}

Future<void> main() async {
  testInvalidSizes();

  final serverContext = SecurityContext()
    ..secureSocketBufferSize = 64 * 1024
    ..useCertificateChain(localFile('certificates/server_chain.pem'))
    ..usePrivateKey(
      localFile('certificates/server_key.pem'),
      password: 'dartdart',
    );
  final server = await SecureServerSocket.bind(
    InternetAddress.loopbackIPv4,
    0,
    serverContext,
  );
  server.listen((socket) async {
    await socket.drain<void>();
    await socket.close();
  });

  Expect.equals(8 * 1024 - 1, await initialWrite(server, clientContext()));
  Expect.equals(
    32 * 1024,
    await initialWrite(
      server,
      clientContext(secureSocketBufferSize: 64 * 1024),
    ),
  );

  await server.close();
}
