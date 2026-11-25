// Copyright (c) 2026, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Regression test verifying that interface dispatch with a wide cone receiver
// intersected with another cone only dispatches to subtypes of the interface
// target's enclosing class.
//
// Assumes --tfa.maxAllocatedTypesInSetSpecialization=1 (1 subtype = narrow,
// >= 2 subtypes = wide).

void main() {
  // Allocate classes and keep target methods live. Indexing typed list literals
  // forces TFA to see a wide cone (e.g. WideA++) instead of a concrete class.
  print(NarrowB().m().$2);

  final c = <WideC>[WideC(), WideC1()][0];
  c.incompatible();
  print(c.m().$2);

  // DynC's methods are not called directly; they stay live only through
  // testBothDynExtendable below.
  DynC();

  final d = <WideD>[WideD(), WideAD()][0];
  print(d.foo());

  // Exercise wide-cone interface dispatch across disjoint, overlapping, and
  // dynamically extendable cones.
  final a = <WideA>[WideA(), WideA1(), WideAD()][0];
  print(testBothWideDisjoint(a));
  print(testWideAndNarrowDisjoint(a));
  print(testBothWideOverlapping(a));
  print(testClosedAndDynExtendable(a));

  final dynA = <DynA>[DynA()][0];
  print(testBothDynExtendable(dynA));
  print(testDynExtendableAndClosed(dynA));
}

// Disjoint wide cones (3 vs 2 subtypes): must neither hit signature mismatch
// nor dispatch WideC.m() to WideA.m().
int testBothWideDisjoint(WideA a) {
  if (a is WideC) {
    (a as WideC).incompatible();
    return (a as WideC).m().$2;
  }
  return 0;
}

// Wide cone (3) vs narrow cone (1) -> disjoint, returns 0.
int testWideAndNarrowDisjoint(WideA a) =>
    a is NarrowB ? (a as NarrowB).m().$2 : 0;

// Overlapping wide cones sharing WideAD -> devirtualized to WideAD.foo().
int testBothWideOverlapping(WideA a) => a is WideD ? (a as WideD).foo() : 0;

// Closed wide cone (3) vs dynamically extendable (1) -> disjoint, returns 0.
int testClosedAndDynExtendable(WideA a) => a is DynC ? (a as DynC).m() : 0;

// Both dynamically extendable: no incompatible dispatch, DynC.m() polymorphic.
int testBothDynExtendable(DynA a) {
  if (a is DynC) {
    (a as DynC).incompatible();
    return (a as DynC).m();
  }
  return 0;
}

// Dynamically extendable (1) vs closed wide cone (2) -> disjoint, returns 0.
int testDynExtendableAndClosed(DynA a) => a is WideC ? (a as WideC).m().$2 : 0;

class WideA {
  (int,) m() => (1,);
  void incompatible(int x) {}
  int foo() => 1;
}

class WideA1 extends WideA {}

class NarrowB {
  (int, int) m() => (5, 6);
}

class WideC {
  (int, int) m() => (3, 4);
  void incompatible() {}
}

class WideC1 extends WideC {}

class WideD {
  int foo() => 10;
}

class WideAD extends WideA implements WideD {
  @override
  int foo() => 42;
}

@pragma('dyn-module:extendable')
class DynA {
  void incompatible(int x) {}
}

@pragma('dyn-module:extendable')
class DynC {
  @pragma('dyn-module:can-be-overridden')
  int m() => 99;

  @pragma('dyn-module:can-be-overridden')
  void incompatible() {}
}
