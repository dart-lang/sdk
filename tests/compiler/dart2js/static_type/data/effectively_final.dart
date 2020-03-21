// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// @dart = 2.7

main() {
  effectivelyFinalList();
  notEffectivelyFinalList();
  effectivelyFinalPromoted();
  effectivelyFinalPromotedInvalid();
}

effectivelyFinalList() {
  dynamic c = [];
  /*List<dynamic>*/ c. /*invoke: [List<dynamic>]->void*/ add(null);
  /*List<dynamic>*/ c.length /*invoke: [int]->int*/ + 1;
}

notEffectivelyFinalList() {
  dynamic c = [];
  /*dynamic*/ c. /*invoke: [dynamic]->dynamic*/ add(null);
  /*dynamic*/ c.length /*invoke: [dynamic]->dynamic*/ + 1;
  c = null;
}

num _method1() => null;

effectivelyFinalPromoted() {
  dynamic c = _method1();
  /*num*/ c /*invoke: [num]->num*/ + 0;
  if (/*num*/ c is int) {
    /*int*/ c /*invoke: [int]->int*/ + 1;
  }
}

String _method2() => null;

effectivelyFinalPromotedInvalid() {
  dynamic c = _method2();
  /*String*/ c /*invoke: [String]->String*/ + '';
  if (/*String*/ c is int) {
    /*int*/ c /*invoke: [int]->int*/ + 1;
  }
}
