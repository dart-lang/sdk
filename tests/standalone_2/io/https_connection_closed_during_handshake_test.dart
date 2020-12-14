// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// VMOptions=--long-ssl-cert-evaluation

// This test verifies that lost of connection during handshake doesn't cause
// vm crashes.

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import "package:expect/expect.dart";

String getFilename(String path) => Platform.script.resolve(path).toFilePath();

final SecurityContext serverSecurityContext = () {
  final context = SecurityContext();
  context
      .usePrivateKeyBytes(File(getFilename('localhost.key')).readAsBytesSync());
  context.useCertificateChainBytes(
      File(getFilename('localhost.crt')).readAsBytesSync());
  return context;
}();

final SecurityContext clientSecurityContext = () {
  final context = SecurityContext(withTrustedRoots: true);
  context.setTrustedCertificatesBytes(
      File(getFilename('localhost.crt')).readAsBytesSync());
  return context;
}();

void main(List<String> args) async {
  if (args.length >= 1 && args[0] == 'server') {
    final server =
        await SecureServerSocket.bind('localhost', 0, serverSecurityContext);
    print('ok ${server.port}');
    server.listen((socket) {
      print('server: got connection');
      socket.close();
    });
    await Future.delayed(Duration(seconds: 2));
    print('server: exiting');
    exit(1);
  }

  final serverProcess = await Process.start(
      Platform.executable, [Platform.script.toFilePath(), 'server']);
  final serverPortCompleter = Completer<int>();

  serverProcess.stdout
      .transform(utf8.decoder)
      .transform(LineSplitter())
      .listen((line) {
    print('server stdout: $line');
    if (line.startsWith('ok')) {
      serverPortCompleter.complete(int.parse(line.substring('ok'.length)));
    }
  });
  serverProcess.stderr
      .transform(utf8.decoder)
      .transform(LineSplitter())
      .listen((line) => print('server stderr: $line'));

  int port = await serverPortCompleter.future;

  var thrownException;
  try {
    print('client connecting...');
    await SecureSocket.connect('localhost', port,
        context: clientSecurityContext);
    print('client connected.');
  } catch (e) {
    thrownException = e;
  } finally {
    await serverProcess.kill();
  }
  print('thrownException: $thrownException');
  Expect.isTrue(thrownException is HandshakeException);
}
