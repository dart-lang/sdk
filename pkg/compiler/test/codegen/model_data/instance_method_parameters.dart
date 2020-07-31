// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// @dart = 2.7

class Class {
  /*member: Class.method1:params=0*/
  @pragma('dart2js:noInline')
  method1() {}

  /*member: Class.method2a:params=0*/
  @pragma('dart2js:noInline')
  method2a([a]) {}

  /*member: Class.method2b:params=1*/
  @pragma('dart2js:noInline')
  method2b([a]) {}

  /*member: Class.method2c:params=1,stubs=[method2c$0:method2c$1(1)]*/
  @pragma('dart2js:noInline')
  method2c([a]) {}

  /*member: Class.method3a:params=0*/
  @pragma('dart2js:noInline')
  method3a([a, b]) {}

  /*member: Class.method3b:params=1,stubs=[method3b$0:method3b$1(1)]*/
  @pragma('dart2js:noInline')
  method3b([a, b]) {}

  /*member: Class.method3c:params=2*/
  @pragma('dart2js:noInline')
  method3c([a, b]) {}

  /*member: Class.method4a:params=0*/
  @pragma('dart2js:noInline')
  method4a({a}) {}

  /*member: Class.method4b:params=1*/
  @pragma('dart2js:noInline')
  method4b({a}) {}

  /*member: Class.method4c:params=1,stubs=[method4c$0:method4c$1$a(1)]*/
  @pragma('dart2js:noInline')
  method4c({a}) {}

  /*member: Class.method5a:params=0*/
  @pragma('dart2js:noInline')
  method5a({a, b}) {}

  /*member: Class.method5b:params=1*/
  @pragma('dart2js:noInline')
  method5b({a, b}) {}

  /*member: Class.method5c:params=1*/
  @pragma('dart2js:noInline')
  method5c({a, b}) {}

  /*member: Class.method6a:params=0,stubs=[method6a$0:method6a$1$0(1)]*/
  @pragma('dart2js:noInline')
  method6a<T>() {}

  /*member: Class.method7a:params=1*/
  @pragma('dart2js:noInline')
  method7a(a, [b, c]) {}

  /*member: Class.method7b:params=2,stubs=[method7b$1:method7b$2(2)]*/
  @pragma('dart2js:noInline')
  method7b(a, [b, c]) {}

  /*member: Class.method7c:params=3*/
  @pragma('dart2js:noInline')
  method7c(a, [b, c]) {}

  /*member: Class.method8a:params=1*/
  @pragma('dart2js:noInline')
  method8a(a, {b, c}) {}

  /*member: Class.method8b:params=2*/
  @pragma('dart2js:noInline')
  method8b(a, {b, c}) {}

  /*member: Class.method8c:params=2*/
  @pragma('dart2js:noInline')
  method8c(a, {b, c}) {}

  /*member: Class.method9a:params=2,stubs=[method9a$0:method9a$2(2)]*/
  @pragma('dart2js:noInline')
  @pragma('dart2js:noElision')
  method9a([a, b]) {}

  /*member: Class.method9b:params=2,stubs=[method9b$0:method9b$2$a$b(2)]*/
  @pragma('dart2js:noInline')
  @pragma('dart2js:noElision')
  method9b({a, b}) {}

  /*member: Class.test:calls=*,params=0*/
  @pragma('dart2js:noInline')
  test() {
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
}

/*member: main:calls=[test$0(0)],params=0*/
main() {
  new Class().test();
}
