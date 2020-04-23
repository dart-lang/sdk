// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:io';

import 'package:test/test.dart';

import 'test_context.dart';

void main() {
  test('run original example', () async {
    File exampleFile = findFile('pkg/dartfix/example/example.dart');

    print('--- launching original example');
    final futureResult1 =
        Process.run(Platform.resolvedExecutable, [exampleFile.path]);

    print('--- waiting for original example');
    final result = await futureResult1;

    print('--- original example output');
    var text = result.stdout as String;
    print(text);

    expect(text.trim(), 'myDouble = 4.0');
  });
}
