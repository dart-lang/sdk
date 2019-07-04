// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';
import '../libs/future_or_lib1.dart' deferred as lib1;
import '../libs/future_or_lib2.dart' as lib2;

/*strong.member: main:OutputUnit(main, {})*/
/*strongConst.member: main:
 OutputUnit(main, {}),
 constants=[ConstructedConstant(A())=OutputUnit(1, {lib1})]
*/
main() async {
  await lib1.loadLibrary();
  lib1.field is FutureOr<lib2.A>;
  lib1.field.method();
}
