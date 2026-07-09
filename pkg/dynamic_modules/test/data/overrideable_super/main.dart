// Copyright (c) 2025, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import '../../common/testing.dart' as helper;
import 'package:expect/expect.dart';

import 'shared/shared.dart' show Child, Other;

void main() async {
  final o1 = Other();
  Child();

  // Ensure that the overrides correctly call `super.toString()`, eventually
  // ending at `Object.toString`. The class name may be minified, so we don't
  // want to make it part of the expectation.
  Expect.isTrue(o1.toString().startsWith('Instance of'));

  Expect.equals(3, await helper.load('entry1.dart'));
  helper.done();
}
