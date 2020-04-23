// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// @dart = 2.7

/*member: method1:invoke*/
method1() {}

/*member: method2a:invoke=(0)*/
method2a([a]) {}

/*member: method2b:invoke*/
method2b([a]) {}

/*member: method2c:invoke*/
method2c([a]) {}

/*member: method2d:invoke,read*/
method2d([a]) {}

/*member: method3a:invoke=(0)*/
method3a([a, b]) {}

/*member: method3b:invoke=(1)*/
method3b([a, b]) {}

/*member: method3c:invoke*/
method3c([a, b]) {}

/*member: method3d:invoke,read*/
method3d([a, b]) {}

/*member: method4a:invoke=(0)*/
method4a({a}) {}

/*member: method4b:invoke*/
method4b({a}) {}

/*member: method4c:invoke*/
method4c({a}) {}

/*member: method4d:invoke,read*/
method4d({a}) {}

/*member: method5a:invoke=(0)*/
method5a({a, b}) {}

/*member: method5b:invoke=(0,a)*/
method5b({a, b}) {}

/*member: method5c:invoke=(0,b)*/
method5c({a, b}) {}

/*member: method5d:invoke,read*/
method5d({a, b}) {}

/*member: method6a:invoke*/
method6a<T>() {}

/*member: method6b:invoke,read*/
method6b<T>() {}

/*member: method7a:invoke=(1)*/
method7a(a, [b, c]) {}

/*member: method7b:invoke=(2)*/
method7b(a, [b, c]) {}

/*member: method7c:invoke*/
method7c(a, [b, c]) {}

/*member: method7d:invoke,read*/
method7d(a, [b, c]) {}

/*member: method8a:invoke=(1)*/
method8a(a, {b, c}) {}

/*member: method8b:invoke=(1,b)*/
method8b(a, {b, c}) {}

/*member: method8c:invoke=(1,c)*/
method8c(a, {b, c}) {}

/*member: method8d:invoke,read*/
method8d(a, {b, c}) {}

/*member: method9a:invoke=(0)*/
@pragma('dart2js:noElision')
method9a([a, b]) {}

/*member: method9b:invoke=(0)*/
@pragma('dart2js:noElision')
method9b({a, b}) {}

/*member: main:invoke*/
main() {
  method1();

  method2a();
  method2b(null);
  method2c();
  method2c(null);
  method2d;

  method3a();
  method3b();
  method3b(null);
  method3c(null, null);
  method3d;

  method4a();
  method4b(a: null);
  method4c();
  method4c(a: null);
  method4d;

  method5a();
  method5b(a: null);
  method5c(b: null);
  method5d;

  method6a();
  method6b;

  method7a(null);
  method7b(null);
  method7b(null, null);
  method7c(null, null, null);
  method7d;

  method8a(null);
  method8b(null, b: null);
  method8c(null, c: null);
  method8d;

  method9a();
  method9b();
}
