// Copyright (c) 2024, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import '../../common/testing.dart' as helper;
import 'package:expect/expect.dart';

/// A dynamic module can use core libraries and language features.
void main() async {
  final result = await helper.load('entry1.dart');
  Expect.isTrue(result);
  helper.done();
}
