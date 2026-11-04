// Copyright (c) 2026, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// dart2wasmOptions=--extra-compiler-option=--cfg

// Each test function records the sequence of visited labels as base-10 digits
// (`trace = trace * 10 + digit`).
void main() {
  // l1 -> l2 -> l1 -> l2
  expectEquals(1212, switch2Way(opaque(1), opaque(5)));
  // l2 -> l1 -> l2
  expectEquals(212, switch2Way(opaque(2), opaque(5)));
  expectEquals(-1, switch2Way(opaque(3), opaque(5)));

  // l1 -> l3 -> l5 -> l2 -> l4
  expectEquals(13524, switch5Way(opaque(1), opaque(5)));
  // l2 -> l4 -> l1 -> l3 -> l5
  expectEquals(24135, switch5Way(opaque(2), opaque(5)));
  // l5 -> l2 -> l4
  expectEquals(524, switch5Way(opaque(5), opaque(3)));

  // (l1 -> l2) x 3
  expectEquals(121212, directEntryToEntry(opaque(1), opaque(3)));
  // l2 -> (l1 -> l2) x 2
  expectEquals(21212, directEntryToEntry(opaque(2), opaque(3)));

  // l1 -> l1 -> l2 -> l1 -> l2
  expectEquals(11212, entryWithSelfEdge(opaque(1), opaque(5)));
  // l2 -> l1 -> l1 -> l2
  expectEquals(2112, entryWithSelfEdge(opaque(2), opaque(4)));

  // [outer1(1, 2) -> outer2(inner2(4) -> inner1(3))] x 2
  expectEquals(12431243, nestedLoops(opaque(2), opaque(1), opaque(2)));
  // outer2(inner1(3) -> inner2(4)) -> outer1(1, 2)
  expectEquals(3412, nestedLoops(opaque(1), opaque(2), opaque(2)));

  // o1 -> i1 -> i2 -> o1 -> i1 -> i2
  expectEquals(134134, outerEntryToInnerEntry(opaque(1) == 1, opaque(4)));
  // o2 -> i2 -> o1 -> i1 -> i2
  expectEquals(24134, outerEntryToInnerEntry(opaque(0) == 1, opaque(3)));

  // (a1 -> a2) then (b2 -> b1)
  expectEquals(1243, sequentialLoops(opaque(1), opaque(2)));
  // (a2 -> a1) then (b1 -> b2)
  expectEquals(2134, sequentialLoops(opaque(2), opaque(1)));
}

/// 2-entry irreducible loop with an early non-loop `default` return.
@pragma('wasm:never-inline')
@pragma('wasm:cfg')
int switch2Way(int state, int n) {
  int trace = 0;
  outer:
  switch (state) {
    l1:
    case 1:
      trace = trace * 10 + 1;
      if ((n -= 1) <= 0) break outer;
      continue l2;
    l2:
    case 2:
      trace = trace * 10 + 2;
      if ((n -= 2) <= 0) break outer;
      continue l1;
    default:
      return -1;
  }
  return trace;
}

/// 5-entry irreducible cycle exercising unbalanced multi-level binary dispatch
/// trees (`[0, 5)` -> `[0, 2)` and `[2, 5)` -> `[2, 3)` and `[3, 5)`).
@pragma('wasm:never-inline')
@pragma('wasm:cfg')
int switch5Way(int state, int n) {
  int trace = 0;
  outer:
  switch (state) {
    l1:
    case 1:
      trace = trace * 10 + 1;
      if (--n <= 0) break outer;
      continue l3;
    l2:
    case 2:
      trace = trace * 10 + 2;
      if (--n <= 0) break outer;
      continue l4;
    l3:
    case 3:
      trace = trace * 10 + 3;
      if (--n <= 0) break outer;
      continue l5;
    l4:
    case 4:
      trace = trace * 10 + 4;
      if (--n <= 0) break outer;
      continue l1;
    l5:
    case 5:
      trace = trace * 10 + 5;
      if (--n <= 0) break outer;
      continue l2;
  }
  return trace;
}

/// Entry `l1` ends directly in an unconditional `Goto(l2)`, making `l1` itself
/// a predecessor of `dispatch`.
@pragma('wasm:never-inline')
@pragma('wasm:cfg')
int directEntryToEntry(int state, int n) {
  int trace = 0;
  outer:
  switch (state) {
    l1:
    case 1:
      trace = trace * 10 + 1;
      continue l2;
    l2:
    case 2:
      trace = trace * 10 + 2;
      if (--n <= 0) break outer;
      continue l1;
  }
  return trace;
}

/// Entry `l1` has both a self-back-edge (`continue l1`) and a cross-entry edge
/// (`continue l2`).
@pragma('wasm:never-inline')
@pragma('wasm:cfg')
int entryWithSelfEdge(int state, int n) {
  int trace = 0;
  outer:
  switch (state) {
    l1:
    case 1:
      trace = trace * 10 + 1;
      if (--n <= 0) break outer;
      if ((n & 1) == 0) continue l1;
      continue l2;
    l2:
    case 2:
      trace = trace * 10 + 2;
      if (--n <= 0) break outer;
      continue l1;
  }
  return trace;
}

/// Outer natural loop containing an irreducible `switch` loop, which in turn
/// contains both an inner natural loop and an inner irreducible `switch` loop.
@pragma('wasm:never-inline')
@pragma('wasm:cfg')
int nestedLoops(int outerN, int state, int n) {
  int trace = 0;
  while (outerN-- > 0) {
    int rem = n;
    outerSwitch:
    switch (state) {
      outer1:
      case 1:
        for (int i = 1; i <= 2; i++) {
          trace = trace * 10 + i;
        }
        if (--rem <= 0) break outerSwitch;
        continue outer2;
      outer2:
      case 2:
        int innerSteps = 2;
        innerSwitch:
        switch (rem & 1) {
          inner1:
          case 0:
            trace = trace * 10 + 3;
            if (--innerSteps <= 0) break innerSwitch;
            continue inner2;
          inner2:
          default:
            trace = trace * 10 + 4;
            if (--innerSteps <= 0) break innerSwitch;
            continue inner1;
        }
        if (--rem <= 0) break outerSwitch;
        continue outer1;
    }
  }
  return trace;
}

/// After constant propagation folds `switch (0)`, `{o1, o2, i1, i2}` has outer
/// entries `[o1, o2]` whose bodies end directly in `Goto(i1)` and `Goto(i2)`
/// into the nested irreducible loop `{i1, i2}`.
@pragma('wasm:never-inline')
@pragma('wasm:cfg')
int outerEntryToInnerEntry(bool startFirst, int n) {
  int trace = 0;
  outer:
  switch (0) {
    case 0:
      if (startFirst) continue o1;
      continue o2;
    o1:
    case 1:
      trace = trace * 10 + 1;
      continue i1;
    o2:
    case 2:
      trace = trace * 10 + 2;
      continue i2;
    i1:
    case 3:
      trace = trace * 10 + 3;
      if (--n <= 0) break outer;
      if ((n & 1) == 1) continue i2;
      continue o2;
    i2:
    case 4:
      trace = trace * 10 + 4;
      if (--n <= 0) break outer;
      if ((n & 1) == 1) continue i1;
      continue o1;
  }
  return trace;
}

/// Two sibling irreducible loops in sequence within the same function.
@pragma('wasm:never-inline')
@pragma('wasm:cfg')
int sequentialLoops(int s1, int s2) {
  int trace = 0;
  int n1 = 2;
  first:
  switch (s1) {
    a1:
    case 1:
      trace = trace * 10 + 1;
      if (--n1 <= 0) break first;
      continue a2;
    a2:
    case 2:
      trace = trace * 10 + 2;
      if (--n1 <= 0) break first;
      continue a1;
  }
  int n2 = 2;
  second:
  switch (s2) {
    b1:
    case 1:
      trace = trace * 10 + 3;
      if (--n2 <= 0) break second;
      continue b2;
    b2:
    case 2:
      trace = trace * 10 + 4;
      if (--n2 <= 0) break second;
      continue b1;
  }
  return trace;
}

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
