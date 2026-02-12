// Copyright (c) 2026, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

extension type C0([a = 0]);

extension type C1([final b = true]);

extension type C2({c = 'foo'});

extension type C3({final d = const [0]});

test() {
  C0(''); // Error
  C1(0); // Error
  C2(c: true); // Error
  C3(d: null); // Error
}

main() {
  var c0a = C0();
  int a1 = c0a.a;
  var c0b = C0(42);
  int a2 = c0b.a;

  var c1a = C1();
  bool b1 = c1a.b;
  var c1b = C1(false);
  bool b2 = c1b.b;

  var c2a = C2();
  String c1 = c2a.c;
  var c2b = C2(c: 'bar');
  String c2 = c2b.c;

  var c3a = C3();
  List<int> d1 = c3a.d;
  var c3b = C3(d: [42]);
  List<int> d2 = c3b.d;
}