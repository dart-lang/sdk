// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:expect/expect.dart';
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
      return a;
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

returnInt4() {
  var a = 42;
  g() { return a; }
  return g();
}

main() {
  returnInt1();
  returnDyn1();
  returnInt2();
  returnDyn2();
  returnInt3();
  returnDyn3();
  returnInt4();
}
""";


void main() {
  Uri uri = new Uri(scheme: 'source');
  var compiler = compilerFor(TEST, uri);
  compiler.runCompiler(uri);
  var typesInferrer = compiler.typesTask.typesInferrer;

  checkReturn(String name, type) {
    var element = findElement(compiler, name);
    Expect.equals(type, typesInferrer.getReturnTypeOfElement(element));
  }

  checkReturn('returnInt1', compiler.typesTask.intType);
  // TODO(ngeoffray): We don't use types of mutated captured
  // variables anymore, because they could lead to optimistic results
  // needing to be re-analyzed.
  checkReturn('returnInt2', compiler.typesTask.dynamicType);
  checkReturn('returnInt3', compiler.typesTask.intType);
  checkReturn('returnInt4', compiler.typesTask.intType);

  checkReturn('returnDyn1', compiler.typesTask.dynamicType);
  checkReturn('returnDyn2', compiler.typesTask.dynamicType);
  checkReturn('returnDyn3', compiler.typesTask.dynamicType);
}
