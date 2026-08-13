// Copyright (c) 2026, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import '../../common/testing.dart' as helper;
import 'package:expect/expect.dart';

/// A dynamic module can apply an exposed mixin with private members.
void main() async {
  final o = (await helper.load('entry1.dart'));
  Expect.isNotNull(o);
  helper.done();
}
