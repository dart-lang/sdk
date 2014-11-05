// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:expect/expect.dart';
import "package:async_helper/async_helper.dart";
import 'package:compiler/src/types/types.dart'
    show TypeMask;

import 'compiler_helper.dart';
import 'type_mask_test_helper.dart';

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

returnInt7() {
  var a = 'foo';
  try {
    a = 42;
    return a;
  } catch (e) {
  }
  return 2;
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
  returnInt7();
}
""";


void main() {
  Uri uri = new Uri(scheme: 'source');
  var compiler = compilerFor(TEST, uri);
  asyncTest(() => compiler.runCompiler(uri).then((_) {
    var typesTask = compiler.typesTask;
    var typesInferrer = typesTask.typesInferrer;

    checkReturn(String name, type) {
      var element = findElement(compiler, name);
      Expect.equals(type,
          simplify(typesInferrer.getReturnTypeOfElement(element), compiler));
    }

    checkReturn('returnInt1', typesTask.uint31Type);
    checkReturn('returnInt2', typesTask.uint31Type);
    checkReturn('returnInt3', typesTask.uint31Type);
    checkReturn('returnInt4', typesTask.uint31Type);
    checkReturn('returnInt5', typesTask.uint31Type);
    checkReturn('returnInt6',
        new TypeMask.nonNullSubtype(compiler.intClass, compiler.world));

    var subclassOfInterceptor =
        findTypeMask(compiler, 'Interceptor', 'nonNullSubclass');

    checkReturn('returnDyn1', subclassOfInterceptor);
    checkReturn('returnDyn2', subclassOfInterceptor);
    checkReturn('returnDyn3', subclassOfInterceptor);
    checkReturn('returnDyn4', subclassOfInterceptor);
    checkReturn('returnDyn5', subclassOfInterceptor);
    checkReturn('returnDyn6', typesTask.dynamicType);
  }));
}
