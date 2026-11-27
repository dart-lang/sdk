// Copyright (c) 2026, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Needs Chrome and ChromeDriver. Runs on the pkg bots, and is skipped in
// pkg/pkg.status on the ones without Chrome.

import 'package:dartdev/src/web/project.dart';
import 'package:dartdev/src/web/serve/dev_server.dart';
import 'package:test/test.dart';

import '../test_utils.dart';
import 'chrome.dart';

void main() {
  test('serves a web app that runs in Chrome', () async {
    final project = await WebProject.find(await createWebApp());
    final server = await DevServer.start(project, port: 0);
    addTearDown(server.close);
    expect(server.compileErrors, isEmpty);

    final chrome = await startChrome();
    await chrome.get(server.url);
    // web/main.dart sets the title to 'hello' once main() runs.
    await waitForTitle(chrome, 'hello');
  }, timeout: const Timeout.factor(4));
}
