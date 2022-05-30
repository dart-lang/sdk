// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async' show FutureOr;

import 'dart:collection' show LinkedHashMap, LinkedHashSet;

main() async {
  Map<int, bool> m = {};
  Set<int> s = {};
  Iterable<int> i = {};
  LinkedHashSet<int> lhs = {};
  LinkedHashMap<int, bool> lhm = {};

  Map<int, bool> fm = await mapfun();
  Set<int> fs = await setfun();
  Iterable<int> fi = await iterablefun();
  LinkedHashSet<int> flhs = await lhsfun();
  LinkedHashMap<int, bool> flhm = await lhmfun();

  Map<int, bool> fm2 = await mapfun2();
  Set<int> fs2 = await setfun2();
  Iterable<int> fi2 = await iterablefun2();
  LinkedHashSet<int> flhs2 = await lhsfun2();
  LinkedHashMap<int, bool> flhm2 = await lhmfun2();
}

Future<Map<int, bool>> mapfun() async => {};
Future<Set<int>> setfun() async => {};
Future<Iterable<int>> iterablefun() async => {};
Future<LinkedHashSet<int>> lhsfun() async => {};
Future<LinkedHashMap<int, bool>> lhmfun() async => {};

FutureOr<Map<int, bool>> mapfun2() => {};
FutureOr<Set<int>> setfun2() => {};
FutureOr<Iterable<int>> iterablefun2() => {};
FutureOr<LinkedHashSet<int>> lhsfun2() => {};
FutureOr<LinkedHashMap<int, bool>> lhmfun2() => {};
