// Copyright (c) 2024, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import '../../common/testing.dart' as helper;
import 'package:expect/async_helper.dart' show asyncExpectThrows;

/// For the same reasons as the `duplicate_library` test, it is an error to load
/// the same module twice.
main() async {
  await helper.load('entry1.dart');
  await asyncExpectThrows(helper.load('entry1.dart'));
  helper.done();
}
