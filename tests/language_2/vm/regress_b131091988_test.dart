// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Check that await from a call-via-field expression works.

import 'package:expect/expect.dart';

abstract class A<T> {
  T Function(List<int> raw) get decode;
}

class B extends A<int> {
  int Function(List<int> raw) get decode => (List<int> raw) => raw.first;
}

class C<T> {
  final A<T> aa;
  C(this.aa);
}

class D {
  final C<int> cc;
  D(this.cc);

  Future<int> read() async {
    return cc.aa.decode(await getList());
  }

  Future<List<int>> getList() async => <int>[42];
}

main() async {
  D dd = new D(new C<int>(new B()));
  Expect.equals(42, await dd.read());
}
