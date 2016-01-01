// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// We used to always nullify the element type of a list we are tracing in
// the presence of a fixed length list constructor call.

import 'package:expect/expect.dart';
import "package:async_helper/async_helper.dart";
import 'package:compiler/src/types/types.dart'
    show ContainerTypeMask, TypeMask;

import 'compiler_helper.dart';
import 'type_mask_test_helper.dart';

const String TEST = r'''
var myList = [42];
main() {
  var a = new List(42);
  return myList[0];
}
''';

void main() {
  Uri uri = new Uri(scheme: 'source');
  var compiler = compilerFor(TEST, uri);
  asyncTest(() => compiler.run(uri).then((_) {
    var typesInferrer = compiler.typesTask.typesInferrer;

    checkType(String name, type) {
      var element = findElement(compiler, name);
      ContainerTypeMask mask = typesInferrer.getTypeOfElement(element);
      Expect.equals(type, simplify(mask.elementType, compiler), name);
    }

    checkType('myList', compiler.typesTask.uint31Type);
  }));
}
