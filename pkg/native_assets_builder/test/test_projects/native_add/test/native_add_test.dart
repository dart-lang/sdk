// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:native_add/native_add.dart';
import 'package:test/test.dart';

void main() {
  test('native add test', () {
    final result = add(4, 6);
    expect(result, equals(10));
  });
}
