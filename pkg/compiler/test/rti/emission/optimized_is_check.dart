// Copyright (c) 2020, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// @dart = 2.7

// It is sometimes possible to compile is-checks to 'instanceof', when the class
// is not in an 'implements' clause or used as a mixin.

// This test verifies is-checks work with simple classes that have various
// degrees of instantiation.

/*class: Instantiated:checks=[],instance,typeArgument*/
class Instantiated {} // instantiated and used in many ways

/*class: Deferred:checks=[],instance*/
class Deferred {} // instantiated after first check

class Unused {} // used only in is-check

/*class: Removed:checks=[],onlyForConstructor*/
class Removed {} // allocated but optimized out of program

/*class: DeferredAndRemoved:checks=[],onlyForConstructor*/
class DeferredAndRemoved {} // allocated after first check and removed

/*class: UsedAsTypeParameter:typeArgument*/
class UsedAsTypeParameter {} // only used as a type parameter

/*class: UsedAsTestedTypeParameter:typeArgument*/
class UsedAsTestedTypeParameter {} // only used as a type parameter

/*class: Check:checks=[],instance*/
class Check<T> {
  bool check(x) => x is T;
}

class Check2<T> {
  bool check(x) => x is UsedAsTypeParameter;
}

void main() {
  var things = List(3);
  things.setRange(0, 3, [Instantiated(), 1, Object()]);

  var checkX = Check<Instantiated>();
  var checkU1 = Check<UsedAsTestedTypeParameter>();
  var checkU2 = Check<UsedAsTypeParameter>();

  // ignore: UNUSED_LOCAL_VARIABLE
  var removed = Removed(); // This is optimized out.

  // Tests that can be compiled to instanceof:
  if (things[0] is Instantiated) print('expected');
  if (things[1] is Instantiated) print('unexpected');
  if (things[1] is Removed) print('unexpected');
  if (things[1] is DeferredAndRemoved) print('unexpected');
  if (things[1] is Deferred) print('unexpected');
  // Tests that might be optimized to false since there are no allocations:
  if (things[1] is Unused) print('unexpected');
  if (things[1] is UsedAsTypeParameter) print('unexpected');

  if (checkX.check(things[0])) print('expected');
  if (checkX.check(things[1])) print('unexpected');
  if (checkU1.check(things[1])) print('unexpected');
  if (checkU2.check(things[1])) print('unexpected');

  // ignore: UNUSED_LOCAL_VARIABLE
  var removed2 = DeferredAndRemoved(); // This is optimized out.

  // First allocation of Deferred is after the above tests.
  things.setRange(0, 3, [Instantiated(), 1, Deferred()]);

  // Tests that can be compiled to instanceof:
  if (things[0] is Instantiated) print('expected');
  if (things[1] is Instantiated) print('unexpected');
  if (things[1] is Removed) print('unexpected');
  if (things[1] is DeferredAndRemoved) print('unexpected');
  if (things[1] is Deferred) print('unexpected');
  if (things[2] is Deferred) print('expected');
  // Tests that might be optimized to false since there are no allocations:
  if (things[1] is Unused) print('unexpected');
  if (things[1] is UsedAsTypeParameter) print('unexpected');
}
