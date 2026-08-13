// Copyright (c) 2024, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import '../../common/testing.dart' as helper;
import 'package:expect/expect.dart';

import 'shared/shared.dart' as shared;

/// A top-level setter can be invoked from a dynamic module.
void main() async {
  Expect.equals('original', shared.topLevelField);
  Expect.equals(0, shared.topLevelGetterInternal);
  Expect.equals(0, shared.topLevelSetterInternal);
  Expect.equals(0, shared.topLevelMethodInternal);
  await helper.load('entry1.dart');
  Expect.equals('updated', shared.topLevelField);
  Expect.equals(1, shared.topLevelGetterInternal);
  Expect.equals(1, shared.topLevelSetterInternal);
  Expect.equals(1, shared.topLevelMethodInternal);
  helper.done();
}
