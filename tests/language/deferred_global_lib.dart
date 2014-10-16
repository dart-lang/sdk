// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

var sideEffectCounter = 0;

final finalConstGlobal = "finalConstGlobal";
final finalNonConstGlobal = (() {
  sideEffectCounter++;
  return "finalNonConstGlobal";
}());

var lazyConstGlobal = "lazyConstGlobal";
var lazyNonConstGlobal = (() {
  sideEffectCounter++;
  return "lazyNonConstGlobal";
}());

readFinalConstGlobal() => finalConstGlobal;
readFinalNonConstGlobal() => finalNonConstGlobal;
readLazyConstGlobal() => lazyConstGlobal;
readLazyNonConstGlobal() => lazyNonConstGlobal;
writeLazyConstGlobal(x) { lazyConstGlobal = x; }
writeLazyNonConstGlobal(x) { lazyNonConstGlobal = x; }
