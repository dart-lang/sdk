// Copyright (c) 2026, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

class Base {
  void invoke(String x) {
    print(x);
  }

  set setter(String s) => s;
}

class Eager extends Base {
  String get a => 'a';
  String get b => 'b';

  @override
  void invoke(String x) {
    super.invoke(x + a);
  }

  set setter(String x) => super.setter = x + b;
}
