// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:expect/expect.dart';

method1() {
  /*strong.direct,explicit=[local.T],needsArgs,needsSignature*/
  /*omit.needsSignature*/
  T local<T>(T t) => t;
  return local;
}

@NoInline()
test(o) => o is S Function<S>(S);

main() {
  Expect.isTrue(test(method1()));
}
