// Copyright (c) 2025, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import '../../common/testing.dart' as helper;
import 'package:expect/expect.dart';

import 'shared/shared.dart'; // ignore: unused_import

/// Verify that default values of const constructor parameters are retained.
void main() async {
  final result = (await helper.load('entry1.dart')) as String;
  Expect.equals("Foo1:41 Foo2:42 Foo3:43", result);
  helper.done();
}
