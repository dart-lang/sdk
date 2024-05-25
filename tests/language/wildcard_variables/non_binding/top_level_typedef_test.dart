// Copyright (c) 2024, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Test the interactions between a wildcard typedef, which is binding, with
// local non-binding wildcard variables.

// SharedOptions=--enable-experiment=wildcard-variables

import 'package:expect/expect.dart';

typedef _ = Type;

_ function<_ extends _>([_ _ = _]) => _;

void main<_ extends _>() {
  _ _ = _;
  final _ _ = _;
  const _ _ = _;
  _ foo<_ extends _>([_ _ = int]) => _;
  _ bar<_ extends _>([_ _ = _]) => int;
  Expect.type<Type>(foo());
  Expect.type<int>(bar());
}

class CConst {
  static const _ = 42;
  void member<_>() {
    var _ = _;
    final _ = _;
    const _ = _;
    int _() => 1;
    var (_, _) = (3, '4');
    Expect.equals(42, _);

    int foo<_>([String _ = "$_"]) => _;
    foo();
    Expect.equals(42, _);
  }
}
