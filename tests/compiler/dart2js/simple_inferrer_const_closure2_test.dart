// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:expect/expect.dart';
import "package:async_helper/async_helper.dart";
import 'compiler_helper.dart';

const String TEST = """

method(a) {  // Called via [foo] with integer then double.
  return a;
}

const foo = method;

returnNum(x) {
  return foo(x);
}

main() {
  returnNum(10);
  returnNum(10.5);
}
""";


void main() {
  Uri uri = new Uri(scheme: 'source');
  var compiler = compilerFor(TEST, uri);
  asyncTest(() => compiler.runCompiler(uri).then((_) {
    var typesInferrer = compiler.typesTask.typesInferrer;

    checkReturn(String name, type) {
      var element = findElement(compiler, name);
      Expect.equals(type,
          typesInferrer.getReturnTypeOfElement(element).simplify(compiler),
          name);
    }

    checkReturn('method', compiler.typesTask.numType);
    checkReturn('returnNum', compiler.typesTask.numType);
  }));
}
