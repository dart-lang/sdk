// Copyright (c) 2021, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// VMOptions=--deterministic  --optimization-counter-threshold=100 --deoptimize-on-runtime-call-name-filter=TypeCheck --deoptimize-on-runtime-call-every=1 --max-subtype-cache-entries=0

main() {
  void nop() {}
  for (int i = 0; i < 1000; ++i) {
    if (assertAssignable(nop) != 1) {
      throw 'broken';
    }
  }
}

@pragma('vm:never-inline')
int assertAssignable(dynamic a0) {
  return ensureValidExpressionStack(1, a0 as void Function());
}

@pragma('vm:never-inline')
int ensureValidExpressionStack(int b, void Function() a) => b;
