// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// @dart=2.5

/*library: nnbd=false*/

import 'opt_in.dart';

class LegacyClass extends Class implements Interface {
  int method3() => /*int*/ 0;

  int method4() => /*int*/ 0;
}

main() {
  LegacyClass c = new /*LegacyClass*/ LegacyClass();
  /*LegacyClass*/ c. /*invoke: int*/ method1();
  /*LegacyClass*/ c. /*invoke: int*/ method2();
  /*LegacyClass*/ c. /*invoke: int*/ method3();
  /*LegacyClass*/ c. /*invoke: int*/ method4();
}
