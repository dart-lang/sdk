// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';
import 'dart:io';

import 'package:ffi/ffi.dart';
import 'package:test/test.dart';

import '../lib/http.dart';

Future<void> main() async {
  test('httpGet', () async {
    final response = await httpGet('http://example.com');
    expect(response, contains('Hello world!'));
  });

  test('httpServe', () async {
    final completer = Completer<String>();
    httpServe((request) {
      if (!completer.isCompleted) {
        completer.complete(request);
      }
    });
    final request = await completer.future;
    expect(request, contains('www.example.com'));
  });
}
