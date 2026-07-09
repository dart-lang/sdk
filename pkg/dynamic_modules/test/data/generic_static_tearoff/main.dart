// Copyright (c) 2025, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import '../../common/testing.dart' as helper;
import 'package:expect/expect.dart';

void main() async {
  final f = await helper.load('entry1.dart') as int Function(int);
  Expect.equals(3, f(3));
  helper.done();
}
