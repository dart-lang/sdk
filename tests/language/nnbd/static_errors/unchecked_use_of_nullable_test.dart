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
  List<Function?> funcList = [];
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
  cond!; //# 30: runtime error
  cond ?? null; //# 31: ok
  cond == null; //# 32: ok
  cond != null; //# 33: ok
  x?.isEven; //# 34: ok
  x?.round(); //# 35: ok
  for(var i in list) {}; //# 36: compile-time error
  await for(var i in stream) {}; //# 37: compile-time error
  assert(cond); //# 38: compile-time error
  [...list]; //# 39: compile-time error
  [...?list]; //# 40: ok
}

generator() sync* {
  Iterable? iter;
  yield* iter; //# 41: compile-time error
}

void typeParametersNullableBounds<IQ extends int?, BQ extends bool?, LQ extends List?, FQ extends Function?, SQ extends Stream?>(
    IQ x,
    BQ cond,
    LQ list,
    FQ func,
    List<FQ> funcList,
    SQ stream,
    ) async {
  x.isEven; //# 42: compile-time error
  x.round(); //# 43: compile-time error
  x.toString(); //# 44: ok
  x.hashCode; //# 45: ok
  x.runtimeType; //# 46: ok
  x.noSuchMethod(Invocation.method(#toString, [])); //# 47: ok
  x + 1; //# 48: compile-time error
  -x; //# 49: compile-time error
  x++; //# 50: compile-time error
  ++x; //# 51: compile-time error
  x..isEven; //# 52: compile-time error
  list[0]; //# 53: compile-time error
  list[0] = 0; //# 54: compile-time error
  x += 1; //# 55: compile-time error
  x ??= x; //# 56: ok
  x.round; //# 57: compile-time error
  x.toString; //# 58: ok
  x.noSuchMethod; //# 59: ok
  func(); //# 60: compile-time error
  funcList[0](); //# 61: compile-time error
  funcList.single(); //# 62: compile-time error
  throw x; //# 63: compile-time error
  cond || true; //# 64: compile-time error
  true || cond; //# 65: compile-time error
  cond && true; //# 66: compile-time error
  true && cond; //# 67: compile-time error
  !cond; //# 68: compile-time error
  cond ? null : null; //# 69: compile-time error
  if (cond) {} //# 70: compile-time error
  while (cond) {} //# 71: compile-time error
  for (;cond;){} //# 72: compile-time error
  do {} while (cond); //# 73: compile-time error
  cond!; //# 74: ok
  cond ?? null; //# 75: ok
  cond == null; //# 76: ok
  cond != null; //# 77: ok
  x?.isEven; //# 78: ok
  x?.round(); //# 79: ok
  for(var i in list) {}; //# 80: compile-time error
  await for(var i in stream) {}; //# 81: compile-time error
  assert(cond); //# 41: compile-time error
}

void typeParametersNullableUses<I extends int, B extends bool, L extends List, F extends Function, S extends Stream>(
    I? x,
    B? cond,
    L? list,
    F? func,
    List<F?> funcList,
    S? stream,
    ) async {
  x.isEven; //# 82: compile-time error
  x.round(); //# 83: compile-time error
  x.toString(); //# 84: ok
  x.hashCode; //# 85: ok
  x.runtimeType; //# 86: ok
  x.noSuchMethod(Invocation.method(#toString, [])); //# 87: ok
  x + 1; //# 88: compile-time error
  -x; //# 89: compile-time error
  x++; //# 90: compile-time error
  ++x; //# 91: compile-time error
  x..isEven; //# 92: compile-time error
  list[0]; //# 93: compile-time error
  list[0] = 0; //# 94: compile-time error
  x += 1; //# 95: compile-time error
  x ??= null; //# 96: ok
  x.round; //# 97: compile-time error
  x.toString; //# 98: ok
  x.noSuchMethod; //# 99: ok
  func(); //# 100: compile-time error
  funcList[0](); //# 101: compile-time error
  funcList.single(); //# 102: compile-time error
  throw x; //# 103: compile-time error
  cond || true; //# 104: compile-time error
  true || cond; //# 105: compile-time error
  cond && true; //# 106: compile-time error
  true && cond; //# 107: compile-time error
  !cond; //# 108: compile-time error
  cond ? null : null; //# 109: compile-time error
  if (cond) {} //# 110: compile-time error
  while (cond) {} //# 111: compile-time error
  for (;cond;) {} //# 112: compile-time error
  do {} while (cond); //# 113: compile-time error
  cond!; //# 114: ok
  cond ?? null; //# 115: ok
  cond == null; //# 116: ok
  cond != null; //# 117: ok
  x?.isEven; //# 118: ok
  x?.round(); //# 119: ok
  for(var i in list) {}; //# 120: compile-time error
  await for(var i in stream) {}; //# 121: compile-time error
}

void dynamicUses() async {
  dynamic dyn;
  dyn.isEven; //# 122: ok
  dyn.round(); //# 123: ok
  dyn.toString(); //# 124: ok
  dyn.hashCode; //# 125: ok
  dyn.runtimeType; //# 126: ok
  dyn.noSuchMethod(Invocation.method(#toString, [])); //# 127: ok
  dyn + 1; //# 128: ok
  -dyn; //# 129: ok
  dyn++; //# 130: ok
  ++dyn; //# 131: ok
  dyn..isEven; //# 132: ok
  dyn[0]; //# 133: ok
  dyn[0] = 0; //# 134: ok
  dyn += 1; //# 135: ok
  dyn ??= null; //# 136: ok
  dyn.round; //# 137: ok
  dyn.toString; //# 138: ok
  dyn.noSuchMethod; //# 139: ok
  dyn(); //# 140: ok
  dyn[0](); //# 141: ok
  dyn.single(); //# 142: ok
  throw dyn; //# 143: ok
  dyn || true; //# 144: ok
  true || dyn; //# 145: ok
  dyn && true; //# 146: ok
  true && dyn; //# 147: ok
  !dyn; //# 148: ok
  dyn ? null : null; //# 149: ok
  if (dyn) {} //# 150: ok
  while (dyn) {} //# 151: ok
  for (;dyn;) {} //# 152: ok
  do {} while (dyn); //# 153: ok
  dyn!; //# 154: ok
  dyn ?? null; //# 155: ok
  dyn == null; //# 156: ok
  dyn != null; //# 157: ok
  dyn?.isEven; //# 158: ok
  dyn?.round(); //# 159: ok
  for(var i in dyn) {}; //# 160: ok
  await for(var i in dyn) {}; //# 161: ok
}

void nullUses() async {
  List<Null> nullList;
  Null _null;
  _null.isEven; //# 162: compile-time error
  _null.round(); //# 163: compile-time error
  _null.toString(); //# 164: ok
  _null.hashCode; //# 165: ok
  _null.runtimeType; //# 166: ok
  _null.noSuchMethod(Invocation.method(#toString, [])); //# 167: ok
  _null + 4; //# 165: compile-time error
  -_null; //# 169: compile-time error
  _null++; //# 170: compile-time error
  ++_null; //# 171: compile-time error
  _null..isEven; //# 172: compile-time error
  _null[3]; //# 170: compile-time error
  _null[3] = 0; //# 171: compile-time error
  _null += 4; //# 172: compile-time error
  _null ??= _null; //# 176: ok
  _null.round; //# 177: compile-time error
  _null.toString; //# 178: ok
  _null.noSuchMethod; //# 179: ok
  _null(); //# 180: compile-time error
  nullList[3](); //# 178: compile-time error
  nullList.single(); //# 182: compile-time error
  throw _null; //# 183: compile-time error
  _null || true; //# 184: compile-time error
  true || _null; //# 185: compile-time error
  _null && true; //# 186: compile-time error
  true && _null; //# 187: compile-time error
  !_null; //# 188: compile-time error
  _null ? _null : _null; //# 189: compile-time error
  if (_null) {} //# 190: compile-time error
  while (_null) {} //# 191: compile-time error
  for (;_null;) {} //# 192: compile-time error
  do {} while (_null); //# 193: compile-time error
  _null!; //# 194: ok
  _null ?? _null; //# 195: ok
  _null == _null; //# 196: ok
  _null != _null; //# 197: ok
  _null?.toString(); //# 198: ok
  for(var i in _null) {}; //# 199: compile-time error
  await for(var i in _null) {}; //# 200: compile-time error
}
