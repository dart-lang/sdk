// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// @dart = 2.7

// ignore: import_internal_library
import 'dart:_js_helper';

/*member: Class.:access=[toString],params=1*/
@Native('Class')
class Class {
  /*member: Class.method1:calls=[method1()],params=1*/
  @pragma('dart2js:noInline')
  method1([a, b])
      // ignore: native_function_body_in_non_sdk_code
      native;

  /*member: Class.method2:calls=[method2(a)],params=2*/
  @pragma('dart2js:noInline')
  method2([a, b])
      // ignore: native_function_body_in_non_sdk_code
      native;

  /*member: Class.method3:calls=[method3(a,b)],params=3*/
  @pragma('dart2js:noInline')
  method3([a, b])
      // ignore: native_function_body_in_non_sdk_code
      native;

  /*member: Class.method4:
   calls=[method4(a,b)],
   params=3,
   stubs=[method4$0:method4()]
  */
  @pragma('dart2js:noInline')
  method4([a, b])
      // ignore: native_function_body_in_non_sdk_code
      native;

  /*member: Class.method5:
   calls=[method5(a,b)],
   params=3,
   stubs=[method5$1:method5(a)]
  */
  @pragma('dart2js:noInline')
  method5([a, b])
      // ignore: native_function_body_in_non_sdk_code
      native;

  /*member: Class.method6:
   calls=[method6(a,b,c)],
   params=4,
   stubs=[method6$1:method6(a)]
  */
  @pragma('dart2js:noInline')
  method6(a, {b, c})
      // ignore: native_function_body_in_non_sdk_code
      native;

  /*member: Class.method7:
   calls=[method7(a,b,c)],
   params=4,
   stubs=[method7$2$b:method7(a,b)]
  */
  @pragma('dart2js:noInline')
  method7(a, {b, c})
      // ignore: native_function_body_in_non_sdk_code
      native;

  /*member: Class.method8:
   calls=[method8(a,b,c)],
   params=4,
   stubs=[
    method8$2$b:method8(a,b),
    method8$2$c:method8(a,null,c)]
  */
  @pragma('dart2js:noInline')
  method8(a, {b, c})
      // ignore: native_function_body_in_non_sdk_code
      native;
}

/*member: test:
 calls=[
  method1$0(1),
  method2$1(2),
  method3$2(3),
  method4$0(1),
  method4$2(3),
  method5$1(2),
  method5$2(3),
  method6$1(2),
  method6$3$b$c(4),
  method7$2$b(3),
  method7$3$b$c(4),
  method8$2$b(3),
  method8$2$c(3)],
 params=1
*/
@pragma('dart2js:noInline')
test(Class c) {
  c.method1();
  c.method2(null);
  c.method3(null, null);
  c.method4();
  c.method4(null, null);
  c.method5(null);
  c.method5(null, null);
  c.method6(null);
  c.method6(null, b: null, c: null);
  c.method7(null, b: null);
  c.method7(null, b: null, c: null);
  c.method8(null, b: null);
  c.method8(null, c: null);
}

/*member: main:calls=*,params=0*/
main() {
  test(new Class());
}
