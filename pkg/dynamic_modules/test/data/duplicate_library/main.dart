// Copyright (c) 2024, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import '../../common/testing.dart' as helper;
import 'package:expect/async_helper.dart' show asyncExpectThrows;

// It is an error to load a module that provides a second definition for
// a library that already exists in the application.
main() async {
  await helper.load('entry1.dart');
  await asyncExpectThrows(helper.load('entry2.dart'));
  helper.done();
}
