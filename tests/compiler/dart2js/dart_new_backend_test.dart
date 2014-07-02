// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'compiler_helper.dart';
import 'dart:async';
import 'package:async_helper/async_helper.dart';
import 'package:compiler/implementation/dart2jslib.dart';
import 'package:compiler/implementation/dart_backend/dart_backend.dart';

const String TestStaticField = """
class Foo {
  static int x = 1;
}
main() {
  print(Foo.x);
}
""";

Future<String> compile(String code) {
  MockCompiler compiler = new MockCompiler.internal(
      emitJavaScript: false,
      enableMinification: false);
  return compiler.init().then((_) {
    compiler.parseScript(code);
    Element element = compiler.mainApp.find('main');
    if (element == null) return null;
    compiler.mainFunction = element;
    compiler.phase = Compiler.PHASE_RESOLVING;
    compiler.backend.enqueueHelpers(compiler.enqueuer.resolution,
                                    compiler.globalDependencies);
    compiler.processQueue(compiler.enqueuer.resolution, element);
    compiler.world.populate();
    compiler.backend.onResolutionComplete();
    compiler.irBuilder.buildNodes(useNewBackend: true);
    compiler.phase = Compiler.PHASE_COMPILING;
    DartBackend backend = compiler.backend;
    backend.assembleProgram();
    String generated = compiler.assembledCode;
    return generated;
  });
}

Future test(String code, String feature) {
  return compile(code).then((output) {
    if (output == null || !output.contains('main() /* new backend */')) {
      throw 'New backend appears to be deactivated for $feature.\n'
            'Output was: $output';
    }
  });
}

main() {
  asyncTest(() => Future.forEach([
    () => test(TestStaticField, 'static fields'),
  ], (f) => f()));
}
