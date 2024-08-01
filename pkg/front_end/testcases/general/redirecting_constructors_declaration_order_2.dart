// Copyright (c) 2024, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

class C {
  List<A> field;
  C.named1({this.field = const [A.redir1(0, s: "")]});
  C.named2({this.field = const [A.redir1(s: "", 0)]});
}

abstract class A {
  const factory A.redir1(int x, {required String s}) = B;
  const factory A.redir2(int x, {required String s}) = B;
}

class B<X> implements A {
  const B(int x, {required String s});
}

test() {
  new A.redir2(0, s: "");
  new A.redir2(s: "", 0);
}
