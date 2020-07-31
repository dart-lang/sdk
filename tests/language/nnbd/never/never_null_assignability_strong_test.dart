// Copyright (c) 2020, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Requirements=nnbd-strong

import 'package:expect/expect.dart';
import 'never_null_assignability_lib1.dart';

// Tests for direct calls to null safe functions.
void testNullSafeCalls() {
  // Test calling a null safe function expecting Null from a null safe libary
  {
    takesNull(nil);
    Expect.throws<String>(() => takesNull(never));
    // 3 can't be cast to Null or Never
    Expect.throwsTypeError(() => takesNull(3 as dynamic));
    Expect.throwsTypeError(() => (takesNull as dynamic)(3));
  }

  // Test calling a null safe function expecting Never from a null safe libary
  {
    Expect.throws<String>(() => takesNever(never));
    // 3 can't be cast to Null or Never
    Expect.throwsTypeError(() => takesNever(3 as dynamic));
    Expect.throwsTypeError(() => (takesNever as dynamic)(3));
  }

  // Test calling a null safe function expecting int from a null safe libary
  {
    takesInt(3);
    Expect.throwsTypeError(() => takesInt(nil as dynamic));
    Expect.throwsTypeError(() => (takesInt as dynamic)(nil));
    Expect.throwsTypeError(() => (takesInt as dynamic)("hello"));
  }

  // Test calling a null safe function expecting Object from a null safe libary
  {
    takesObject(3);
    Expect.throwsTypeError(() => takesObject(nil as dynamic));
    Expect.throwsTypeError(() => (takesObject as dynamic)(nil));
  }

  // Test calling a null safe function expecting Object? from a null safe libary
  {
    takesAny(3);
    takesAny(nil);
    (takesAny as dynamic)(nil);
  }
}

void testNullSafeApply() {
  // Test applying a null safe function of static type void Function(Null)
  // in a null safe library, when called with null cast to Null at the call
  // site.
  {
    applyTakesNull(takesNull, nil);
    applyTakesNull(takesAny, nil);
  }

  // Test applying a null safe function of static type void Function(Null)
  // in a null safe library, when called with a non-null value cast to Null
  // at the call site.
  {
    Expect.throwsTypeError(() => applyTakesNull(takesNull, 3));
    Expect.throwsTypeError(() => applyTakesNull(takesAny, 3));
  }

  // Test applying a null safe function of static type void Function(Never)
  // in a null safe library, when called with null cast to Never at the call
  // site.
  {
    // Cast of null to Never should fail.
    Expect.throwsTypeError(() => applyTakesNever(takesNull, nil));
    // Cast of null to Never should fail.
    Expect.throwsTypeError(() => applyTakesNever(takesNever, nil));
    // Cast of null to Never should fail.
    Expect.throwsTypeError(() => applyTakesNever(takesInt, nil));
    // Cast of null to Never should fail.
    Expect.throwsTypeError(() => applyTakesNever(takesObject, nil));
    // Cast of null to Never should fail.
    Expect.throwsTypeError(() => applyTakesNever(takesAny, nil));
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

void testNullSafeApplyDynamically() {
  // Test dynamically applying a null safe function of static type
  // void Function(Null) in a null safe library, when called with
  // null.
  {
    applyTakesNullDynamically(takesNull, nil);
    applyTakesNullDynamically(takesAny, nil);
  }

  // Test dynamically applying a null safe function of static type
  // void Function(Null) in a null safe library, when called with
  // a non-null value.
  {
    Expect.throwsTypeError(() => applyTakesNullDynamically(takesNull, 3));
    applyTakesNullDynamically(takesAny, 3);
  }

  // Test dynamically applying a null safe function of static type
  // void Function(Never) in a null safe library, when called with
  // null.
  {
    applyTakesNeverDynamically(takesNull, nil);
    applyTakesNeverDynamically(takesAny, nil);

    // Dynamic call should fail.
    Expect.throwsTypeError(() => applyTakesNeverDynamically(takesNever, nil));
    // Dynamic call should fail.
    Expect.throwsTypeError(() => applyTakesNeverDynamically(takesInt, nil));
    // Dynamic call should fail.
    Expect.throwsTypeError(() => applyTakesNeverDynamically(takesObject, nil));
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

void main() {
  testNullSafeCalls();
  testNullSafeApply();
  testNullSafeApplyDynamically();
}
