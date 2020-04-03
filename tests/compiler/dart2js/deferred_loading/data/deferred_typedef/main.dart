// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// @dart = 2.7

import 'lib1.dart' deferred as lib1;

/*member: main:OutputUnit(main, {}),constants=[ConstructedConstant(C(a=TypeConstant(void Function()),b=FunctionConstant(topLevelMethod)))=OutputUnit(1, {lib1}),TypeConstant(void Function())=OutputUnit(1, {lib1})]*/
main() async {
  await lib1.loadLibrary();
  print(lib1.cA);
  print(lib1.cB);
}
