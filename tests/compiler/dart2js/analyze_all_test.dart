// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import "package:expect/expect.dart";
import "compiler_helper.dart";
import "package:async_helper/async_helper.dart";

const String SOURCE = """
class Foo {
  // Deliberately not const to ensure compile error.
  Foo(_);
}

@Bar()
class Bar {
  const Bar();
}

@Foo('x')
typedef void VoidFunction();

@Foo('y')
class MyClass {}

main() {
}
""";

main() {
  Uri uri = Uri.parse('test:code');
  var compiler1 = compilerFor(SOURCE, uri, analyzeAll: false);
  asyncTest(() => compiler1.runCompiler(uri).then((_) {
    Expect.isFalse(compiler1.compilationFailed);
    print(compiler1.warnings);
    Expect.isTrue(compiler1.warnings.isEmpty, 'unexpected warnings');
    Expect.isTrue(compiler1.errors.isEmpty, 'unexpected errors');
  }));

  var compiler2 = compilerFor(SOURCE, uri, analyzeAll: true);
  asyncTest(() => compiler2.runCompiler(uri).then((_) {
    Expect.isTrue(compiler2.compilationFailed);
    Expect.isTrue(compiler2.warnings.isEmpty,
                  'unexpected warnings: ${compiler2.warnings}');
    Expect.equals(2, compiler2.errors.length,
                  'expected exactly two errors, but got ${compiler2.errors}');

    Expect.equals(MessageKind.CONSTRUCTOR_IS_NOT_CONST,
                  compiler2.errors[0].message.kind);
    Expect.equals("Foo", compiler2.errors[0].node.toString());

    Expect.equals(MessageKind.CONSTRUCTOR_IS_NOT_CONST,
                  compiler2.errors[1].message.kind);
    Expect.equals("Foo", compiler2.errors[1].node.toString());
  }));
}
