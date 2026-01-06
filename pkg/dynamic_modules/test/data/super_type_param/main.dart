// Copyright (c) 2026, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import '../../common/testing.dart' as helper;
import 'package:expect/expect.dart';

/// A dynamic module can create an instance of a class referencing
/// other classes via supertype type arguments.
void main() async {
  final result = (await helper.load('entry1.dart')) as List;
  Expect.isNotNull(result.length == 2);
  Expect.isNotNull(result[0]);
  Expect.isNotNull(result[1]);
  helper.done();
}
