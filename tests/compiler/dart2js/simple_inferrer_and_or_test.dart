// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:expect/expect.dart';
import 'compiler_helper.dart';

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

main() {
  returnDyn1();
  returnDyn2();
  returnDyn3();
  returnDyn4();
  returnDyn5();
  returnDyn6();
}
""";


void main() {
  Uri uri = new Uri.fromComponents(scheme: 'source');
  var compiler = compilerFor(TEST, uri);
  compiler.runCompiler(uri);
  var typesInferrer = compiler.typesTask.typesInferrer;

  checkReturn(String name, type) {
    var element = findElement(compiler, name);
    Expect.equals(type, typesInferrer.returnTypeOf[element]);
  }

  var subclassOfInterceptor =
      findTypeMask(compiler, 'Interceptor', 'nonNullSubclass');

  checkReturn('returnDyn1', subclassOfInterceptor);
  checkReturn('returnDyn2', subclassOfInterceptor);
  checkReturn('returnDyn3', subclassOfInterceptor);
  checkReturn('returnDyn4', typesInferrer.dynamicType);
  checkReturn('returnDyn5', typesInferrer.dynamicType);
  checkReturn('returnDyn6', typesInferrer.dynamicType);
}
