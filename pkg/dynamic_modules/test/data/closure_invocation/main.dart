// Copyright (c) 2025, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import '../../common/testing.dart' as helper;
import 'package:expect/expect.dart';

import 'shared/shared.dart' as shared;

void main() async {
  await helper.load('entry1.dart');
  Expect.equals('dynamic module 1: hello', shared.topLevelClosure!('hello'));
  helper.done();
}
