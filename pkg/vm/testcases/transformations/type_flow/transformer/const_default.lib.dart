// Copyright (c) 2021, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

class Constant {
  final int _field;

  const Constant._(this._field);

  static const Constant a = const Constant._(0);
}

abstract class Interface {
  Future<void> method({Constant c: Constant.a});
  Future<void> method2();
}

class Class implements Interface {
  Future<void> method({c: Constant.a}) async {}
  Future<void> method2() async {}
}
