// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// SharedOptions=--enable-experiment=non-nullable

// Test that it is an error to use nullable types in unsound ways.
void main() async {
  int? x;
  bool? cond;
  List? list;
  Function? func;
  List<Function?> funcList;
  Stream? stream;
  x.isEven; //# 00: compile-time error
  x.round(); //# 01: compile-time error
  x.toString(); //# 02: ok
  x.hashCode; //# 03: ok
  x.runtimeType; //# 04: ok
  x.noSuchMethod(Invocation.method(#toString, [])); //# 05: ok
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
  for(var i in list) {}; //# 36: compile-time error
  await for(var i in stream) {}; //# 37: compile-time error
  assert(cond); //# 38: compile-time error
}

generator() sync* {
  Iterable? iter;
  yield* iter; //# 39: compile-time error
}

void typeParametersNullableBounds<IQ extends int?, BQ extends bool?, LQ extends List?, FQ extends Function?, SQ extends Stream?>(
    IQ x,
    BQ cond,
    LQ list,
    FQ func,
    List<FQ> funcList,
    SQ stream,
    ) async {
  x.isEven; //# 40: compile-time error
  x.round(); //# 41: compile-time error
  x.toString(); //# 42: ok
  x.hashCode; //# 43: ok
  x.runtimeType; //# 44: ok
  x.noSuchMethod(Invocation.method(#toString, [])); //# 45: ok
  x + 1; //# 46: compile-time error
  -x; //# 47: compile-time error
  x++; //# 48: compile-time error
  ++x; //# 49: compile-time error
  x..isEven; //# 50: compile-time error
  list[0]; //# 51: compile-time error
  list[0] = 0; //# 52: compile-time error
  x += 1; //# 53: compile-time error
  x ??= x; //# 54: ok
  x.round; //# 55: compile-time error
  x.toString; //# 56: ok
  x.noSuchMethod; //# 57: ok
  func(); //# 58: compile-time error
  funcList[0](); //# 59: compile-time error
  funcList.single(); //# 60: compile-time error
  throw x; //# 61: compile-time error
  cond || true; //# 62: compile-time error
  true || cond; //# 63: compile-time error
  cond && true; //# 64: compile-time error
  true && cond; //# 65: compile-time error
  !cond; //# 66: compile-time error
  cond ? null : null; //# 67: compile-time error
  if (cond) {} //# 68: compile-time error
  while (cond) {} //# 69: compile-time error
  for (;cond;){} //# 70: compile-time error
  do {} while (cond); //# 71: compile-time error
  cond!; //# 72: ok
  cond ?? null; //# 73: ok
  cond == null; //# 74: ok
  cond != null; //# 75: ok
  x?.isEven; //# 76: ok
  x?.round(); //# 77: ok
  for(var i in list) {}; //# 78: compile-time error
  await for(var i in stream) {}; //# 79: compile-time error
  assert(cond); //# 39: compile-time error
}

void typeParametersNullableUses<I extends int, B extends bool, L extends List, F extends Function, S extends Stream>(
    I? x,
    B? cond,
    L? list,
    F? func,
    List<F?> funcList,
    S? stream,
    ) async {
  x.isEven; //# 80: compile-time error
  x.round(); //# 81: compile-time error
  x.toString(); //# 82: ok
  x.hashCode; //# 83: ok
  x.runtimeType; //# 84: ok
  x.noSuchMethod(Invocation.method(#toString, [])); //# 85: ok
  x + 1; //# 86: compile-time error
  -x; //# 87: compile-time error
  x++; //# 88: compile-time error
  ++x; //# 89: compile-time error
  x..isEven; //# 90: compile-time error
  list[0]; //# 91: compile-time error
  list[0] = 0; //# 92: compile-time error
  x += 1; //# 93: compile-time error
  x ??= null; //# 94: ok
  x.round; //# 95: compile-time error
  x.toString; //# 96: ok
  x.noSuchMethod; //# 97: ok
  func(); //# 98: compile-time error
  funcList[0](); //# 99: compile-time error
  funcList.single(); //# 100: compile-time error
  throw x; //# 101: compile-time error
  cond || true; //# 102: compile-time error
  true || cond; //# 103: compile-time error
  cond && true; //# 104: compile-time error
  true && cond; //# 105: compile-time error
  !cond; //# 106: compile-time error
  cond ? null : null; //# 107: compile-time error
  if (cond) {} //# 108: compile-time error
  while (cond) {} //# 109: compile-time error
  for (;cond;) {} //# 110: compile-time error
  do {} while (cond); //# 111: compile-time error
  cond!; //# 112: ok
  cond ?? null; //# 113: ok
  cond == null; //# 114: ok
  cond != null; //# 115: ok
  x?.isEven; //# 116: ok
  x?.round(); //# 117: ok
  for(var i in list) {}; //# 118: compile-time error
  await for(var i in stream) {}; //# 119: compile-time error
}

void dynamicUses() async {
  dynamic dyn;
  dyn.isEven; //# 120: ok
  dyn.round(); //# 121: ok
  dyn.toString(); //# 122: ok
  dyn.hashCode; //# 123: ok
  dyn.runtimeType; //# 124: ok
  dyn.noSuchMethod(null); //# 125: ok
  dyn + 1; //# 126: ok
  -dyn; //# 127: ok
  dyn++; //# 128: ok
  ++dyn; //# 129: ok
  dyn..isEven; //# 130: ok
  dyn[0]; //# 131: ok
  dyn[0] = 0; //# 132: ok
  dyn += 1; //# 133: ok
  dyn ??= null; //# 134: ok
  dyn.round; //# 135: ok
  dyn.toString; //# 136: ok
  dyn.noSuchMethod; //# 137: ok
  dyn(); //# 138: ok
  dyn[0](); //# 139: ok
  dyn.single(); //# 140: ok
  throw dyn; //# 141: ok
  dyn || true; //# 142: ok
  true || dyn; //# 143: ok
  dyn && true; //# 144: ok
  true && dyn; //# 145: ok
  !dyn; //# 146: ok
  dyn ? null : null; //# 147: ok
  if (dyn) {} //# 148: ok
  while (dyn) {} //# 149: ok
  for (;dyn;) {} //# 150: ok
  do {} while (dyn); //# 151: ok
  dyn!; //# 152: ok
  dyn ?? null; //# 153: ok
  dyn == null; //# 154: ok
  dyn != null; //# 155: ok
  dyn?.isEven; //# 156: ok
  dyn?.round(); //# 157: ok
  for(var i in dyn) {}; //# 158: ok
  await for(var i in dyn) {}; //# 159: ok
}
