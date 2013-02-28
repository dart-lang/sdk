// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

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

  checkReturn('returnInt1', compiler.intClass);
  checkReturn('returnInt2', compiler.intClass);
  checkReturn('returnInt3', compiler.intClass);
  checkReturn('returnInt4', compiler.intClass);
  checkReturn('returnInt5', compiler.intClass);

  checkReturn('returnDyn1', compiler.dynamicClass);
  checkReturn('returnDyn2', compiler.dynamicClass);
  checkReturn('returnDyn3', compiler.dynamicClass);
  checkReturn('returnDyn4', compiler.dynamicClass);
}
