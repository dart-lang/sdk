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
  test('compile function that returns a literal map', () {
    return check('main() { return {"a": 1, "b": 2, "c": 3}; }',
        useKernelInSsa: true);
  });
  test('compile function that returns a const map', () {
    return check('main() { return const {"a": 1, "b": 2, "c": 3}; }');
  });
  test('compile top level string field ', () {
    return check('String foo = (() { return "a";})(); main() { return foo; }');
  });
}
