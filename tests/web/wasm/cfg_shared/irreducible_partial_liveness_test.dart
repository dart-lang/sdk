// Copyright (c) 2026, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// dart2wasmOptions=--extra-compiler-option=--cfg

// Numeric test functions record the value observed at each visited entry as a
// base-10 digit (`trace = trace * 10 + digit`).
void main() {
  // l1(only1=1) -> l2(3, sets only1=2) -> l1(only1=2)
  expectEquals(132, partialInt(opaque(1), opaque(3)));
  // l2(3, sets only1=2) -> l1(only1=2) -> l2(3)
  expectEquals(323, partialInt(opaque(2), opaque(3)));

  expectEquals(132, partialDouble(opaque(1), opaque(3)));
  expectEquals(323, partialDouble(opaque(2), opaque(3)));

  expectEquals(132, partialBool(opaque(1), opaque(3)));
  expectEquals(323, partialBool(opaque(2), opaque(3)));

  idString(partialString(opaque(1), opaque(1)));
  idString(partialString(opaque(1), opaque(2)));
  idString(partialString(opaque(2), opaque(2)));

  final a = TagA();
  final b = TagB();
  // l1 breaks immediately -> returns initial `last = a` (10)
  expectEquals(10, partialObject(opaque(1), opaque(1), a, b).id());
  // l1(sets cur=b) -> l2(last=cur) -> returns `b` (20)
  expectEquals(20, partialObject(opaque(1), opaque(2), a, b).id());
  // l2(last=cur=a) -> returns `a` (10)
  expectEquals(10, partialObject(opaque(2), opaque(1), a, b).id());
  // l2(last=a) -> l1(sets cur=b) -> l2(last=b) -> returns `b` (20)
  expectEquals(20, partialObject(opaque(2), opaque(3), a, b).id());

  // l1(x=1) -> l2(x=2) -> l3(9, sets x=3) -> l1(x=3)
  expectEquals(1293, liveInTwoOfThreeEntries(opaque(1), opaque(4)));
  // l2(x=1) -> l3(9, sets x=3) -> l1(x=3)
  expectEquals(193, liveInTwoOfThreeEntries(opaque(2), opaque(3)));
  // l3(9, sets x=3) -> l1(x=3) -> l2(x=2)
  expectEquals(932, liveInTwoOfThreeEntries(opaque(3), opaque(3)));

  // l2(x=7, sets x=9) -> l1(x=9, sets x=7) -> l2(x=7)
  expectEquals(
    797,
    asymmetricPhiSimplification(opaque(2), opaque(3), opaque(7)),
  );
  // l1(x=7, sets x=7) -> l2(x=7)
  expectEquals(
    77,
    asymmetricPhiSimplification(opaque(1), opaque(2), opaque(7)),
  );
}

/// `only1` (`int` / `i64`) is live only at `l1` (`#undefined` at `l2`).
@pragma('wasm:never-inline')
@pragma('wasm:cfg')
int partialInt(int state, int n) {
  int trace = 0;
  int only1 = 1;
  outer:
  switch (state) {
    l1:
    case 1:
      trace = trace * 10 + only1;
      if (--n <= 0) break outer;
      continue l2;
    l2:
    case 2:
      trace = trace * 10 + 3;
      if (--n <= 0) break outer;
      only1 = 2;
      continue l1;
  }
  return trace;
}

/// `only1` (`double` / `f64`) is live only at `l1` (`#undefined` at `l2`).
@pragma('wasm:never-inline')
@pragma('wasm:cfg')
int partialDouble(int state, int n) {
  int trace = 0;
  double only1 = 1.5;
  outer:
  switch (state) {
    l1:
    case 1:
      trace = trace * 10 + (only1 == 2.5 ? 2 : 1);
      if (--n <= 0) break outer;
      continue l2;
    l2:
    case 2:
      trace = trace * 10 + 3;
      if (--n <= 0) break outer;
      only1 = 2.5;
      continue l1;
  }
  return trace;
}

/// `only1` (`bool` / `i32`) is live only at `l1` (`#undefined` at `l2`).
@pragma('wasm:never-inline')
@pragma('wasm:cfg')
int partialBool(int state, int n) {
  int trace = 0;
  bool only1 = false;
  outer:
  switch (state) {
    l1:
    case 1:
      trace = trace * 10 + (only1 ? 2 : 1);
      if (--n <= 0) break outer;
      continue l2;
    l2:
    case 2:
      trace = trace * 10 + 3;
      if (--n <= 0) break outer;
      only1 = true;
      continue l1;
  }
  return trace;
}

/// `only2` (`String`: `externref` in dev, WasmGC ref in prod) is live only at
/// `l2` (`#undefined` -> `ref.null noextern` / `ref.null none` at `l1`).
@pragma('wasm:never-inline')
@pragma('wasm:cfg')
String partialString(int state, int n) {
  String last = 'init';
  String only2 = 'a';
  outer:
  switch (state) {
    l1:
    case 1:
      if (--n <= 0) break outer;
      only2 = 'from-l1';
      continue l2;
    l2:
    case 2:
      last = idString(only2);
      if (--n <= 0) break outer;
      continue l1;
  }
  return last;
}

/// `cur` (`Tag`, WasmGC struct ref) is live only at `l2` (`#undefined` ->
/// `ref.null none`). Passing `cur` to `idTag` exercises `ref.as_non_null` after
/// entering via `l1`, and `main` asserts the returned object via `Tag.id()`.
@pragma('wasm:never-inline')
@pragma('wasm:cfg')
Tag partialObject(int state, int n, Tag a, Tag b) {
  Tag last = a;
  Tag cur = a;
  outer:
  switch (state) {
    l1:
    case 1:
      if (--n <= 0) break outer;
      cur = b;
      continue l2;
    l2:
    case 2:
      last = idTag(cur);
      if (--n <= 0) break outer;
      continue l1;
  }
  return last;
}

/// `x` is live at `l1` and `l2` (both have Phis for `x`) but dead at `l3`, so
/// `_mergeEntryPhis` merges two distinct Phis while supplying `#undefined` for
/// the third entry (`[Phi, Phi, null]`).
@pragma('wasm:never-inline')
@pragma('wasm:cfg')
int liveInTwoOfThreeEntries(int state, int n) {
  int trace = 0;
  int x = 1;
  outer:
  switch (state) {
    l1:
    case 1:
      trace = trace * 10 + x;
      if (--n <= 0) break outer;
      x = 2;
      continue l2;
    l2:
    case 2:
      trace = trace * 10 + x;
      if (--n <= 0) break outer;
      continue l3;
    l3:
    case 3:
      trace = trace * 10 + 9;
      if (--n <= 0) break outer;
      x = 3;
      continue l1;
  }
  return trace;
}

/// `x` has a dominating definition (`init`) read in both entries. Every edge
/// into `l2` carries `init`, so `Simplification` eliminates `l2`'s trivial
/// `Phi(init, init)` while keeping `l1`'s `Phi(init, 9)`.
@pragma('wasm:never-inline')
@pragma('wasm:cfg')
int asymmetricPhiSimplification(int state, int n, int init) {
  int trace = 0;
  int x = init;
  outer:
  switch (state) {
    l1:
    case 1:
      trace = trace * 10 + x;
      if (--n <= 0) break outer;
      x = init;
      continue l2;
    l2:
    case 2:
      trace = trace * 10 + x;
      if (--n <= 0) break outer;
      x = 9;
      continue l1;
  }
  return trace;
}

class Tag {
  int id() => 0;
}

class TagA extends Tag {
  int id() => 10;
}

class TagB extends Tag {
  int id() => 20;
}

@pragma('wasm:never-inline')
@pragma('wasm:cfg')
Tag idTag(Tag t) => t;

@pragma('wasm:never-inline')
@pragma('wasm:cfg')
String idString(String s) => s;

@pragma('wasm:never-inline')
@pragma('wasm:cfg')
int opaque(int x) => x;

@pragma('wasm:never-inline')
@pragma('wasm:cfg')
void expectEquals(int expected, int actual) {
  if (expected != actual) {
    print('expectEquals failed');
    _trap();
  }
}

@pragma('wasm:never-inline')
@pragma('wasm:cfg')
void _trap() => _trap();
