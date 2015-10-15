// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:dart2js_info/info.dart';
import 'package:test/test.dart';

main() {
  // TODO(sigmund): add more tests
  group('parse', () {
    test('empty', () {
      var json = {
        'elements': {
          'library': {},
          'class': {},
          'function': {},
          'field': {},
          'typedef': {},
        },
        'holding': {},
        'program': {'size': 10},
      };

      expect(new AllInfo.fromJson(json).program.size, 10);
    });
  });
}
