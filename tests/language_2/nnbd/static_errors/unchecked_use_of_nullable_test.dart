// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// SharedOptions=--enable-experiment=non-nullable

// Test that it is an error to use nullable types in unsound ways.
void main() async {
  int? x;
  bool? cond;
  List? list;
  dynamic dyn;
  Function? func;
  List<Function?> funcList;
  Stream? stream;
  x.isEven; //# 00: compile-time error
  x.round(); //# 01: compile-time error
  x.toString(); //# 02: ok
  x.hashCode; //# 03: ok
  x.runtimeType; //# 04: ok
  x.noSuchMethod(null); //# 05: ok
  x + 1; //# 06: compile-time error
  -x; //# 06: compile-time error
  x++; //# 07: compile-time error
  ++x; //# 08: compile-time error
  x..isEven; //# 09: compile-time error
  list[0]; //# 10: compile-time error
  list[0] = 0; //# 10: compile-time error
  x += 1; //# 11: compile-time error
  x ??= 1; //# 12: ok
  x.round; //# 13: compile-time error
  x.toString; //# 14: ok
  x.noSuchMethod; //# 15: ok
  func(); //# 16: compile-time error
  funcList[0](); //# 17: compile-time error
  funcList.single(); //# 18: compile-time error
  throw x; //# 19: compile-time error
  cond || true; //# 20: compile-time error
  true || cond; //# 21: compile-time error
  cond && true; //# 22: compile-time error
  true && cond; //# 23: compile-time error
  !cond; //# 24: compile-time error
  cond ? null : null; //# 25: compile-time error
  if (cond) {} //# 26: compile-time error
  while (cond) {} //# 27: compile-time error
  for (;cond;) {} //# 28: compile-time error
  do {} while (cond); //# 29: compile-time error
  cond!; //# 30: ok
  cond ?? null; //# 31: ok
  cond == null; //# 32: ok
  cond != null; //# 33: ok
  x?.isEven; //# 34: ok
  x?.round(); //# 35: ok
  for(i in list) {}; //# 36: compile-time error
  await for(i in stream) {}; //# 37: compile-time error
  assert(cond); //# 38: compile-time error
}

generator() sync* {
  Iterable? iter;
  yield* iter; //# 39: compile-time error
}
