// Copyright (c) 2026, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:dartpad/dartpad.dart';
import 'package:web/web.dart';

Future<void> main() async {
  final sdk = DartPadSdk(
    // Absolute URL for files in web/ folder of package:dartpad
    assetBaseUrl: Uri.base.resolve('web/'),
  );

  // Create a Web Worker running the dartpad worker environment.
  final dartpad = await sdk.dedicatedWorker();

  // Create a workspace with pubspec.yaml and main.dart
  final ws = await dartpad.createWorkspace();
  await ws.writeFileFromText('pubspec.yaml', '''
    package: foo
    environment:
      sdk: ^3.11.0
    dependencies:
      http: ^1.0.0
  ''');
  await ws.writeFileFromText(
    'main.dart',
    'void main() => print("hello world");',
  );

  // Resolve dependenices
  await ws.pub(command: 'get');

  // Create a sandboxed iframe to run code in
  final iframe = await sdk.createSandboxedIframe(window.document.body!);
  // Connect the workspace to the iframe, making the workspace the owner!
  final sandbox = await ws.connectSandboxedIframe(iframe.port);

  // Print console output
  sandbox.console.forEach(print).ignore();
  // Run main.dart in the sanboxed iframe
  await sandbox.runMain('main.dart');

  // Cleanup
  await sandbox.close();
  await iframe.close();
  await ws.dispose();
  await dartpad.dispose();
}
