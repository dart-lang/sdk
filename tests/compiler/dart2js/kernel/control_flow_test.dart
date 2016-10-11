// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test/test.dart';

import 'helper.dart' show check;

main() {
  group('compile control flow', () {
    test('simple if statement', () {
      String code = '''
        main() {
          if (true) {
            return 1;
          } else {
            return 2;
          }
        }''';
      return check(code);
    });
    test('simple if statement no else', () {
      String code = '''
        main() {
          if (true) {
            return 1;
          }
        }''';
      return check(code);
    });
    test('simple dead if statement', () {
      String code = '''
        main() {
          if (false) {
            return 1;
          }
        }''';
      return check(code);
    });
  });
}
