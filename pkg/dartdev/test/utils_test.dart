// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:dartdev/src/utils.dart';
import 'package:test/test.dart';

void main() {
  group('pluralize', () {
    test('zero', () {
      expect(pluralize('cat', 0), 'cats');
    });

    test('one', () {
      expect(pluralize('cat', 1), 'cat');
    });

    test('many', () {
      expect(pluralize('cat', 2), 'cats');
    });
  });
}
