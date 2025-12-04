// Copyright (c) 2025, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/// The type of the parameter should be inferred from the corresponding field.

// SharedOptions=--enable-experiment=private-named-parameters

import 'package:expect/expect.dart';
import 'package:expect/static_type_helper.dart';

class C {
  int _x;
  C({required this._x});
}

void main() {
  C(x: expr(1)..expectStaticType<Exactly<int>>());
}

T expr<T>([Object? v]) => v as T;
