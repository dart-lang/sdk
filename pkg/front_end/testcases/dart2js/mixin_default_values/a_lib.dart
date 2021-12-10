// Copyright (c) 2021, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
import 't_lib.dart';

String _defaultStringy(String t) => t.toLowerCase();

class A {
  A({
    double d = 3.14,
    StringyFunction<String> s = _defaultStringy,
  }) : this.factoryConstructor(d: d, s: s);
  A.factoryConstructor({
    double d = 3.14,
    StringyFunction<String> s = _defaultStringy,
  })  : d = d,
        _s = s;
  String doStringy(String i) => _s(i);
  final double d;
  final StringyFunction<String> _s;
}
