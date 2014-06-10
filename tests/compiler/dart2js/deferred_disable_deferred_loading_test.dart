// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Test that deferred loading can be disabled with a flag to the compiler.

import 'package:expect/expect.dart';
import "package:async_helper/async_helper.dart";
import 'memory_source_file_helper.dart';
import "dart:async";

class FakeOutputStream<T> extends EventSink<T> {
  void add(T event) {}
  void addError(T event, [StackTrace stackTrace]) {}
  void close() {}
}

void main() {
  Uri script = currentDirectory.resolveUri(Platform.script);
  Uri libraryRoot = script.resolve('../../../sdk/');
  Uri packageRoot = script.resolve('./packages/');

  var provider = new MemorySourceFileProvider(MEMORY_SOURCE_FILES);
  var handler = new FormattingDiagnosticHandler(provider);

  Compiler compiler = new Compiler(provider.readStringFromUri,
                                   (name, extension) => new FakeOutputStream(),
                                   handler.diagnosticHandler,
                                   libraryRoot,
                                   packageRoot,
                                   ['--disable-deferred-loading'],
                                   {});
  asyncTest(() => compiler.run(Uri.parse('memory:main.dart')).then((_) {
    Expect.isTrue(compiler.compilationFailed);
  }));
}

const Map MEMORY_SOURCE_FILES = const {"main.dart": """
import 'lib.dart' deferred as lib;

void main() {
  lib.foo();
}
""", "lib.dart": """
foo() {}
""",};