// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// @dart = 2.7

// ignore: import_internal_library
import 'dart:_js_helper';

@Native('Class')
class Class {
  factory Class() {
    throw new UnsupportedError("Not supported");
  }

  method1(a, [b, c])
      // ignore: NATIVE_FUNCTION_BODY_IN_NON_SDK_CODE
      native;

  /*member: Class.method2:
   calls=[method2(a,b,c)],
   params=4,
   stubs=[
    method2$1:method2(a),
    method2$2$b:method2(a,b),
    method2$2$c:method2(a,null,c)]
  */
  method2(a, {b, c})
      // ignore: NATIVE_FUNCTION_BODY_IN_NON_SDK_CODE
      native;

  // TODO(johnniwinther): Control the order of the named arguments. Currently
  // we sort them lexicographically but that doesn't match the target
  // expectations.
  /*member: Class.method3:
   calls=[method3(a,c,b)],
   params=4,
   stubs=[
    method3$1:method3(a),
    method3$2$b:method3(a,null,b),
    method3$2$c:method3(a,c)]
  */
  method3(a, {c, b})
      // ignore: NATIVE_FUNCTION_BODY_IN_NON_SDK_CODE
      native;

  // TODO(johnniwinther): Control the order of the named arguments. Currently
  // we sort them lexicographically but that doesn't match the target
  // expectations.
  /*member: Class.method4:
   calls=[method4(a,c,d,b)],
   params=5,
   stubs=[
    method4$1:method4(a),
    method4$2$b:method4(a,null,null,b),
    method4$2$c:method4(a,c),
    method4$3$b$c:method4(a,c,null,b),
    method4$3$b$d:method4(a,null,d,b),
    method4$3$c$d:method4(a,c,d)]
  */
  method4(a, {c, d, b})
      // ignore: NATIVE_FUNCTION_BODY_IN_NON_SDK_CODE
      native;
}

/*member: makeClass:params=0*/
@Creates('Class')
makeClass()
    // ignore: NATIVE_FUNCTION_BODY_IN_NON_SDK_CODE
    native;

/*member: main:calls=[test(1),*],params=0*/
main() {
  test(makeClass());
}

/*member: test:
 calls=[
  method1(0),
  method1(0,1),
  method1(0,1,2),
  method2$1(2),
  method2$2$b(3),
  method2$2$c(3),
  method2$3$b$c(4),
  method3$1(2),
  method3$2$b(3),
  method3$2$c(3),
  method3$3$b$c(4),
  method4$1(2),
  method4$2$b(3),
  method4$2$c(3),
  method4$3$b$c(4),
  method4$3$b$d(4),
  method4$3$c$d(4)],
 params=1
*/
@pragma('dart2js:noInline')
test(Class o) {
  if (o == null) return;
  o.method1(0);
  o.method1(0, 1);
  o.method1(0, 1, 2);
  o.method2(0);
  o.method2(0, b: 1);
  o.method2(0, b: 1, c: 2);
  o.method2(0, c: 2);
  o.method3(0);
  o.method3(0, b: 1);
  o.method3(0, b: 1, c: 2);
  o.method3(0, c: 2);
  o.method4(0);
  o.method4(0, b: 1);
  o.method4(0, b: 1, c: 2);
  o.method4(0, c: 2);
  o.method4(0, c: 2, d: 3);
  o.method4(0, b: 1, d: 3);
}
