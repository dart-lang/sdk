// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:expect/expect.dart';
import "package:async_helper/async_helper.dart";
import 'compiler_helper.dart';

const String TEST = """

method1() {
  return 42;
}

method2(a) {  // Called only via [foo2] with a small integer.
  return a;
}

const foo1 = method1;
const foo2 = method2;

returnInt1() {
  return foo1();
}

returnInt2() {
  return foo2(54);
}

main() {
  returnInt1();
  returnInt2();
}
""";


void main() {
  Uri uri = new Uri(scheme: 'source');
  var compiler = compilerFor(TEST, uri);
  asyncTest(() => compiler.run(uri).then((_) {
    var typesInferrer = compiler.typesTask.typesInferrer;

    checkReturn(String name, type) {
      var element = findElement(compiler, name);
      Expect.equals(type,
          typesInferrer.getReturnTypeOfElement(element).simplify(compiler),
          name);
    }

    checkReturn('method1', compiler.typesTask.uint31Type);
    checkReturn('returnInt1', compiler.typesTask.uint31Type);

    checkReturn('method2', compiler.typesTask.uint31Type);
    checkReturn('returnInt2', compiler.typesTask.uint31Type);
  }));
}
