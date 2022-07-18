// Copyright (c) 2022, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import './issue46518.dart';

typedef NullableIntF = Future<int?> Function();

class OT<T extends Object> {
  const OT();

  @override
  String toString() {
    return "$runtimeType";
  }
}

testOptedIn() {
  const localToken = OT<NullableIntF>();
  const CheckIdentical(optedInToken, localToken);
  const CheckIdentical(optedOutToken, localToken);
}

const optedInToken = OT<NullableIntF>();
