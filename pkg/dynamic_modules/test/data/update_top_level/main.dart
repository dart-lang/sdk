// Copyright (c) 2024, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import '../../common/testing.dart' as helper;
import 'package:expect/expect.dart';

import 'shared/shared.dart' show topLevel;

/// A top-level setter can be invoked from a dynamic module.
main() async {
  Expect.equals('original', topLevel);
  await helper.load('entry1.dart');
  Expect.equals('updated', topLevel);
  helper.done();
}
