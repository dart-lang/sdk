// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Test that no parts are emitted when deferred loading isn't used.

import 'package:expect/expect.dart';
import "package:async_helper/async_helper.dart";
import 'memory_source_file_helper.dart';

import 'package:compiler/implementation/dart2jslib.dart'
       show NullSink;

import 'package:compiler/compiler.dart'
       show Diagnostic;

import 'dart:async';

main() {
  Uri script = currentDirectory.resolveUri(Platform.script);
  Uri libraryRoot = script.resolve('../../../sdk/');
  Uri packageRoot = script.resolve('./packages/');

  var provider = new MemorySourceFileProvider(MEMORY_SOURCE_FILES);
  void diagnosticHandler(Uri uri, int begin, int end,
                         String message, Diagnostic kind) {
    if (kind == Diagnostic.VERBOSE_INFO) {
      return;
    }
    throw '$uri:$begin:$end:$message:$kind';
  }

  EventSink<String> outputProvider(String name, String extension) {
    if (name != '') throw 'Attempt to output file "$name.$extension"';
    return new NullSink('$name.$extension');
  }

  Compiler compiler = new Compiler(provider.readStringFromUri,
                                   outputProvider,
                                   diagnosticHandler,
                                   libraryRoot,
                                   packageRoot,
                                   [],
                                   {});
  asyncTest(() => compiler.run(Uri.parse('memory:main.dart')).then((_) {
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
