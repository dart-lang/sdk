// Copyright (c) 2025, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import '../../common/testing.dart' as helper;
// ignore: unused_import
import 'shared/shared.dart';
import 'package:expect/expect.dart';

/// Verify that `is` test works correctly for an instance of a class
/// from a dynamic module which extends class from the host app.
void main() async {
  final o = (await helper.load('entry1.dart')) as List;
  Expect.isTrue(o.first);
  Expect.isTrue(o.last);
  helper.done();
}
