// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Test that no parts are emitted when deferred loading isn't used.

import 'package:async_helper/async_helper.dart';
import 'package:compiler/src/dart2jslib.dart';
import 'package:expect/expect.dart';
import 'memory_compiler.dart';

main() {
  DiagnosticCollector diagnostics = new DiagnosticCollector();
  OutputCollector output = new OutputCollector();
  Compiler compiler = compilerFor(
      MEMORY_SOURCE_FILES,
      diagnosticHandler: diagnostics,
      outputProvider: output);

  asyncTest(() => compiler.run(Uri.parse('memory:main.dart')).then((_) {
    Expect.isFalse(diagnostics.hasRegularMessages);
    Expect.isFalse(output.hasExtraOutput);
    Expect.isFalse(compiler.compilationFailed);
  }));
}

const Map MEMORY_SOURCE_FILES = const {
  'main.dart': """
class Greeting {
  final message;
  const Greeting(this.message);
}

const fisk = const Greeting('Hello, World!');

main() {
  var x = fisk;
  if (new DateTime.now().millisecondsSinceEpoch == 42) {
    x = new Greeting(\"I\'m confused\");
  }
  print(x.message);
}
""",
};
