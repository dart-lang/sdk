// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// @dart = 2.7

/*member: method1:params=0*/
@pragma('dart2js:noInline')
method1() {}

/*member: method2a:params=0*/
@pragma('dart2js:noInline')
method2a([a]) {}

/*member: method2b:params=1*/
@pragma('dart2js:noInline')
method2b([a]) {}

/*member: method2c:params=1*/
@pragma('dart2js:noInline')
method2c([a]) {}

/*member: method3a:params=0*/
@pragma('dart2js:noInline')
method3a([a, b]) {}

/*member: method3b:params=1*/
@pragma('dart2js:noInline')
method3b([a, b]) {}

/*member: method3c:params=2*/
@pragma('dart2js:noInline')
method3c([a, b]) {}

/*member: method4a:params=0*/
@pragma('dart2js:noInline')
method4a({a}) {}

/*member: method4b:params=1*/
@pragma('dart2js:noInline')
method4b({a}) {}

/*member: method4c:params=1*/
@pragma('dart2js:noInline')
method4c({a}) {}

/*member: method5a:params=0*/
@pragma('dart2js:noInline')
method5a({a, b}) {}

/*member: method5b:params=1*/
@pragma('dart2js:noInline')
method5b({a, b}) {}

/*member: method5c:params=1*/
@pragma('dart2js:noInline')
method5c({a, b}) {}

/*member: method6a:params=0*/
@pragma('dart2js:noInline')
method6a<T>() {}

/*member: method7a:params=1*/
@pragma('dart2js:noInline')
method7a(a, [b, c]) {}

/*member: method7b:params=2*/
@pragma('dart2js:noInline')
method7b(a, [b, c]) {}

/*member: method7c:params=3*/
@pragma('dart2js:noInline')
method7c(a, [b, c]) {}

/*member: method8a:params=1*/
@pragma('dart2js:noInline')
method8a(a, {b, c}) {}

/*member: method8b:params=2*/
@pragma('dart2js:noInline')
method8b(a, {b, c}) {}

/*member: method8c:params=2*/
@pragma('dart2js:noInline')
method8c(a, {b, c}) {}

/*member: method9a:params=2*/
@pragma('dart2js:noInline')
@pragma('dart2js:noElision')
method9a([a, b]) {}

/*member: method9b:params=2*/
@pragma('dart2js:noInline')
@pragma('dart2js:noElision')
method9b({a, b}) {}

/*member: main:
 calls=[
  method1(0),
  method2a(0),
  method2b(1),
  method2c(1),
  method2c(1),
  method3a(0),
  method3b(1),
  method3b(1),
  method3c(2),
  method4a(0),
  method4b(1),
  method4c(1),
  method4c(1),
  method5a(0),
  method5b(1),
  method5c(1),
  method6a(0),
  method7a(1),
  method7b(2),
  method7b(2),
  method7c(3),
  method8a(1),
  method8b(2),
  method8c(2),
  method9a(2),
  method9b(2)],
 params=0
*/
main() {
  method1();

  method2a();
  method2b(null);
  method2c();
  method2c(null);

  method3a();
  method3b();
  method3b(null);
  method3c(null, null);

  method4a();
  method4b(a: null);
  method4c();
  method4c(a: null);

  method5a();
  method5b(a: null);
  method5c(b: null);

  method6a();

  method7a(null);
  method7b(null);
  method7b(null, null);
  method7c(null, null, null);

  method8a(null);
  method8b(null, b: null);
  method8c(null, c: null);

  method9a();
  method9b();
}
