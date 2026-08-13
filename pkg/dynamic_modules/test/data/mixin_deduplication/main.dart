// Copyright (c) 2025, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import '../../common/testing.dart' as helper;
import 'package:expect/expect.dart';

/// A dynamic module can reference a mixin application which
/// could be de-duplicated.
void main() async {
  final results = (await helper.load('entry1.dart')) as List;
  Expect.equals(43, results[0]);
  Expect.equals(44, results[1]);
  helper.done();
}
