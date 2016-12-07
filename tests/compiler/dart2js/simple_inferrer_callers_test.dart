// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Test that computation of callers of an element works when two
// elements of the same name are being invoked in the same method.

import 'package:async_helper/async_helper.dart';
import 'package:expect/expect.dart';
import 'package:compiler/src/inferrer/type_graph_inferrer.dart';

import 'compiler_helper.dart';

const String TEST = """
class A {
  var field;
}

class B {
  var field;
}

main() {
  new A().field;
  new B().field;
}
""";

// Create our own type inferrer to avoid clearing out the internal
// data structures.
class MyInferrer extends TypeGraphInferrer {
  MyInferrer(compiler, commonMasks) : super(compiler, commonMasks);
  clear() {}
}

void main() {
  Uri uri = new Uri(scheme: 'source');
  var compiler = compilerFor(TEST, uri, analyzeOnly: true);
  asyncTest(() => compiler.run(uri).then((_) {
        compiler.closeResolution();
        var inferrer =
            new MyInferrer(compiler, compiler.closedWorld.commonMasks);
        compiler.globalInference.typesInferrerInternal = inferrer;
        compiler.globalInference.runGlobalTypeInference(compiler.mainFunction);
        var mainElement = findElement(compiler, 'main');
        var classA = findElement(compiler, 'A');
        var fieldA = classA.lookupLocalMember('field');
        var classB = findElement(compiler, 'B');
        var fieldB = classB.lookupLocalMember('field');

        Expect.isTrue(inferrer.getCallersOf(fieldA).contains(mainElement));
        Expect.isTrue(inferrer.getCallersOf(fieldB).contains(mainElement));
      }));
}
