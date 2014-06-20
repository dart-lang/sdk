// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Test that tree-shaking hasn't been turned off.

import 'package:expect/expect.dart';
import "package:async_helper/async_helper.dart";
import 'memory_source_file_helper.dart';

import 'package:compiler/implementation/dart2jslib.dart'
       show NullSink;

import 'package:compiler/compiler.dart'
       show Diagnostic;

import 'dart:async';
import 'package:compiler/implementation/js_backend/js_backend.dart'
       show JavaScriptBackend;

main() {
  Uri script = currentDirectory.resolveUri(Platform.script);
  Uri libraryRoot = script.resolve('../../../sdk/');
  Uri packageRoot = script.resolve('./packages/');

  var provider = new MemorySourceFileProvider(MEMORY_SOURCE_FILES);
  void diagnosticHandler(Uri uri, int begin, int end,
                         String message, Diagnostic kind) {
    if (kind == Diagnostic.VERBOSE_INFO
        || kind == Diagnostic.WARNING
        || kind == Diagnostic.HINT) {
      return;
    }
    throw '$uri:$begin:$end:$message:$kind';
  }

  EventSink<String> outputProvider(String name, String extension) {
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
    Expect.isFalse(compiler.enqueuer.resolution.hasEnqueuedEverything);
    Expect.isFalse(compiler.enqueuer.resolution.hasEnqueuedReflectiveStaticFields);
    Expect.isFalse(compiler.enqueuer.codegen.hasEnqueuedEverything);
    Expect.isFalse(compiler.enqueuer.codegen.hasEnqueuedReflectiveStaticFields);
    Expect.isFalse(compiler.disableTypeInference);
    JavaScriptBackend backend = compiler.backend;
    Expect.isFalse(backend.hasRetainedMetadata);
  }));
}

const Map MEMORY_SOURCE_FILES = const {
  'main.dart': r"""
import 'dart:mirrors';

class Foo {
  noSuchMethod(invocation) {
    print('Invoked ${MirrorSystem.getName(invocation.memberName)}');
    return reflect('foobar').delegate(invocation);
  }
}

void main() {
  print(new Foo().substring(3));
}
""",
};
