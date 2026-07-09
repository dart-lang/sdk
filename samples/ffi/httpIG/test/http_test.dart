// Copyright (c) 2025, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
//
// VMOptions=--experimental-shared-data
// SharedObjects=fake_httpIG

import 'dart:async';

import 'package:test/test.dart';

import 'package:httpIG_sample/http.dart';

Future<void> main() async {
  test('httpGet', () async {
    final response = await httpGet('http://example.com');
    expect(response, contains('Hello world!'));
  });

  test('httpServe', () async {
    final completer = Completer<String>();
    final receivePort = httpServe((request) {
      if (!completer.isCompleted) {
        completer.complete(request);
      }
    });
    final request = await completer.future;
    expect(request, contains('www.example.com'));
    receivePort.close();
  });
}
