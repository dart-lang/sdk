// Copyright (c) 2022, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// @dart=2.9
import "./issue46518_lib.dart";

const optedOutToken = OT<NullableIntF>();

class CheckIdentical {
  const CheckIdentical(x, y) : assert(identical(x, y));
}

testOptedOut() {
  const localToken = OT<NullableIntF>();
  const CheckIdentical(optedInToken, localToken);
  const CheckIdentical(optedOutToken, localToken);
}

const testCrossLibraries = const CheckIdentical(optedInToken, optedOutToken);

main() {}
