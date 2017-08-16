// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:expect/expect.dart';
import "package:async_helper/async_helper.dart";
import 'compiler_helper.dart';
import 'type_mask_test_helper.dart';

const String TEST = """
class X {}
returnDyn1() {
  var a;
  ((a = 52) == true) || ((a = 'foo') == true);
  return a;
}

returnDyn2() {
  var a;
  ((a = 52) == true) && ((a = 'foo') == true);
  return a;
}

returnDyn3() {
  var a;
  a = a == 54 ? 'foo' : 31;
  return a;
}

returnDyn4() {
  var a;
  ((a = 52) == true) || ((a = new X()) == true);
  return a;
}

returnDyn5() {
  var a;
  ((a = 52) == true) && ((a = new X()) == true);
  return a;
}

returnDyn6() {
  var a;
  a = a == 54 ? 'foo' : new X();
  return a;
}

returnDyn7b(x) => x;

returnDyn7() {
  var a = "foo";
  if (a.length == 3) a = 52;
  if ((a is int) || (a is String && true)) returnDyn7b(a);
  return a;
}

returnDyn8(x) => x;

test8() {
  var a = "foo";
  if (a.length == 3) a = 52;
  if ((false && a is! String) || returnDyn8(a)) return a;
}

returnDyn9(x) => x;

test9() {
  var a = "foo";
  if (a.length == 3) a = 52;
  if (!(a is bool && a is bool)) returnDyn9(a);
}

returnString(x) => x;

test10() {
  var a = "foo";
  if (a.length == 3) a = 52;
  if (!(a is num) && a is String) returnString(a);
}

main() {
  returnDyn1();
  returnDyn2();
  returnDyn3();
  returnDyn4();
  returnDyn5();
  returnDyn6();
  returnDyn7();
  test8();
  test9();
  test10();
}
""";

void main() {
  Uri uri = new Uri(scheme: 'source');
  var compiler = compilerFor(TEST, uri);
  asyncTest(() => compiler.run(uri).then((_) {
        var typesInferrer = compiler.globalInference.typesInferrerInternal;
        var closedWorld = typesInferrer.closedWorld;

        checkReturn(String name, type) {
          MemberElement element = findElement(compiler, name);
          Expect.equals(
              type,
              simplify(
                  typesInferrer.getReturnTypeOfMember(element), closedWorld));
        }

        var subclassOfInterceptor = closedWorld.commonMasks.interceptorType;

        checkReturn('returnDyn1', subclassOfInterceptor);
        checkReturn('returnDyn2', subclassOfInterceptor);
        checkReturn('returnDyn3', subclassOfInterceptor);
        checkReturn(
            'returnDyn4', closedWorld.commonMasks.dynamicType.nonNullable());
        checkReturn(
            'returnDyn5', closedWorld.commonMasks.dynamicType.nonNullable());
        checkReturn(
            'returnDyn6', closedWorld.commonMasks.dynamicType.nonNullable());
        checkReturn('returnDyn7', subclassOfInterceptor);
        checkReturn('returnDyn7b', subclassOfInterceptor);
        checkReturn('returnDyn8', subclassOfInterceptor);
        checkReturn('returnDyn9', subclassOfInterceptor);
        checkReturn('returnString', closedWorld.commonMasks.stringType);
      }));
}
