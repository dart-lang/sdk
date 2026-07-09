// Copyright (c) 2026, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import '../../worker_harness.dart';

void main() {
  testFlutterWorkspace('pub get (fetch package:foo)', (ws) async {
    await ws.writeFileFromText('pubspec.yaml', '''
      name: myapp
      publish_to: none
      dependencies:
        flutter:
          sdk: flutter
      dev_dependencies:
        foo:
      environment:
        sdk: '>=3.12.0 <4.0.0'
    ''');

    final (:log) = await ws.pub(command: 'get');

    printOnFailure(log);
    check(
      log,
    ).matchesPattern(RegExp(r'Changed \d+ (dependencies|dependency)!'));
  });
}
