// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Test that computation of callers of an element works when two
// elements of the same name are being invoked in the same method.

import 'package:async_helper/async_helper.dart';
import 'package:expect/expect.dart';
import 'package:compiler/src/common_elements.dart';
import 'package:compiler/src/inferrer/type_graph_inferrer.dart';
import 'package:compiler/src/world.dart' show ClosedWorld, ClosedWorldRefiner;

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
class MyInferrer extends AstTypeGraphInferrer {
  MyInferrer(compiler, closedWorld, closedWorldRefiner)
      : super(compiler, closedWorld, closedWorldRefiner);
  clear() {}
}

void main() {
  Uri uri = new Uri(scheme: 'source');
  var compiler = compilerFor(TEST, uri, analyzeOnly: true);
  asyncTest(() => compiler.run(uri).then((_) {
        ElementEnvironment elementEnvironment =
            compiler.frontendStrategy.elementEnvironment;
        ClosedWorldRefiner closedWorldRefiner =
            compiler.closeResolution(elementEnvironment.mainFunction);
        ClosedWorld closedWorld =
            compiler.resolutionWorldBuilder.closedWorldForTesting;
        var inferrer =
            new MyInferrer(compiler, closedWorld, closedWorldRefiner);
        compiler.globalInference.typesInferrerInternal = inferrer;
        compiler.globalInference.runGlobalTypeInference(
            closedWorld.elementEnvironment.mainFunction,
            closedWorld,
            closedWorldRefiner);
        var mainElement = findElement(compiler, 'main');
        dynamic classA = findElement(compiler, 'A');
        var fieldA = classA.lookupLocalMember('field');
        dynamic classB = findElement(compiler, 'B');
        var fieldB = classB.lookupLocalMember('field');

        Expect.isTrue(inferrer.getCallersOf(fieldA).contains(mainElement));
        Expect.isTrue(inferrer.getCallersOf(fieldB).contains(mainElement));
      }));
}
