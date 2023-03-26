// Copyright (c) 2023, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test/test.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'server_abstract.dart';

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(OpenUriTest);
  });
}

@reflectiveTest
class OpenUriTest extends AbstractLspAnalysisServerTest {
  final exampleUri = Uri.parse("https://example.org");

  Future<void> initializeWithUriSupport() async {
    await initialize(initializationOptions: {
      'allowOpenUri': true,
    });
  }

  Future<void> test_assertsSupported() async {
    final testUri = Uri.parse("https://example.org");
    await initialize(); // no support

    expect(() => server.sendOpenUriNotification(testUri),
        throwsA(TypeMatcher<AssertionError>()));
  }

  Future<void> test_openUri() async {
    await initializeWithUriSupport();

    final notificationFuture = openUriNotifications.first;
    server.sendOpenUriNotification(exampleUri);
    final notification = await notificationFuture;

    expect(notification.uri, exampleUri);
  }
}
