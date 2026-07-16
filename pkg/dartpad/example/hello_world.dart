// Copyright (c) 2026, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:dartpad/dartpad.dart';

Future<void> main() async {
  final sdk = DartPadSdk(
    // Absolute URL for files in web/ folder of package:dartpad
    assetBaseUrl: Uri.base.resolve('web/'),
  );

  final dartpad = await sdk.dedicatedWorker();
  final ws = await dartpad.createWorkspace();
  await ws.writeFileFromText(
    'main.dart',
    'void main() => print("hello world");',
  );
}
