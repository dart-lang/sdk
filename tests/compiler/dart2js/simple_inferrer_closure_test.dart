// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'compiler_helper.dart';

const String TEST = """
returnInt1() {
  var a = 42;
  var f = () {
    return a;
  };
  return a;
}

returnDyn1() {
  var a = 42;
  var f = () {
    a = 'foo';
  };
  return a;
}

returnInt2() {
  var a = 42;
  var f = () {
    a = 54;
  };
  return a;
}

returnDyn2() {
  var a = 42;
  var f = () {
    a = 54;
  };
  var g = () {
    a = 'foo';
  };
  return a;
}

returnInt3() {
  var a = 42;
  if (a == 53) {
    var f = () {
      a = 32;
    };
  }
  return a;
}

returnDyn3() {
  var a = 42;
  if (a == 53) {
    var f = () {
      a = 'foo';
    };
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

  checkReturn('returnDyn1', compiler.dynamicClass);
  checkReturn('returnDyn2', compiler.dynamicClass);
  checkReturn('returnDyn3', compiler.dynamicClass);

  print(typesInferrer.returnTypeOf);
}
