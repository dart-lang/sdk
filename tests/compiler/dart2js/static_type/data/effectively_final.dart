// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

main() {
  effectivelyFinalList();
  notEffectivelyFinalList();
  effectivelyFinalPromoted();
  effectivelyFinalPromotedInvalid();
}

effectivelyFinalList() {
  dynamic c = [];
  /*dynamic*/ c. /*invoke: dynamic*/ add(null);
}

notEffectivelyFinalList() {
  dynamic c = [];
  /*dynamic*/ c. /*invoke: dynamic*/ add(null);
  c = null;
}

num _method1() => null;

effectivelyFinalPromoted() {
  dynamic c = _method1();
  /*dynamic*/ c /*invoke: dynamic*/ + 0;
  if (/*dynamic*/ c is int) {
    /*int*/ c /*invoke: int*/ + 1;
  }
}

String _method2() => null;

effectivelyFinalPromotedInvalid() {
  dynamic c = _method2();
  /*dynamic*/ c /*invoke: dynamic*/ + '';
  if (/*dynamic*/ c is int) {
    /*int*/ c /*invoke: int*/ + 1;
  }
}
