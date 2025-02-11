// Copyright (c) 2025, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import '../../common/testing.dart' as helper;

import 'shared/shared.dart' show A, B;

main() async {
  final o = (await helper.load('entry1.dart')) as A;
  final l = <dynamic>[A(), B()];
  for (final entry in l) {
    entry.foo();
  }
  o.foo();
  helper.done();
}
