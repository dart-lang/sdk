// Copyright (c) 2025, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import '../../common/testing.dart' as helper;
import 'package:expect/expect.dart';

void main() async {
  final result = await helper.load('entry1.dart') as Enum;
  Expect.equals('e2', result.name);
  Expect.equals('Foo.e2', result.toString());
  helper.done();
}
