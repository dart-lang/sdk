// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Regression test for dart2js that used to have a bogus
// implementation of var.== and
// var.hashCode.

import 'package:expect/expect.dart';
import "package:async_helper/async_helper.dart";
import 'memory_compiler.dart';

const MEMORY_SOURCE_FILES = const {
  'main.dart': '''

import 'dart:typed_data';

a() => [0];
b() => [1, 2];
c() => new Uint8List(1);
d() => new Uint8List(2);

main() {
  print(a); print(b); print(c); print(d);
}
''',
};

main() {
  var compiler = compilerFor(MEMORY_SOURCE_FILES);
  asyncTest(() => compiler.run(Uri.parse('memory:main.dart')).then((_) {
    var typesInferrer = compiler.typesTask.typesInferrer;

    var element = compiler.mainApp.find('a');
    var mask1 = typesInferrer.getReturnTypeOfElement(element);

    element = compiler.mainApp.find('b');
    var mask2 = typesInferrer.getReturnTypeOfElement(element);

    element = compiler.mainApp.find('c');
    var mask3 = typesInferrer.getReturnTypeOfElement(element);

    element = compiler.mainApp.find('d');
    var mask4 = typesInferrer.getReturnTypeOfElement(element);

    Expect.notEquals(mask1.union(mask2, compiler.world),
                     mask3.union(mask4, compiler.world));
  }));
}
