// Copyright (c) 2026, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import '../../common/testing.dart' as helper;
import 'shared/shared.dart' show L1Ea, L1Fa, L1Ga;
import 'package:expect/expect.dart';

void main() async {
  final result = await helper.load('entry.dart');
  final map = result as Map<String, List>;
  final isChecks = map['o-is']!;
  Expect.equals(isChecks.length, 4);
  for (var check in isChecks) {
    Expect.isTrue(check);
  }
  Expect.isTrue(map['list-of-l1ec'] is List<L1Ea>);
  Expect.isTrue(map['list-of-l1fc'] is List<L1Fa>);
  Expect.isTrue(map['list-of-l1gc'] is List<L1Ga>);
  helper.done();
}
