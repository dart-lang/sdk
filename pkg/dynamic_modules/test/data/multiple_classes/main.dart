// Copyright (c) 2024, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:expect/expect.dart';

import '../../common/testing.dart' as helper;
import 'modules/common.dart';

// It is an error to load a module that provides a second definition for
// a library that already exists in the application.
main() async {
  final a1 = await helper.load('entry1.dart') as A;
  final a2 = await helper.load('entry2.dart') as A;
  Expect.equals(a1.getString(), 'B');
  Expect.equals(a2.getString(), 'C');
  helper.done();
}
