// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'compiler_helper.dart';

const String TEST = """
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

main() {
  returnDyn1();
  returnDyn2();
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

  checkReturn('returnDyn1', compiler.dynamicClass);
  checkReturn('returnDyn2', compiler.dynamicClass);
  checkReturn('returnDyn3', compiler.dynamicClass);
}
