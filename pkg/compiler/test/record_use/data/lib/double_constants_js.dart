// Copyright (c) 2026, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// ignore: experimental_member_use
import 'package:meta/meta.dart' show RecordUse;

const zero = 0.0;
const maxFinite = 1.7976931348623157e+308;
const minusMaxFinite = -maxFinite;

void main() {
  // In dart2js, 0.0 is canonicalized to IntConstant(0).
  print(SomeClass.someStaticMethod(zero));

  // In dart2js, maxFinite is canonicalized to IntConstant.
  // When running the compiler on the VM, BigInt.toInt() clamps it to
  // 9223372036854775807 (Int64.MAX).
  print(SomeClass.someStaticMethod(maxFinite));

  // In dart2js, -maxFinite is canonicalized to IntConstant.
  // When running the compiler on the VM, BigInt.toInt() clamps it to
  // -9223372036854775808 (Int64.MIN).
  print(SomeClass.someStaticMethod(minusMaxFinite));
}

class SomeClass {
  // ignore: experimental_member_use
  @RecordUse()
  static String someStaticMethod(double d) => d.toString();
}
