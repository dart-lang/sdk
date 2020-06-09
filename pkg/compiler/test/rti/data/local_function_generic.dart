// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// @dart = 2.7

import 'package:expect/expect.dart';

method1() {
  /*spec:nnbd-off.direct,explicit=[local.T],needsArgs,needsSignature*/
  /*prod:nnbd-off|prod:nnbd-sdk.needsSignature*/
  /*spec:nnbd-sdk.direct,explicit=[local.T*],needsArgs,needsSignature*/ T
      local<T>(T t) => t;
  return local;
}

@pragma('dart2js:noInline')
test(o) => o is S Function<S>(S);

main() {
  Expect.isTrue(test(method1()));
}
