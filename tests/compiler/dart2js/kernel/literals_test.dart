// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test/test.dart';

import 'helper.dart' show check;

main() {
  test('compile function that returns a literal list', () {
    return check('main() { return [1, 2, 3]; }');
  });
  test('compile function that returns a const list', () {
    return check('main() { return const [1, 2, 3]; }');
  });
}
