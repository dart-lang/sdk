// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// @dart = 2.7

class Class {
  /*member: Class.constructor1:params=0*/
  @pragma('dart2js:noInline')
  Class.constructor1() {}

  /*member: Class.constructor2a:params=0*/
  @pragma('dart2js:noInline')
  Class.constructor2a([a]) {}

  /*member: Class.constructor2b:params=1*/
  @pragma('dart2js:noInline')
  Class.constructor2b([a]) {}

  /*member: Class.constructor2c:params=1*/
  @pragma('dart2js:noInline')
  Class.constructor2c([a]) {}

  /*member: Class.constructor3a:params=0*/
  @pragma('dart2js:noInline')
  Class.constructor3a([a, b]) {}

  /*member: Class.constructor3b:params=1*/
  @pragma('dart2js:noInline')
  Class.constructor3b([a, b]) {}

  /*member: Class.constructor3c:params=2*/
  @pragma('dart2js:noInline')
  Class.constructor3c([a, b]) {}

  /*member: Class.constructor4a:params=0*/
  @pragma('dart2js:noInline')
  Class.constructor4a({a}) {}

  /*member: Class.constructor4b:params=1*/
  @pragma('dart2js:noInline')
  Class.constructor4b({a}) {}

  /*member: Class.constructor4c:params=1*/
  @pragma('dart2js:noInline')
  Class.constructor4c({a}) {}

  /*member: Class.constructor5a:params=0*/
  @pragma('dart2js:noInline')
  Class.constructor5a({a, b}) {}

  /*member: Class.constructor5b:params=1*/
  @pragma('dart2js:noInline')
  Class.constructor5b({a, b}) {}

  /*member: Class.constructor5c:params=1*/
  @pragma('dart2js:noInline')
  Class.constructor5c({a, b}) {}

  /*member: Class.constructor6a:params=1*/
  @pragma('dart2js:noInline')
  Class.constructor6a(a, [b, c]) {}

  /*member: Class.constructor6b:params=2*/
  @pragma('dart2js:noInline')
  Class.constructor6b(a, [b, c]) {}

  /*member: Class.constructor6c:params=3*/
  @pragma('dart2js:noInline')
  Class.constructor6c(a, [b, c]) {}

  /*member: Class.constructor7a:params=1*/
  @pragma('dart2js:noInline')
  Class.constructor7a(a, {b, c}) {}

  /*member: Class.constructor7b:params=2*/
  @pragma('dart2js:noInline')
  Class.constructor7b(a, {b, c}) {}

  /*member: Class.constructor7c:params=2*/
  @pragma('dart2js:noInline')
  Class.constructor7c(a, {b, c}) {}

  /*member: Class.constructor8a:params=2*/
  @pragma('dart2js:noInline')
  @pragma('dart2js:noElision')
  Class.constructor8a([a, b]) {}

  /*member: Class.constructor8b:params=2*/
  @pragma('dart2js:noInline')
  @pragma('dart2js:noElision')
  Class.constructor8b({a, b}) {}
}

/*member: main:
 calls=[
  Class$constructor1(0),
  Class$constructor2a(0),
  Class$constructor2b(1),
  Class$constructor2c(1),
  Class$constructor2c(1),
  Class$constructor3a(0),
  Class$constructor3b(1),
  Class$constructor3b(1),
  Class$constructor3c(2),
  Class$constructor4a(0),
  Class$constructor4b(1),
  Class$constructor4c(1),
  Class$constructor4c(1),
  Class$constructor5a(0),
  Class$constructor5b(1),
  Class$constructor5c(1),
  Class$constructor6a(1),
  Class$constructor6b(2),
  Class$constructor6b(2),
  Class$constructor6c(3),
  Class$constructor7a(1),
  Class$constructor7b(2),
  Class$constructor7c(2),
  Class$constructor8a(2),
  Class$constructor8b(2)],
 params=0
*/
main() {
  new Class.constructor1();

  new Class.constructor2a();
  new Class.constructor2b(null);
  new Class.constructor2c();
  new Class.constructor2c(null);

  new Class.constructor3a();
  new Class.constructor3b();
  new Class.constructor3b(null);
  new Class.constructor3c(null, null);

  new Class.constructor4a();
  new Class.constructor4b(a: null);
  new Class.constructor4c();
  new Class.constructor4c(a: null);

  new Class.constructor5a();
  new Class.constructor5b(a: null);
  new Class.constructor5c(b: null);

  new Class.constructor6a(null);
  new Class.constructor6b(null);
  new Class.constructor6b(null, null);
  new Class.constructor6c(null, null, null);

  new Class.constructor7a(null);
  new Class.constructor7b(null, b: null);
  new Class.constructor7c(null, c: null);

  new Class.constructor8a();
  new Class.constructor8b();
}
