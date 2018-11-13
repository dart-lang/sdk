// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

class A {
  static var s = "something";
  var a = "anything";
  var x;

  foo() => null;
  bar(var y) => y;
  static sfoo() => null;
  static sbar(var y) => y;

  A.next();

  A(); //# 00: ok
  A() : this.next(); //# 01: ok

  A() : x = s; //# 02: ok
  A() : x = sfoo(); //# 03: ok
  A() : x = sbar(null); //# 04: ok
  A() : x = a; //# 05: compile-time error
  A() : x = foo(); //# 06: compile-time error
  A() : x = bar(null); //# 07: compile-time error
  A() : x = bar(this); //# 08: compile-time error
  A() : x = this; //# 09: compile-time error
  A() : x = this.a; //# 10: compile-time error
  A() : x = this.foo(); //# 11: compile-time error
  A() : x = this.bar(null); //# 12: compile-time error
  A() : x = this.bar(this); //# 13: compile-time error
  A() : x = sbar(this); //# 14: compile-time error
  A() : x = sbar(this.a); //# 15: compile-time error
  A() : x = sbar(this.foo()); //# 16: compile-time error
  A() : x = sbar(this.bar(null)); //# 17: compile-time error
  A() : x = sbar(this.bar(this)); //# 18: compile-time error

  A() : this.x = (() => null); //# 19: ok
  A() : this.x = (() => s)(); //# 20: ok
  A() : this.x = ((c) => c); //# 21: ok
  A() : this.x = ((c) => s)(null); //# 22: ok
  A() : this.x = ((c) => c)(this); //# 23: compile-time error
  A() : this.x = (() => this); //# 24: compile-time error
  A() : this.x = (() => this.a)(); //# 25: compile-time error
  A() : this.x = ((c) => this.foo()); //# 26: compile-time error
  A() : this.x = ((c) => a)(null); //# 27: compile-time error
  A() : this.x = ((c) => foo())(s); //# 28: compile-time error
  A() : this.x = sbar((() { return null; })); //# 29: ok
  A() : this.x = sbar((() { return s; })()); //# 30: ok
  A() : this.x = sbar(((c) { return c; })); //# 31: ok
  A() : this.x = sbar(((c) { return s; })(null)); //# 32: ok
  A() : this.x = sbar(((c) { return c; })(this)); //# 33: compile-time error
  A() : this.x = sbar((() { return this; })); //# 34: compile-time error
  A() : this.x = sbar((() { return this.a; })()); //# 35: compile-time error
  A() : this.x = sbar(((c) { return this.foo(); })); //# 36: compile-time error
  A() : this.x = sbar(((c) { return a; })(null)); //# 37: compile-time error
  A() : this.x = sbar(((c) { return foo(); })(s)); //# 38: compile-time error

  A() : this.x = (s = null); //# 39: ok
  A() : this.x = (a = null); //# 40: compile-time error
  A() : this.x = (this.a = null); //# 41: compile-time error
}

main() {}
