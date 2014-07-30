// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:expect/expect.dart';
import "package:async_helper/async_helper.dart";
import 'package:compiler/implementation/types/types.dart'
    show ContainerTypeMask, TypeMask;
    
import 'memory_compiler.dart';
import 'compiler_helper.dart' show findElement;
import 'type_mask_test_helper.dart';

const TEST = const {
  'main.dart' : r'''
import 'dart:typed_data';

var myList = new Float32List(42);
var myOtherList = new Uint8List(32);

main() {
  var a = new Float32List(9);
  return myList[0] + myOtherList[0];
}
'''};

void main() {
  var compiler = compilerFor(TEST);
  asyncTest(() => compiler.run(Uri.parse('memory:main.dart')).then((_) {
    var typesInferrer = compiler.typesTask.typesInferrer;

    checkType(String name, type, length) {
      var element = findElement(compiler, name);
      TypeMask mask = typesInferrer.getTypeOfElement(element);
      Expect.isTrue(mask.isContainer);
      ContainerTypeMask container = mask;
      Expect.equals(type, simplify(container.elementType, compiler), name);
      Expect.equals(container.length, length);
    }

    checkType('myList', compiler.typesTask.numType, 42);
    checkType('myOtherList', compiler.typesTask.uint31Type, 32);
  }));
}
