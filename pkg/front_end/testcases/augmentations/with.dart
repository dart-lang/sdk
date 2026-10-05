// Copyright (c) 2026, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

mixin M1 {
  String get id => "M1";
  String get id1 => "M1";
}

mixin M2 {
  String get id => "M2";
  String get id2 => "M2";
}

mixin M3 {
  String get id => "M3";
  String get id3 => "M3";
}

class C1a with M1;
augment class C1a;

class C1b;
augment class C1b with M1;

class C2a with M1, M2;
augment class C2a;

class C2b with M1;
augment class C2b with M2;

class C2c;
augment class C2c with M1, M2;

class C3a with M1, M2, M3;
augment class C3a;
augment class C3a;

class C3b with M1, M2;
augment class C3b with M3;
augment class C3b;

class C3c with M1, M2;
augment class C3c;
augment class C3c with M3;

class C3d with M1;
augment class C3d with M2;
augment class C3d with M3;

class C3e;
augment class C3e with M1, M2;
augment class C3e with M3;

class C3f;
augment class C3f with M1;
augment class C3f with M2, M3;

class C3g;
augment class C3g;
augment class C3g with M1, M2, M3;


enum E1a with M1 { a }
augment enum E1a;

enum E1b { a }
augment enum E1b with M1;

enum E2a with M1, M2 { a }
augment enum E2a;

enum E2b with M1 { a }
augment enum E2b with M2;

enum E2c { a }
augment enum E2c with M1, M2;

enum E3a with M1, M2, M3 { a }
augment enum E3a;
augment enum E3a;

enum E3b with M1, M2 { a }
augment enum E3b with M3;
augment enum E3b;

enum E3c with M1, M2 { a }
augment enum E3c;
augment enum E3c with M3;

enum E3d with M1 { a }
augment enum E3d with M2;
augment enum E3d with M3;

enum E3e { a }
augment enum E3e with M1, M2;
augment enum E3e with M3;

enum E3f { a }
augment enum E3f with M1;
augment enum E3f with M2, M3;

enum E3g { a }
augment enum E3g;
augment enum E3g with M1, M2, M3;

main() {
  var c1a = C1a();
  expect("M1", c1a.id);
  expect("M1", c1a.id1);

  var c1b = C1b();
  expect("M1", c1b.id);
  expect("M1", c1b.id1);

  var c2a = C2a();
  expect("M2", c2a.id);
  expect("M1", c2a.id1);
  expect("M2", c2a.id2);

  var c2b = C2b();
  expect("M2", c2b.id);
  expect("M1", c2b.id1);
  expect("M2", c2b.id2);

  var c2c = C2c();
  expect("M2", c2c.id);
  expect("M1", c2c.id1);
  expect("M2", c2c.id2);

  var c3a = C3a();
  expect("M3", c3a.id);
  expect("M1", c3a.id1);
  expect("M2", c3a.id2);
  expect("M3", c3a.id3);

  var c3b = C3b();
  expect("M3", c3b.id);
  expect("M1", c3b.id1);
  expect("M2", c3b.id2);
  expect("M3", c3b.id3);

  var c3c = C3c();
  expect("M3", c3c.id);
  expect("M1", c3c.id1);
  expect("M2", c3c.id2);
  expect("M3", c3c.id3);

  var c3d = C3d();
  expect("M3", c3d.id);
  expect("M1", c3d.id1);
  expect("M2", c3d.id2);
  expect("M3", c3d.id3);

  var c3e = C3e();
  expect("M3", c3e.id);
  expect("M1", c3e.id1);
  expect("M2", c3e.id2);
  expect("M3", c3e.id3);

  var c3f = C3f();
  expect("M3", c3f.id);
  expect("M1", c3f.id1);
  expect("M2", c3f.id2);
  expect("M3", c3f.id3);

  var c3g = C3g();
  expect("M3", c3g.id);
  expect("M1", c3g.id1);
  expect("M2", c3g.id2);
  expect("M3", c3g.id3);

  var e1a = E1a.a;
  expect("M1", e1a.id);
  expect("M1", e1a.id1);
  
  var e1b = E1b.a;
  expect("M1", e1b.id);
  expect("M1", e1b.id1);
  
  var e2a = E2a.a;
  expect("M2", e2a.id);
  expect("M1", e2a.id1);
  expect("M2", e2a.id2);
  
  var e2b = E2b.a;
  expect("M2", e2b.id);
  expect("M1", e2b.id1);
  expect("M2", e2b.id2);
  
  var e2c = E2c.a;
  expect("M2", e2c.id);
  expect("M1", e2c.id1);
  expect("M2", e2c.id2);
  
  var e3a = E3a.a;
  expect("M3", e3a.id);
  expect("M1", e3a.id1);
  expect("M2", e3a.id2);
  expect("M3", e3a.id3);
  
  var e3b = E3b.a;
  expect("M3", e3b.id);
  expect("M1", e3b.id1);
  expect("M2", e3b.id2);
  expect("M3", e3b.id3);
  
  var e3c = E3c.a;
  expect("M3", e3c.id);
  expect("M1", e3c.id1);
  expect("M2", e3c.id2);
  expect("M3", e3c.id3);
  
  var e3d = E3d.a;
  expect("M3", e3d.id);
  expect("M1", e3d.id1);
  expect("M2", e3d.id2);
  expect("M3", e3d.id3);
  
  var e3e = E3e.a;
  expect("M3", e3e.id);
  expect("M1", e3e.id1);
  expect("M2", e3e.id2);
  expect("M3", e3e.id3);
  
  var e3f = E3f.a;
  expect("M3", e3f.id);
  expect("M1", e3f.id1);
  expect("M2", e3f.id2);
  expect("M3", e3f.id3);
  
  var e3g = E3g.a;
  expect("M3", e3g.id);
  expect("M1", e3g.id1);
  expect("M2", e3g.id2);
  expect("M3", e3g.id3);
}

expect(expected, actual) {
  if (expected != actual) throw 'Expected $expected, actual $actual.';
}
