// Copyright (c) 2020, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Requirements=nnbd-weak

// ddcOptions=--weak-null-safety-errors

import 'package:expect/expect.dart';

/// Code that runs without error when running with unsound null safety but
/// should throw in sound mode or when running DDC with
/// `--weak-null-safety-errors`.

void fn(StringBuffer arg) {}
void testArg<T>(T t) => throw 'do not call';
T testReturn<T>() => throw 'do not call';

const c = C<Duration>();

class C<T> {
  covariantCheck(List<T> t) {}
  const C();
}

void main() {
  Expect.throwsTypeError(() => null as int);
  dynamic dynamicNull = null;
  Expect.throwsTypeError(() => fn(dynamicNull));

  Expect.throwsTypeError(() => [Duration(days: 1), null] as List<Duration>);

  // Constants get legacy types introduced in their type arguments.
  C<Duration?> c2 = c;
  Expect.throwsTypeError(() => c2.covariantCheck([Duration(days: 1), null]));

  // Tearoff instantiations are "potentially constant" and are treated as a
  // constant by the CFE.
  // When compiling for unsound null safety the resulting type signature
  // attached to the tearoff is `void Function(Duration*)` which is a valid
  // subtype of `void Function(Duration?)`. In sound null safety the signature
  // is `void Function(Duration)` which should fail in the cast.
  Expect.throwsTypeError(() => (testArg<Duration>) as void Function(Duration?));
  Expect.throwsTypeError(() => (testReturn<Duration?>) as Duration Function());
}
