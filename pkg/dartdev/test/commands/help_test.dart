// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test/test.dart';

import '../utils.dart';

void main() {
  group('help', help);
}

void help() {
  TestProject p;

  tearDown(() => p?.dispose());

  test('pub', () {
    p = project();
    var result = p.runSync('help', ['pub']);

    var pubHelpResult = p.runSync('pub', ['help']);
    expect(result.stdout, contains(pubHelpResult.stdout));
    expect(result.stderr, contains(pubHelpResult.stderr));
  });
}
