// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:compiler/src/commandline_options.dart' show Flags;
import 'package:test/test.dart';

import 'helper.dart' show check;

main() {
  test('assert without message', () {
    String code = '''
bool foo() => 2 + 2 == 4;
main() {
  assert(foo());
}''';
    return check(code,
        extraOptions: const <String>[Flags.enableCheckedMode],
        useKernelInSsa: true);
  });

  test('assert with message', () {
    String code = '''
bool foo() => 2 + 2 == 4;
main() {
  assert(foo(), "foo failed");
}''';
    return check(code,
        extraOptions: const <String>[
          Flags.enableCheckedMode,
          Flags.enableAssertMessage,
        ],
        useKernelInSsa: true);
  });
}
