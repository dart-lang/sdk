// Copyright (c) 2020, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// @dart=2.7

// Requirements=nnbd-weak

import 'package:expect/expect.dart';
import 'never_null_assignability_lib1.dart';

void takesLegacyObject(Object n) {
  // In a legacy library, we may get null.  Throw AssertionError so that this
  // can be distinguished from a dynamic call failure.
  if (n == null) throw AssertionError("Not an Object");
}

void takesLegacyInt(int n) {
  // In a legacy library, we may get null.  Throw AssertionError so that this
  // can be distinguished from a dynamic call failure.
  if (n == null) throw AssertionError("Not an int");
}

void takesLegacyNull(Null n) {
  // This should never happen!
  if (n != null) throw AssertionError("Not null");
}

// Tests for direct calls to null safe functions.
void testNullSafeCalls() {
  // Test calling a null safe function expecting Null from a legacy library
  {
    takesNull(nil);
    takesNull(never);
    // Even in weak mode, 3 can't be cast to Null or Never
    Expect.throwsTypeError(() => takesNull(3 as dynamic));
    Expect.throwsTypeError(() => (takesNull as dynamic)(3));
  }

  // Test calling a null safe function expecting Never from a legacy library
  {
    takesNever(nil);
    takesNever(never);
    // Even in weak mode, 3 can't be cast to Null or Never
    Expect.throwsTypeError(() => takesNever(3 as dynamic));
    Expect.throwsTypeError(() => (takesNever as dynamic)(3));
  }

  // Test calling a null safe function expecting int from a legacy library
  {
    takesInt(3);
    Expect.throwsAssertionError(() => takesInt(nil));
    Expect.throwsAssertionError(() => takesInt(nil as dynamic));
    Expect.throwsAssertionError(() => (takesInt as dynamic)(nil));
    Expect.throwsTypeError(() => (takesInt as dynamic)("hello"));
  }

  // Test calling a null safe function expecting Object from a legacy library
  {
    takesObject(3);
    Expect.throwsAssertionError(() => takesObject(nil));
    Expect.throwsAssertionError(() => takesObject(nil as dynamic));
    Expect.throwsAssertionError(() => (takesObject as dynamic)(nil));
  }

  // Test calling a null safe function expecting Object? from a legacy library
  {
    takesAny(3);
    takesAny(nil);
    (takesAny as dynamic)(nil);
  }
}

// Tests for direct calls to legacy functions.
void testLegacyCalls() {
  // Test calling a legacy function expecting Null from a legacy library
  {
    takesLegacyNull(nil);
    // Even in weak mode, 3 can't be cast to Null or Never
    Expect.throwsTypeError(() => takesLegacyNull(3 as dynamic));
    Expect.throwsTypeError(() => (takesLegacyNull as dynamic)(3));
  }

  // Test calling a legacy function expecting int from a legacy library
  {
    takesLegacyInt(3);
    Expect.throwsAssertionError(() => takesLegacyInt(nil));
    Expect.throwsAssertionError(() => (takesLegacyInt as dynamic)(nil));
    Expect.throwsTypeError(() => (takesLegacyInt as dynamic)("hello"));
  }

  // Test calling a legacy function expecting Object from a legacy library
  {
    takesLegacyObject(3);
    Expect.throwsAssertionError(() => takesLegacyObject(nil));
    Expect.throwsAssertionError(() => (takesLegacyObject as dynamic)(nil));
  }
}

void testNullSafeApply() {
  // Test applying a null safe function of static type void Function(Null)
  // in a null safe library, when called with null cast to Null at the call
  // site.
  {
    applyTakesNull(takesNull, nil);
    applyTakesNull(takesNever, nil);
    applyTakesNull(takesAny, nil);

    // Cast of null to Null shouldn't fail, check that we reach the assertion.
    Expect.throwsAssertionError(() => applyTakesNull(takesInt, nil));
    // Cast of null to Null shouldn't fail, check that we reach the assertion.
    Expect.throwsAssertionError(() => applyTakesNull(takesObject, nil));
  }

  // Test applying a null safe function of static type void Function(Null)
  // in a null safe library, when called with a non-null value cast to Null
  // at the call site.
  {
    Expect.throwsTypeError(() => applyTakesNull(takesNull, 3));
    Expect.throwsTypeError(() => applyTakesNull(takesNever, 3));
    Expect.throwsTypeError(() => applyTakesNull(takesInt, 3));
    Expect.throwsTypeError(() => applyTakesNull(takesObject, 3));
    Expect.throwsTypeError(() => applyTakesNull(takesAny, 3));
  }

  // Test applying a null safe function of static type void Function(Never)
  // in a null safe library, when called with null cast to Never at the call
  // site.
  {
    applyTakesNever(takesNull, nil);
    applyTakesNever(takesNever, nil);
    applyTakesNever(takesAny, nil);

    // Cast of null to Never shouldn't fail, check that we reach the assertion.
    Expect.throwsAssertionError(() => applyTakesNever(takesInt, nil));
    // Cast of null to Never shouldn't fail, check that we reach the assertion.
    Expect.throwsAssertionError(() => applyTakesNever(takesObject, nil));
  }

  // Test applying a null safe function of static type void Function(Never)
  // in a null safe library, when called with a non-null value cast to Never
  // at the call site.
  {
    Expect.throwsTypeError(() => applyTakesNever(takesNull, 3));
    Expect.throwsTypeError(() => applyTakesNever(takesNever, 3));
    Expect.throwsTypeError(() => applyTakesNever(takesInt, 3));
    Expect.throwsTypeError(() => applyTakesNever(takesObject, 3));
    Expect.throwsTypeError(() => applyTakesNever(takesAny, 3));
  }
}

void testLegacyApply() {
  // Test applying a legacy function of static type void Function(Null)
  // in a null safe library, when called with null cast to Null at the call
  // site.
  {
    applyTakesNull(takesLegacyNull, nil);

    // Cast of null to Null shouldn't fail, check that we reach the assertion.
    Expect.throwsAssertionError(() => applyTakesNull(takesLegacyInt, nil));
    // Cast of null to Null shouldn't fail, check that we reach the assertion.
    Expect.throwsAssertionError(() => applyTakesNull(takesLegacyObject, nil));
  }

  // Test applying a legacy function of static type void Function(Null)
  // in a null safe library, when called with a non-null value cast to Null
  // at the call site.
  {
    Expect.throwsTypeError(() => applyTakesNull(takesLegacyNull, 3));
    Expect.throwsTypeError(() => applyTakesNull(takesLegacyInt, 3));
    Expect.throwsTypeError(() => applyTakesNull(takesLegacyObject, 3));
  }

  // Test applying a legacy function of static type void Function(Never)
  // in a null safe library, when called with null cast to Never at the call
  // site.
  {
    applyTakesNever(takesLegacyNull, nil);

    // Cast of null to Never shouldn't fail, check that we reach the assertion.
    Expect.throwsAssertionError(() => applyTakesNever(takesLegacyInt, nil));
    // Cast of null to Never shouldn't fail, check that we reach the assertion.
    Expect.throwsAssertionError(() => applyTakesNever(takesLegacyObject, nil));
  }

  // Test applying a legacy function of static type void Function(Never)
  // in a null safe library, when called with a non-null value cast to Never
  // at the call site.
  {
    Expect.throwsTypeError(() => applyTakesNever(takesLegacyNull, 3));
    Expect.throwsTypeError(() => applyTakesNever(takesLegacyInt, 3));
    Expect.throwsTypeError(() => applyTakesNever(takesLegacyObject, 3));
  }
}

void testNullSafeApplyDynamically() {
  // Test dynamically applying a null safe function of static type
  // void Function(Null) in a null safe library, when called with
  // null.
  {
    applyTakesNullDynamically(takesNull, nil);
    applyTakesNullDynamically(takesNever, nil);
    applyTakesNullDynamically(takesAny, nil);

    // Dynamic call shouldn't fail, check that we reach the assertion.
    Expect.throwsAssertionError(() => applyTakesNullDynamically(takesInt, nil));
    // Dynamic call shouldn't fail, check that we reach the assertion.
    Expect.throwsAssertionError(
        () => applyTakesNullDynamically(takesObject, nil));
  }

  // Test dynamically applying a null safe function of static type
  // void Function(Null) in a null safe library, when called with
  // a non-null value.
  {
    Expect.throwsTypeError(() => applyTakesNullDynamically(takesNull, 3));
    Expect.throwsTypeError(() => applyTakesNullDynamically(takesNever, 3));
    applyTakesNullDynamically(takesInt, 3);
    Expect.throwsTypeError(() => applyTakesNullDynamically(takesInt, "hello"));
    applyTakesNullDynamically(takesObject, 3);
    applyTakesNullDynamically(takesAny, 3);
  }

  // Test dynamically applying a null safe function of static type
  // void Function(Never) in a null safe library, when called with
  // null.
  {
    applyTakesNeverDynamically(takesNull, nil);
    applyTakesNeverDynamically(takesNever, nil);
    applyTakesNeverDynamically(takesAny, nil);

    // Dynamic call shouldn't fail, check that we reach the assertion.
    Expect.throwsAssertionError(
        () => applyTakesNeverDynamically(takesInt, nil));
    // Dynamic call shouldn't fail, check that we reach the assertion.
    Expect.throwsAssertionError(
        () => applyTakesNeverDynamically(takesObject, nil));
  }

  // Test dynamically applying a null safe function of static type
  // void Function(Never) in a null safe library, when called with
  // a non-null value.
  {
    Expect.throwsTypeError(() => applyTakesNeverDynamically(takesNull, 3));
    Expect.throwsTypeError(() => applyTakesNeverDynamically(takesNever, 3));
    applyTakesNeverDynamically(takesInt, 3);
    Expect.throwsTypeError(() => applyTakesNeverDynamically(takesInt, "hello"));
    applyTakesNeverDynamically(takesObject, 3);
    applyTakesNeverDynamically(takesAny, 3);
  }
}

void testLegacyApplyDynamically() {
  // Test dynamically applying a legacy function of static type
  // void Function(Null) in a null safe library, when called with
  // null.
  {
    applyTakesNullDynamically(takesLegacyNull, nil);

    // Dynamic call shouldn't fail, check that we reach the assertion.
    Expect.throwsAssertionError(
        () => applyTakesNullDynamically(takesLegacyInt, nil));
    // Dynamic call shouldn't fail, check that we reach the assertion.
    Expect.throwsAssertionError(
        () => applyTakesNullDynamically(takesLegacyObject, nil));
  }

  // Test dynamically applying a legacy function of static type
  // void Function(Null) in a null safe library, when called with
  // a non-null value.
  {
    Expect.throwsTypeError(() => applyTakesNullDynamically(takesLegacyNull, 3));
    applyTakesNullDynamically(takesLegacyInt, 3);
    Expect.throwsTypeError(
        () => applyTakesNullDynamically(takesLegacyInt, "hello"));
    applyTakesNullDynamically(takesLegacyObject, 3);
  }

  // Test dynamically applying a legacy function of static type
  // void Function(Never) in a null safe library, when called with
  // null.
  {
    applyTakesNeverDynamically(takesLegacyNull, nil);

    // Dynamic call shouldn't fail, check that we reach the assertion.
    Expect.throwsAssertionError(
        () => applyTakesNeverDynamically(takesLegacyInt, nil));
    // Dynamic call shouldn't fail, check that we reach the assertion.
    Expect.throwsAssertionError(
        () => applyTakesNeverDynamically(takesLegacyObject, nil));
  }

  // Test dynamically applying a legacy function of static type
  // void Function(Never) in a null safe library, when called with
  // a non-null value.
  {
    Expect.throwsTypeError(
        () => applyTakesNeverDynamically(takesLegacyNull, 3));
    applyTakesNeverDynamically(takesLegacyInt, 3);
    Expect.throwsTypeError(
        () => applyTakesNeverDynamically(takesLegacyInt, "hello"));
    applyTakesNeverDynamically(takesLegacyObject, 3);
  }
}

void main() {
  never = null;
  never = nil;
  nil = never;
  testNullSafeCalls();
  testLegacyCalls();
  testNullSafeApply();
  testLegacyApply();
  testNullSafeApplyDynamically();
  testLegacyApplyDynamically();
}
