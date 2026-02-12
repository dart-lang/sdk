// Copyright (c) 2026, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import '../../common/testing.dart' as helper;
import 'package:expect/expect.dart';

import 'shared/shared.dart' as shared;

void main() async {
  final wrap = shared.wrap<int, String>;
  final wrapped = wrap(3, 'hello');
  Expect.equals(3, wrapped.$1);
  Expect.equals('hello', wrapped.$2);
  final dynModWrap =
      await helper.load('entry1.dart') as (bool, int) Function(bool k, int v);
  final dynModWrapped = dynModWrap(true, 5);
  Expect.equals(true, dynModWrapped.$1);
  Expect.equals(5, dynModWrapped.$2);
  helper.done();
}
