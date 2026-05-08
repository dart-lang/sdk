// Copyright (c) 2026, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

class C0([var a = 0]);

class C1([final b = true]);

class C2({var c = 'foo'});

class C3({final d = const [0]});

class C4([e = 0]);

class C5({f = true});


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

  var c4a = C4();
  var c4b = C4(42);
  var c4c = C4(true);

  var c5a = C5();
  var c5b = C5(f: false);
  var c5c = C5(f: 42);
}