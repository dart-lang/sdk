// Copyright (c) 2026, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import '../../common/testing.dart' as helper;
import 'package:expect/expect.dart';

class C1 {
  int method1() => 1;
  int method2() => 2;
}

class C2 {
  int method3() => 3;
  int method4() => 4;
}

final List escape = [C1(), C2()];

// Dynamic calls from the host app.
void main() async {
  print(escape);

  final list = (await helper.load('entry1.dart')) as List;
  dynamic o1 = list[0];
  Expect.equals('10', o1.method1());
  Expect.equals('20', o1.method2());

  dynamic o2 = list[1];
  Expect.equals('30', o2.method3());
  Expect.equals('40', o2.method4());
  Expect.equals('50', o2.method5());
  helper.done();
}
