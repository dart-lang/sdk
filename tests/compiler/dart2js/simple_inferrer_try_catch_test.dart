// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:expect/expect.dart';
import '../../../sdk/lib/_internal/compiler/implementation/types/types.dart'
    show TypeMask;

import 'compiler_helper.dart';

const String TEST = """
returnInt1() {
  var a = 42;
  try {
    a = 54;
  } catch (e){
  }
  return a;
}

returnDyn1() {
  var a = 42;
  try {
    a = 'foo';
  } catch (e){
  }
  return a;
}

returnInt2() {
  var a = 42;
  try {
    a = 54;
  } catch (e){
    a = 2;
  }
  return a;
}

returnDyn2() {
  var a = 42;
  try {
    a = 54;
  } catch (e){
    a = 'foo';
  }
  return a;
}

returnInt3() {
  var a = 42;
  try {
    a = 54;
  } catch (e){
    a = 'foo';
  } finally {
    a = 4;
  }
  return a;
}

returnDyn3() {
  var a = 42;
  try {
    a = 54;
  } on String catch (e) {
    a = 2;
  } on Object catch (e) {
    a = 'foo';
  }
  return a;
}

returnInt4() {
  var a = 42;
  try {
    a = 54;
  } on String catch (e) {
    a = 2;
  } on Object catch (e) {
    a = 32;
  }
  return a;
}

returnDyn4() {
  var a = 42;
  if (a == 54) {
    try {
      a = 'foo';
    } catch (e) {
    }
  }
  return a;
}

returnInt5() {
  var a = 42;
  if (a == 54) {
    try {
      a = 42;
    } catch (e) {
    }
  }
  return a;
}

returnDyn5() {
  var a = 42;
  if (a == 54) {
    try {
      a = 'foo';
      print(a);
      a = 42;
    } catch (e) {
    }
  }
  return a;
}

returnInt6() {
  try {
    throw 42;
  } on int catch (e) {
    return e;
  }
  return 42;
}

returnDyn6() {
  try {
    throw 42;
  } catch (e) {
    return e;
  }
}


main() {
  returnInt1();
  returnDyn1();
  returnInt2();
  returnDyn2();
  returnInt3();
  returnDyn3();
  returnInt4();
  returnDyn4();
  returnInt5();
  returnDyn5();
  returnInt6();
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

  checkReturn('returnInt1', typesInferrer.intType);
  checkReturn('returnInt2', typesInferrer.intType);
  checkReturn('returnInt3', typesInferrer.intType);
  checkReturn('returnInt4', typesInferrer.intType);
  checkReturn('returnInt5', typesInferrer.intType);
  checkReturn('returnInt6',
      new TypeMask.nonNullSubtype(compiler.intClass.rawType));

  var subclassOfInterceptor =
      findTypeMask(compiler, 'Interceptor', 'nonNullSubclass');

  checkReturn('returnDyn1', subclassOfInterceptor);
  checkReturn('returnDyn2', subclassOfInterceptor);
  checkReturn('returnDyn3', subclassOfInterceptor);
  checkReturn('returnDyn4', subclassOfInterceptor);
  checkReturn('returnDyn5', subclassOfInterceptor);
  checkReturn('returnDyn6', typesInferrer.dynamicType);
}
