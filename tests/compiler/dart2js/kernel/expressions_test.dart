// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test/test.dart';

import 'helper.dart' show check;

main() {
  group('string literals', () {
    test('juxtaposition', () {
      return check('main() { return "abc" "def"; }');
    });
    test('literal interpolation', () {
      return check('main() { return "abc\${1}def"; }');
    });
    test('complex interpolation', () {
      String code = '''
foo() => 1;
main() => "abc\${foo()}"
          "\${foo()}def";''';
      return check(code);
    });
  });
}
